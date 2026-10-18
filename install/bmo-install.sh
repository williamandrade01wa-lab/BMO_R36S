#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# BMO Ready R36S Installer
# v1.0.0
#
# Estado atual:
#   DRY-RUN completo
#   APPLY v1 somente em raiz SANDBOX
#
# APPLY v1:
#   - nunca permite TARGET_ROOT=/
#   - exige marcador .bmo-apply-v1-sandbox
#   - escreve somente filesystem/frontend
#   - demais fases permanecem PLAN_ONLY
# ============================================================

SCRIPT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

REPO_ROOT="$(
    cd "$SCRIPT_DIR/.." &&
    pwd
)"

MANIFEST="$SCRIPT_DIR/manifests/ready-v1.0.0.env"
PACKAGES="$SCRIPT_DIR/packages/audited-runtime.txt"
ENABLED_SERVICES="$SCRIPT_DIR/manifests/enabled-services.txt"
OPTIONAL_SERVICES="$SCRIPT_DIR/manifests/optional-services.txt"

MODE=""
PPSSPP_RUNTIME=""
TARGET_ROOT="/"


usage() {

    cat <<'EOF'

BMO Ready R36S Installer v1.0.0

Dry-run:

  ./install/bmo-install.sh --dry-run

Sandbox APPLY v1:

  sudo ./install/bmo-install.sh \
      --apply \
      --root /caminho/sandbox \
      --ppsspp-runtime /caminho/runtime.tar.gz

IMPORTANTE:

  APPLY v1 NÃO pode usar / como destino.
  O destino precisa conter:

    .bmo-apply-v1-sandbox

  Somente filesystem/frontend são escritos.
  As fases seguintes continuam PLAN_ONLY.

EOF
}


die() {

    echo
    echo "ERRO: $*" >&2
    exit 1
}


phase() {

    NUMBER="$1"
    TITLE="$2"

    echo
    echo "============================================================"
    printf " %02d. %s\n" "$NUMBER" "$TITLE"
    echo "============================================================"
}


require_file() {

    FILE="$1"

    [ -f "$FILE" ] || {
        die "arquivo obrigatório ausente: $FILE"
    }
}


require_dir() {

    DIR="$1"

    [ -d "$DIR" ] || {
        die "diretório obrigatório ausente: $DIR"
    }
}


check_sha() {

    FILE="$1"
    EXPECTED="$2"
    LABEL="$3"

    require_file "$FILE"

    ACTUAL="$(
        sha256sum "$FILE" |
        awk '{print $1}'
    )"

    printf '%-30s %s\n' "$LABEL" "$ACTUAL"

    [ "$ACTUAL" = "$EXPECTED" ] || {
        die "$LABEL SHA256 divergente"
    }
}


plan_copy() {

    SOURCE="$1"
    DESTINATION="$2"
    MODE_BITS="$3"

    require_file "$REPO_ROOT/$SOURCE"

    printf 'COPY   %-55s -> %s [%s]\n' \
        "$SOURCE" \
        "$DESTINATION" \
        "$MODE_BITS"
}


target_path() {

    ABSOLUTE_PATH="$1"

    case "$ABSOLUTE_PATH" in
        /*)
            ;;
        *)
            die "target_path exige caminho absoluto: $ABSOLUTE_PATH"
            ;;
    esac

    printf '%s%s\n' \
        "${TARGET_ROOT%/}" \
        "$ABSOLUTE_PATH"
}


apply_copy() {

    SOURCE="$1"
    DESTINATION="$2"
    MODE_BITS="$3"

    require_file "$REPO_ROOT/$SOURCE"

    TARGET="$(
        target_path "$DESTINATION"
    )"

    echo "APPLY  $SOURCE -> $TARGET [$MODE_BITS]"

    install \
        -D \
        -o root \
        -g root \
        -m "$MODE_BITS" \
        "$REPO_ROOT/$SOURCE" \
        "$TARGET"
}


while [ "$#" -gt 0 ]; do

    case "$1" in

        --dry-run)
            MODE="dry-run"
            shift
            ;;

        --ppsspp-runtime)

            [ "$#" -ge 2 ] || {
                die "--ppsspp-runtime requer um caminho"
            }

            PPSSPP_RUNTIME="$2"
            shift 2
            ;;

        --apply)
            MODE="apply"
            shift
            ;;

        --root)

            [ "$#" -ge 2 ] || {
                die "--root requer um caminho"
            }

            TARGET_ROOT="$2"
            shift 2
            ;;

        -h|--help)
            usage
            exit 0
            ;;

        *)
            die "argumento desconhecido: $1"
            ;;

    esac

done


case "$MODE" in

    dry-run)
        ;;

    apply)

        [ "$EUID" -eq 0 ] || {
            die "--apply requer root"
        }

        case "$TARGET_ROOT" in
            /*)
                ;;
            *)
                die "--root precisa ser caminho absoluto"
                ;;
        esac

        [ -d "$TARGET_ROOT" ] || {
            die "TARGET_ROOT precisa existir previamente: $TARGET_ROOT"
        }

        TARGET_ROOT="$(
            readlink -f -- "$TARGET_ROOT"
        )"

        [ -n "$TARGET_ROOT" ] || {
            die "nao foi possivel resolver TARGET_ROOT"
        }

        [ "$TARGET_ROOT" != "/" ] || {
            die "APPLY v1 recusa TARGET_ROOT=/"
        }

        [ -f "$TARGET_ROOT/.bmo-apply-v1-sandbox" ] || {
            die "marcador .bmo-apply-v1-sandbox ausente em $TARGET_ROOT"
        }

        ;;

    *)
        usage
        die "use --dry-run ou --apply"
        ;;

esac


echo "============================================================"
echo " BMO READY v1.0.0 INSTALLER"

if [ "$MODE" = "dry-run" ]; then

    echo " MODE=DRY-RUN"

else

    echo " MODE=APPLY-v1-SANDBOX"

fi

echo "============================================================"

echo
echo "SOURCE=$REPO_ROOT"

if [ "$MODE" = "dry-run" ]; then

    echo "NO SYSTEM CHANGES WILL BE PERFORMED"

else

    echo "TARGET_ROOT=$TARGET_ROOT"
    echo "REAL_ROOT_WRITE=BLOCKED"
    echo "APPLY_SCOPE=filesystem+frontend"

fi


# ============================================================
# 01 validate-base
# ============================================================

phase 1 "validate-base"

require_file "$MANIFEST"

# shellcheck disable=SC1090
. "$MANIFEST"

echo "READY_VERSION=$BMO_READY_VERSION"
echo "BASE_COMMIT=$BMO_BASE_GIT_COMMIT"

[ "$BMO_READY_VERSION" = "1.0.0" ] || {
    die "versão inesperada no manifest"
}

ARCH="$(uname -m)"

echo "HOST_ARCH=$ARCH"

case "$ARCH" in
    aarch64|arm64)
        echo "ARCH_COMPATIBLE=YES"
        ;;
    *)
        echo "ARCH_COMPATIBLE=NO"
        echo "INFO: permitido durante planejamento fora do R36S."
        ;;
esac

if [ -r /etc/os-release ]; then

    . /etc/os-release

    echo "HOST_OS=${PRETTY_NAME:-UNKNOWN}"

fi

echo
echo "NOTA:"
echo "O dry-run valida a receita."
echo "A validação rígida da BMO Linux Pure será adicionada"
echo "antes de habilitarmos --apply."


# ============================================================
# 02 packages
# ============================================================

phase 2 "packages"

require_file "$PACKAGES"

echo "Pacotes comprovados no baseline:"
echo

grep -Ev '^[[:space:]]*(#|$)' "$PACKAGES" |
while IFS= read -r PACKAGE; do

    echo "APT    $PACKAGE"

done

echo
echo "STATUS=PLAN_ONLY"
echo "Nenhum apt install será executado."


# ============================================================
# 03 user-groups
# ============================================================

phase 3 "user-groups"

cat <<'EOF'
USER   r36s

Runtime groups comprovadamente relevantes:
  audio
  video
  input
  render
  tty

Grupos adicionais foram observados no aparelho de referência,
mas NÃO serão adicionados automaticamente até revisão de
privilégio mínimo.

STATUS=POLICY_PENDING
EOF


# ============================================================
# 04 filesystem
# ============================================================

phase 4 "filesystem"

cat <<'EOF'
CREATE /opt/bmo-ui
CREATE /opt/src/ppsspp/build-bmo

CREATE /home/r36s/.config/retroarch
CREATE /home/r36s/.config/ppsspp/PSP/SYSTEM

PRESERVE /boot
PRESERVE kernel
PRESERVE DTB
PRESERVE bootloader
PRESERVE existing /etc/fstab

DO NOT COPY system/fstab.r36s over /etc/fstab
EOF

if [ "$MODE" = "apply" ]; then

    UI_DIR="$(
        target_path /opt/bmo-ui
    )"

    echo
    echo "APPLY v1 filesystem:"
    echo "CREATE $UI_DIR"

    install \
        -d \
        -o root \
        -g root \
        -m 0755 \
        "$UI_DIR"

    echo "FILESYSTEM_APPLY_V1_OK"

else

    echo
    echo "STATUS=PLAN_ONLY"

fi


# ============================================================
# 05 frontend
# ============================================================

phase 5 "frontend"

check_sha \
    "$REPO_ROOT/frontend/index.html" \
    "$BMO_FRONTEND_SHA256" \
    "frontend production"

check_sha \
    "$REPO_ROOT/frontend/index.bmo-next.html" \
    "$BMO_FRONTEND_SHA256" \
    "frontend candidate"

cmp -s \
    "$REPO_ROOT/frontend/index.html" \
    "$REPO_ROOT/frontend/index.bmo-next.html" ||
    die "production e candidate não são idênticos"

echo
echo "FRONTEND_IDENTICAL=YES"

plan_copy \
    "frontend/index.html" \
    "/opt/bmo-ui/index.html" \
    "0644"

plan_copy \
    "frontend/index.bmo-next.html" \
    "/opt/bmo-ui/index.bmo-next.html" \
    "0644"

if [ "$MODE" = "apply" ]; then

    echo
    echo "APPLY v1 frontend:"

    apply_copy \
        "frontend/index.html" \
        "/opt/bmo-ui/index.html" \
        "0644"

    apply_copy \
        "frontend/index.bmo-next.html" \
        "/opt/bmo-ui/index.bmo-next.html" \
        "0644"

    TARGET_PROD="$(
        target_path /opt/bmo-ui/index.html
    )"

    TARGET_CAND="$(
        target_path /opt/bmo-ui/index.bmo-next.html
    )"

    check_sha \
        "$TARGET_PROD" \
        "$BMO_FRONTEND_SHA256" \
        "installed production"

    check_sha \
        "$TARGET_CAND" \
        "$BMO_FRONTEND_SHA256" \
        "installed candidate"

    cmp -s \
        "$TARGET_PROD" \
        "$TARGET_CAND" ||
        die "frontend instalado divergiu"

    echo "FRONTEND_APPLY_V1_OK"

fi


# ============================================================
# 06 backend
# ============================================================

phase 6 "backend"

plan_copy \
    "backend/bmo-control-api.py" \
    "/usr/local/bin/bmo-control-api.py" \
    "0755"


# ============================================================
# 07 launchers
# ============================================================

phase 7 "launchers"

plan_copy \
    "launchers/bmo-game-launcher.py" \
    "/usr/local/bin/bmo-game-launcher.py" \
    "0755"

plan_copy \
    "launchers/bmo-kiosk.sh" \
    "/usr/local/bin/bmo-kiosk.sh" \
    "0755"

plan_copy \
    "launchers/bmo-moonlight-hotkeys.py" \
    "/usr/local/bin/bmo-moonlight-hotkeys.py" \
    "0755"

plan_copy \
    "launchers/bmo-moonlight-launch.sh" \
    "/usr/local/bin/bmo-moonlight-launch.sh" \
    "0755"

plan_copy \
    "scripts/runtime/bmo-game-hwkeys.py" \
    "/usr/local/bin/bmo-game-hwkeys.py" \
    "0755"

plan_copy \
    "scripts/runtime/bmo-x-init.sh" \
    "/usr/local/bin/bmo-x-init.sh" \
    "0755"

plan_copy \
    "scripts/runtime/bmo-usb-ip-watch.sh" \
    "/usr/local/bin/bmo-usb-ip-watch.sh" \
    "0755"

plan_copy \
    "scripts/runtime/bmo-usb-swap-screen.sh" \
    "/usr/local/bin/bmo-usb-swap-screen.sh" \
    "0755"

plan_copy \
    "scripts/runtime/bmo-usb-tether-auto.sh" \
    "/usr/local/bin/bmo-usb-tether-auto.sh" \
    "0755"

plan_copy \
    "scripts/runtime/r36s-battery-api.py" \
    "/usr/local/bin/r36s-battery-api.py" \
    "0755"

plan_copy \
    "scripts/runtime/r36s-sound-api.py" \
    "/usr/local/bin/r36s-sound-api.py" \
    "0755"

plan_copy \
    "scripts/runtime/r36s-status-api.py" \
    "/usr/local/bin/r36s-status-api.py" \
    "0755"


# ============================================================
# 08 retroarch
# ============================================================

phase 8 "retroarch"

plan_copy \
    "configs/retroarch/retroarch.cfg" \
    "/home/r36s/.config/retroarch/retroarch.cfg" \
    "0644"

plan_copy \
    "configs/retroarch/config/mGBA/mGBA.opt" \
    "/home/r36s/.config/retroarch/config/mGBA/mGBA.opt" \
    "0644"

cat <<'EOF'

Expected cores:
  /usr/lib/aarch64-linux-gnu/libretro/mgba_libretro.so
  /usr/lib/aarch64-linux-gnu/libretro/snes9x_libretro.so

STATUS=PLAN_ONLY
EOF


# ============================================================
# 09 ppsspp
# ============================================================

phase 9 "ppsspp"

echo "VERSION=$BMO_PPSSPP_VERSION"
echo "SOURCE_COMMIT=$BMO_PPSSPP_GIT_COMMIT"
echo "EXPECTED_BINARY_SHA=$BMO_PPSSPP_BINARY_SHA256"
echo "EXPECTED_RUNTIME_SHA=$BMO_PPSSPP_RUNTIME_SHA256"

plan_copy \
    "configs/ppsspp/PSP/SYSTEM/controls.ini" \
    "/home/r36s/.config/ppsspp/PSP/SYSTEM/controls.ini" \
    "0644"

plan_copy \
    "configs/ppsspp/PSP/SYSTEM/ppsspp.ini" \
    "/home/r36s/.config/ppsspp/PSP/SYSTEM/ppsspp.ini" \
    "0644"

if [ -n "$PPSSPP_RUNTIME" ]; then

    echo
    echo "Validando runtime fornecido..."

    require_file "$PPSSPP_RUNTIME"

    RUNTIME_SHA="$(
        sha256sum "$PPSSPP_RUNTIME" |
        awk '{print $1}'
    )"

    echo "RUNTIME_SHA=$RUNTIME_SHA"

    [ "$RUNTIME_SHA" = "$BMO_PPSSPP_RUNTIME_SHA256" ] || {
        die "PPSSPP runtime SHA divergente"
    }

    TMP_LIST="$(mktemp)"

    trap 'rm -f "$TMP_LIST"' EXIT

    tar -tzf "$PPSSPP_RUNTIME" > "$TMP_LIST"

    grep -q '/runtime/PPSSPPSDL$' "$TMP_LIST" || {
        die "PPSSPPSDL não encontrado no runtime"
    }

    grep -q '/runtime/assets/' "$TMP_LIST" || {
        die "assets PPSSPP não encontrados no runtime"
    }

    echo "PPSSPP_RUNTIME_ARCHIVE_OK"

else

    echo
    echo "PPSSPP_RUNTIME=NOT_PROVIDED"
    echo "INFO: obrigatório antes de uma instalação real."

fi

echo
echo "TARGET=/opt/src/ppsspp/build-bmo"
echo "STATUS=PLAN_ONLY"


# ============================================================
# 10 moonlight
# ============================================================

phase 10 "moonlight"

cat <<EOF
PACKAGE=moonlight-qt
REFERENCE_VERSION=$BMO_MOONLIGHT_QT_VERSION

PAIRING=NOT_PACKAGED
Moonlight.conf=NOT_PACKAGED

Sunshine host:
  configurado posteriormente por bmo-configure.sh

STATUS=PLAN_ONLY
EOF


# ============================================================
# 11 system-config
# ============================================================

phase 11 "system-config"

plan_copy \
    "deploy/r36s/bmo-kiosk.default" \
    "/etc/default/bmo-kiosk" \
    "0644"

plan_copy \
    "install/system/udev/99-bmo-usb-power.rules" \
    "/etc/udev/rules.d/99-bmo-usb-power.rules" \
    "0644"

plan_copy \
    "deploy/r36s/bmo-deploy.sudoers" \
    "/etc/sudoers.d/bmo-deploy" \
    "0440"

plan_copy \
    "deploy/r36s/bmo-deploy-helper" \
    "/usr/local/sbin/bmo-deploy-helper" \
    "0755"

cat <<'EOF'

XORG:
  preserve base configuration from BMO Linux Pure
  no BMO xorg.conf will be installed

FSTAB:
  preserve root and boot entries
  SD2 entry will be handled by configurator

STATUS=PLAN_ONLY
EOF


# ============================================================
# 12 systemd
# ============================================================

phase 12 "systemd"

SYSTEMD_UNITS=(
    bmo-control-api.service
    bmo-kiosk.service
    bmo-ui.service
    bmo-usb-ip-watch.service
    bmo-usb-swap-screen.service
    bmo-usb-tether-auto.service
    bmo-vt.service
    bmo-x-init.service
    bmo-xorg.service
    r36s-battery-api.service
    r36s-console.service
    r36s-sound-api.service
    r36s-status-api.service
)

for UNIT in "${SYSTEMD_UNITS[@]}"; do

    plan_copy \
        "systemd/$UNIT" \
        "/etc/systemd/system/$UNIT" \
        "0644"

done

echo
echo "ENABLE ON READY:"

grep -Ev '^[[:space:]]*(#|$)' "$ENABLED_SERVICES" |
while IFS= read -r UNIT; do
    echo "ENABLE $UNIT"
done

echo
echo "INSTALL BUT KEEP DISABLED:"

grep -Ev '^[[:space:]]*(#|$)' "$OPTIONAL_SERVICES" |
while IFS= read -r UNIT; do
    echo "DISABLE $UNIT"
done

echo
echo "STATUS=PLAN_ONLY"


# ============================================================
# 13 permissions
# ============================================================

phase 13 "permissions"

cat <<'EOF'
OWNER root:root
  /opt/bmo-ui/*
  /usr/local/bin/bmo-*
  /usr/local/bin/r36s-*
  /usr/local/sbin/bmo-*
  /etc/systemd/system/*
  /etc/udev/rules.d/99-bmo-usb-power.rules

OWNER r36s:r36s
  /home/r36s/.config/retroarch
  /home/r36s/.config/ppsspp
  /home/r36s/ROMs

SPECIAL
  /etc/sudoers.d/bmo-deploy = root:root 0440

STATUS=PLAN_ONLY
EOF


# ============================================================
# 14 empty-rom-layout
# ============================================================

phase 14 "empty-rom-layout"

cat <<'EOF'
CREATE EMPTY:
  /home/r36s/ROMs/gba
  /home/r36s/ROMs/sfc
  /home/r36s/ROMs/psp

OPTIONAL SD2 AFTER CONFIGURATION:
  /mnt/bmo-sd2/EASYROMS/gba
  /mnt/bmo-sd2/EASYROMS/sfc
  /mnt/bmo-sd2/EASYROMS/psp
  /mnt/bmo-sd2/EASYROMS/saves
  /mnt/bmo-sd2/EASYROMS/states

DO NOT COPY:
  ROMs
  ISOs
  SAVEDATA
  save states
  favorites
  game covers

STATUS=PLAN_ONLY
EOF


# ============================================================
# 15 verify
# ============================================================

phase 15 "verify"

require_file "$ENABLED_SERVICES"
require_file "$OPTIONAL_SERVICES"

ENABLED_COUNT="$(
    grep -Ev '^[[:space:]]*(#|$)' "$ENABLED_SERVICES" |
    wc -l
)"

OPTIONAL_COUNT="$(
    grep -Ev '^[[:space:]]*(#|$)' "$OPTIONAL_SERVICES" |
    wc -l
)"

echo "REQUIRED_ENABLED_SERVICES=$ENABLED_COUNT"
echo "OPTIONAL_DISABLED_SERVICES=$OPTIONAL_COUNT"

[ "$ENABLED_COUNT" -eq 10 ] || {
    die "quantidade inesperada de serviços habilitados"
}

[ "$OPTIONAL_COUNT" -eq 3 ] || {
    die "quantidade inesperada de serviços opcionais"
}

echo
echo "VERIFY PLAN:"
echo "  frontend SHA"
echo "  backend health"
echo "  systemd services"
echo "  Xorg :0"
echo "  kiosk"
echo "  RetroArch cores"
echo "  PPSSPP binary"
echo "  Moonlight Qt"
echo "  gamepad"
echo "  audio"
echo "  brightness"
echo "  no ROMs"
echo "  no credentials"

echo
echo "============================================================"

if [ "$MODE" = "dry-run" ]; then

    echo " BMO_READY_INSTALL_DRY_RUN_OK"
    echo "============================================================"
    echo
    echo "No files outside the repository were modified."

else

    echo " BMO_READY_INSTALL_APPLY_V1_OK"
    echo "============================================================"
    echo
    echo "Only the sandbox target root was modified:"
    echo "$TARGET_ROOT"

fi
