#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

REPO="$(
    cd "$SCRIPT_DIR/.." &&
    pwd
)"

PURE_XZ=""
PPSSPP_RUNTIME=""
OUTPUT_DIR=""

VERSION="1.0.0"

PURE_SHA_EXPECTED="5f9f35375c88fd945e780577cd92d1a30a58675a7eb043fd4547bcc77895a2e6"
PPSSPP_SHA_EXPECTED="1af91efd8374a2c164e5f2ffa37b3d65980b825a207cbb09c688b2997088c5ad"

LOOP=""
ROOT=""
WORKDIR=""
BOOT_MOUNTED=0
RESOLV_BACKED_UP=0
POLICY_BACKED_UP=0
SUCCESS=0


die() {
    echo "ERRO: $*" >&2
    exit 1
}


cleanup() {

    set +e

    if [ -n "${ROOT:-}" ] && mountpoint -q "$ROOT"; then
        sync
        umount -R "$ROOT" 2>/dev/null
    fi

    if [ -n "${LOOP:-}" ]; then
        losetup -d "$LOOP" 2>/dev/null
    fi

    if [ "$SUCCESS" -eq 0 ] && [ -n "${WORKDIR:-}" ]; then
        echo
        echo "BUILD_INTERROMPIDO_WORKDIR=$WORKDIR"
    fi
}

trap cleanup EXIT


while [ "$#" -gt 0 ]; do

    case "$1" in

        --pure)
            PURE_XZ="$2"
            shift 2
            ;;

        --ppsspp-runtime)
            PPSSPP_RUNTIME="$2"
            shift 2
            ;;

        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;

        *)
            die "argumento desconhecido: $1"
            ;;

    esac
done


[ "$EUID" -eq 0 ] || die "builder requer root"

[ -f "$PURE_XZ" ] || die "Pure ausente"
[ -f "$PPSSPP_RUNTIME" ] || die "PPSSPP runtime ausente"
[ -n "$OUTPUT_DIR" ] || die "--output-dir obrigatorio"

mkdir -p "$OUTPUT_DIR"

OUTPUT_DIR="$(
    readlink -f "$OUTPUT_DIR"
)"


echo "============================================================"
echo " BMO READY v$VERSION - IMAGE BUILD"
echo "============================================================"


echo
echo "[01/12] Validando fontes..."

PURE_SHA="$(
    sha256sum "$PURE_XZ" |
    awk '{print $1}'
)"

PPSSPP_SHA="$(
    sha256sum "$PPSSPP_RUNTIME" |
    awk '{print $1}'
)"

[ "$PURE_SHA" = "$PURE_SHA_EXPECTED" ] || {
    die "Pure SHA divergente"
}

[ "$PPSSPP_SHA" = "$PPSSPP_SHA_EXPECTED" ] || {
    die "PPSSPP runtime SHA divergente"
}

xz -t "$PURE_XZ"

GIT_COMMIT="$(
    runuser -u hipo -- \
        git -C "$REPO" rev-parse HEAD
)"

[ -z "$(
    runuser -u hipo -- \
        git -C "$REPO" status --porcelain
)" ] || {
    die "Git worktree precisa estar limpo"
}

echo "GIT_COMMIT=$GIT_COMMIT"
echo "SOURCE_VALIDATION_OK"


echo
echo "[02/12] Preparando imagem de trabalho..."

STAMP="$(date +%Y%m%d-%H%M%S)"

WORKDIR="/home/hipo/bmo-builds/ready-v${VERSION}-$STAMP"

mkdir -p "$WORKDIR"

WORK_IMG="$WORKDIR/BMO-R36S-Ready-v${VERSION}-candidate.img"

echo "WORKDIR=$WORKDIR"

df -h "$OUTPUT_DIR"
df -h "$WORKDIR"

xz -dc "$PURE_XZ" > "$WORK_IMG"

[ -s "$WORK_IMG" ] || {
    die "imagem descompactada vazia"
}

echo "RAW_IMAGE_CREATED_OK"


echo
echo "[03/12] Detectando particoes..."

LOOP="$(
    losetup \
        --find \
        --show \
        --partscan \
        "$WORK_IMG"
)"

udevadm settle

echo "LOOP=$LOOP"

lsblk "$LOOP"

mapfile -t PARTS < <(
    lsblk \
        -lnpo NAME,TYPE \
        "$LOOP" |
    awk '$2=="part" {print $1}'
)

[ "${#PARTS[@]}" -ge 1 ] || {
    die "nenhuma particao detectada"
}

ROOT_PART=""
BOOT_PART=""

for PART in "${PARTS[@]}"; do

    PROBE="$(mktemp -d)"

    if mount -o ro "$PART" "$PROBE" 2>/dev/null; then

        if [ -f "$PROBE/etc/os-release" ] &&
           [ -d "$PROBE/usr" ]
        then
            ROOT_PART="$PART"
        fi

        if [ -f "$PROBE/armbianEnv.txt" ]; then
            BOOT_PART="$PART"
        fi

        umount "$PROBE"
    fi

    rmdir "$PROBE"

done

[ -n "$ROOT_PART" ] || {
    die "root filesystem nao localizado"
}

echo "ROOT_PART=$ROOT_PART"
echo "BOOT_PART=${BOOT_PART:-IN_ROOT}"

echo "PARTITION_DETECTION_OK"


echo
echo "[04/12] Montando target..."

ROOT="$WORKDIR/root"

mkdir -p "$ROOT"

mount "$ROOT_PART" "$ROOT"

if [ -n "$BOOT_PART" ] &&
   [ "$BOOT_PART" != "$ROOT_PART" ]
then
    mkdir -p "$ROOT/boot"
    mount "$BOOT_PART" "$ROOT/boot"
    BOOT_MOUNTED=1
fi

[ -f "$ROOT/etc/os-release" ] || {
    die "root montado invalido"
}

touch "$ROOT/.bmo-ready-build-root"
touch "$ROOT/.bmo-ready-sandbox"
touch "$ROOT/.bmo-apply-v3-sandbox"

echo "TARGET_ROOT=$ROOT"
echo "TARGET_MOUNT_OK"


echo
echo "[05/12] Preparando chroot..."

for DIR in dev proc sys run; do

    mkdir -p "$ROOT/$DIR"

    mount \
        --rbind \
        "/$DIR" \
        "$ROOT/$DIR"

    mount \
        --make-rslave \
        "$ROOT/$DIR"

done


RESOLV_BACKUP="$WORKDIR/resolv.conf.original"

if [ -e "$ROOT/etc/resolv.conf" ] ||
   [ -L "$ROOT/etc/resolv.conf" ]
then
    cp -a \
        --no-dereference \
        "$ROOT/etc/resolv.conf" \
        "$RESOLV_BACKUP"

    RESOLV_BACKED_UP=1
fi

rm -f "$ROOT/etc/resolv.conf"

cp -L \
    /etc/resolv.conf \
    "$ROOT/etc/resolv.conf"


POLICY="$ROOT/usr/sbin/policy-rc.d"
POLICY_BACKUP="$WORKDIR/policy-rc.d.original"

if [ -e "$POLICY" ] ||
   [ -L "$POLICY" ]
then
    cp -a \
        --no-dereference \
        "$POLICY" \
        "$POLICY_BACKUP"

    POLICY_BACKED_UP=1
fi

cat > "$POLICY" <<'EOF'
#!/bin/sh
exit 101
EOF

chmod 0755 "$POLICY"

echo "CHROOT_PREPARED_OK"


echo
echo "[06/12] Pacotes + usuario..."

"$REPO/install/phases/60-prereqs.sh" \
    --root "$ROOT" \
    --apply

echo "PHASE60_OK"


echo
echo "[07/12] BMO base + emuladores..."

"$REPO/install/bmo-install.sh" \
    --apply \
    --root "$ROOT" \
    --ppsspp-runtime "$PPSSPP_RUNTIME"

echo "BMO_BASE_INSTALL_OK"


echo
echo "[08/12] System config + services..."

"$REPO/install/phases/40-system-config.sh" \
    --root "$ROOT"

"$REPO/install/phases/50-services.sh" \
    --root "$ROOT"

echo "SYSTEM_INTEGRATION_OK"


echo
echo "[09/12] Limpando ambiente apt/chroot..."

chroot "$ROOT" \
    /usr/bin/env -i \
    HOME=/root \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    apt-get clean || true


rm -f "$POLICY"

if [ "$POLICY_BACKED_UP" -eq 1 ]; then
    cp -a \
        --no-dereference \
        "$POLICY_BACKUP" \
        "$POLICY"
fi


rm -f "$ROOT/etc/resolv.conf"

if [ "$RESOLV_BACKED_UP" -eq 1 ]; then
    cp -a \
        --no-dereference \
        "$RESOLV_BACKUP" \
        "$ROOT/etc/resolv.conf"
fi

echo "CHROOT_RUNTIME_RESTORED_OK"


echo
echo "[10/12] Sanitizando Ready..."

"$REPO/install/phases/70-sanitize.sh" \
    --root "$ROOT"

echo "SANITIZE_OK"


echo
echo "[11/12] Validacao final..."

"$REPO/install/phases/60-prereqs.sh" \
    --root "$ROOT" \
    --check


[ "$(
    find "$ROOT/usr/local/bin" \
        -maxdepth 1 \
        -type f |
    wc -l
)" -eq 13 ]

[ "$(
    find "$ROOT/home/r36s/.config" \
        -type f |
    wc -l
)" -eq 4 ]

[ "$(
    find "$ROOT/home/r36s/ROMs" \
        -type f |
    wc -l
)" -eq 0 ]

[ "$(
    find "$ROOT/opt/src/ppsspp/build-bmo" \
        -type f |
    wc -l
)" -eq 186 ]


ENABLED_LINKS="$(
    find "$ROOT/etc/systemd/system" \
        -type l |
    wc -l
)"

echo "SYSTEMD_ENABLE_LINKS=$ENABLED_LINKS"

[ "$ENABLED_LINKS" -eq 10 ] || {
    die "esperados 10 services enabled"
}


for UNIT in \
    bmo-usb-ip-watch.service \
    bmo-usb-swap-screen.service \
    bmo-usb-tether-auto.service
do

    COUNT="$(
        find "$ROOT/etc/systemd/system" \
            -type l \
            -name "$UNIT" |
        wc -l
    )"

    [ "$COUNT" -eq 0 ] || {
        die "optional enabled indevidamente: $UNIT"
    }

done


[ ! -e "$ROOT/home/r36s/.ssh" ]
[ ! -e "$ROOT/home/r36s/.config/moonlight" ]
[ ! -e "$ROOT/home/r36s/.config/chromium" ]
[ ! -e "$ROOT/opt/bmo-ui/game-covers" ]


NM="$ROOT/etc/NetworkManager/system-connections"

if [ -d "$NM" ]; then

    NM_FILES="$(
        find "$NM" \
            -mindepth 1 \
            -maxdepth 1 \
            -type f |
        wc -l
    )"

    echo "NETWORK_PROFILES=$NM_FILES"

    [ "$NM_FILES" -eq 0 ]

fi


FRONTEND_SHA="$(
    sha256sum "$ROOT/opt/bmo-ui/index.html" |
    awk '{print $1}'
)"

echo "FRONTEND_SHA=$FRONTEND_SHA"

[ "$FRONTEND_SHA" = \
  "ba55304de35bf73c01c3946da91cadef62a686bb6ac900b65c46cb588a671a03" ]


PPSSPP_BIN_SHA="$(
    sha256sum \
        "$ROOT/opt/src/ppsspp/build-bmo/PPSSPPSDL" |
    awk '{print $1}'
)"

echo "PPSSPP_BINARY_SHA=$PPSSPP_BIN_SHA"

[ "$PPSSPP_BIN_SHA" = \
  "a69d28a61ef9da9aad675740ec96eade4a1240ffac5be79651f02457f686bba8" ]


rm -f \
    "$ROOT/.bmo-ready-build-root" \
    "$ROOT/.bmo-ready-sandbox" \
    "$ROOT/.bmo-apply-v3-sandbox"

sync

echo "FINAL_FILESYSTEM_VALIDATION_OK"


echo
echo "[12/12] Desmontando e comprimindo..."

umount -R "$ROOT"

losetup -d "$LOOP"
LOOP=""

OUTPUT="$OUTPUT_DIR/BMO-R36S-Ready-v${VERSION}-candidate.img.xz"

rm -f "$OUTPUT"

xz \
    -T0 \
    -6 \
    -c \
    "$WORK_IMG" \
    > "$OUTPUT"

xz -t "$OUTPUT"

READY_SHA="$(
    sha256sum "$OUTPUT" |
    awk '{print $1}'
)"

READY_SIZE="$(
    stat -c '%s' "$OUTPUT"
)"


MANIFEST="$OUTPUT_DIR/BMO-R36S-Ready-v${VERSION}-candidate.txt"

cat > "$MANIFEST" <<EOF
BMO R36S Ready v${VERSION} Candidate

Git commit:
$GIT_COMMIT

Pure source:
$(basename "$PURE_XZ")

Pure SHA256:
$PURE_SHA

PPSSPP runtime SHA256:
$PPSSPP_SHA

Ready candidate:
$(basename "$OUTPUT")

Ready size:
$READY_SIZE

Ready SHA256:
$READY_SHA

ROM files:
0

Wi-Fi profiles:
0

Moonlight pairing:
not packaged

System services enabled:
10

Optional USB services enabled:
0
EOF


printf '%s  %s\n' \
    "$READY_SHA" \
    "$(basename "$OUTPUT")" \
    > "$OUTPUT.sha256"


rm -rf "$WORKDIR"

SUCCESS=1


echo
echo "============================================================"
echo " BMO_READY_IMAGE_CANDIDATE_OK"
echo "============================================================"
echo "OUTPUT=$OUTPUT"
echo "SHA256=$READY_SHA"
echo "SIZE=$READY_SIZE"
echo "GIT_COMMIT=$GIT_COMMIT"
echo "MANIFEST=$MANIFEST"
