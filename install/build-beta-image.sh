#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd -- "$(dirname -- "$0")/.." && pwd)"
BASE="";PPSSPP="";OUT="";WORK="";LOOP="";ROOT=""
RESUME=NO
VERSION=1.0.0-beta.1
BASE_SHA=33e250518619c9cfecc2a846fa9a68e4bc213a5f1731d93cd07cffcaa61e9996
PPSSPP_SHA=1af91efd8374a2c164e5f2ffa37b3d65980b825a207cbb09c688b2997088c5ad
die(){ echo "[BMO-BETA] ERROR: $*" >&2;exit 1; }
log(){ echo "[BMO-BETA] $*"; }
cleanup(){
    if [ -n "$ROOT" ] && mountpoint -q "$ROOT";then umount -R "$ROOT" || return 1;fi
    if [ -n "$LOOP" ];then losetup -d "$LOOP";fi
}
trap cleanup EXIT
while [ "$#" -gt 0 ];do case "$1" in
    --resume-work) RESUME=YES;shift;;
    --base-raw) BASE="$2";shift 2;;
    --ppsspp-runtime) PPSSPP="$2";shift 2;;
    --output-dir) OUT="$2";shift 2;;
    --work-dir) WORK="$2";shift 2;;
    *) die "unknown option: $1";;
esac;done
[ "$EUID" -eq 0 ] || die 'root required'
[ "$(uname -m)" = aarch64 ] || die 'native aarch64 builder required'
[ -f "$BASE" ] && [ -f "$PPSSPP" ] && [ -n "$OUT" ] && [ -n "$WORK" ] || die 'base/runtime/output/work required'
BASE="$(realpath -e "$BASE")";PPSSPP="$(realpath -e "$PPSSPP")"
if [ "$RESUME" = NO ];then
    [ ! -e "$WORK" ] || die 'work directory must be new'
else
    [ -d "$WORK" ] && [ ! -L "$WORK" ] || die 'resume requires existing real work directory'
fi
install -d -m 0755 "$OUT" "$WORK"
OUT="$(realpath -e "$OUT")";WORK="$(realpath -e "$WORK")"
OUTPUT="$OUT/BMO-R36S-Ready-v$VERSION.img.xz"
[ ! -e "$OUTPUT" ] || die 'output exists; refusing overwrite'
for cmd in sfdisk losetup e2fsck resize2fs mount chroot xz python3;do command -v "$cmd" >/dev/null || die "missing host tool: $cmd";done
GIT_SHA="$(git -c safe.directory="$REPO" -C "$REPO" rev-parse HEAD)"
git -c safe.directory="$REPO" -C "$REPO" diff --quiet || die 'tracked source changes not committed'
python3 - "$REPO" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
wizard = (root / 'scripts/windows/BMO-Preparar-Cartao.ps1').read_text(encoding='utf-8-sig')
assert "version='0.2.2'" in wizard
assert 'Get-BmoSha256' in wizard and 'Get-FileHash' not in wizard
assert 'v0.2.2' in (root / 'scripts/windows/LEIA-ME.txt').read_text(encoding='utf-8-sig')
print('BMO_WIZARD_HASH_CONTRACT_OK')
PY
log "VERSION=$VERSION SOURCE=$GIT_SHA"
echo "$BASE_SHA  $BASE" | sha256sum -c -
echo "$PPSSPP_SHA  $PPSSPP" | sha256sum -c -
[ "$(df --output=avail -B1 "$WORK" | tail -1)" -gt 16000000000 ] || die '16 GB free required'
IMAGE="$WORK/BMO-R36S-Ready-v$VERSION.img"
if [ "$RESUME" = NO ];then
cp --reflink=auto --sparse=always "$BASE" "$IMAGE"
sfdisk --json "$IMAGE" > "$WORK/partition-before.json"
read -r START SECTORS < <(python3 - "$WORK/partition-before.json" <<'PY'
import json,sys
p=json.load(open(sys.argv[1]))["partitiontable"]["partitions"]
assert len(p)==2 and p[1]["type"].lower()=="83"
start=p[1]["start"]
print(start,(12*1024**3)//512-start)
PY
)
truncate -s 12G "$IMAGE"
printf 'start=%s,size=%s,type=83\n' "$START" "$SECTORS" | sfdisk --no-reread --force -N 2 "$IMAGE"
else
    [ -f "$IMAGE" ] && [ ! -L "$IMAGE" ] || die 'resume image missing or symlink'
    [ "$(stat -c %s "$IMAGE")" = 12884901888 ] || die 'resume image size mismatch'
    log 'Resuming stopped image work; checks and installation are repeated'
fi
LOOP="$(losetup --find --show --partscan "$IMAGE")";udevadm settle
ROOT_PART="$LOOP"p2;BOOT_PART="$LOOP"p1
if e2fsck -pf "$ROOT_PART";then :;else rc=$?;[ "$rc" -le 1 ] || die 'ext4 check failed';fi
resize2fs "$ROOT_PART"
ROOT="$WORK/root";mkdir -p "$ROOT";mount "$ROOT_PART" "$ROOT"
install -d "$ROOT/boot/u-boot";mount "$BOOT_PART" "$ROOT/boot/u-boot"
(cd "$REPO/assets/boot" && sha256sum -c logo.bmp.sha256)
cp "$REPO/assets/boot/logo.bmp" "$ROOT/boot/u-boot/logo.bmp"
cmp "$REPO/assets/boot/logo.bmp" "$ROOT/boot/u-boot/logo.bmp"
[ -f "$ROOT/etc/bmo/base-version.env" ] || die 'not a BMO Base'
[ "$(chroot "$ROOT" dpkg --print-architecture)" = arm64 ] || die 'target not arm64'
if [ "$RESUME" = YES ];then
    [ -f "$ROOT/.bmo-ready-build-root" ] || die 'resume target lacks build marker'
    [ -z "$(chroot "$ROOT" dpkg --audit)" ] || die 'resume target has incomplete packages'
fi
touch "$ROOT/.bmo-ready-build-root" "$ROOT/.bmo-ready-sandbox" "$ROOT/.bmo-apply-v3-sandbox"
# Suppress Armbian login hooks before any package setup invokes bash -l.
rm -f "$ROOT/root/.not_logged_in_yet"
install -m 0755 "$REPO/image/armbian/userpatches/overlay/usr/local/sbin/bmo-firstboot" "$ROOT/usr/local/sbin/bmo-firstboot"
mount --rbind /dev "$ROOT/dev";mount --make-rslave "$ROOT/dev"
mount -t proc proc "$ROOT/proc"
mount --rbind /sys "$ROOT/sys";mount --make-rslave "$ROOT/sys"
# Do not expose the host systemd/D-Bus sockets.
mount -t tmpfs -o mode=0755 tmpfs "$ROOT/run"
if [ "$RESUME" = NO ];then
    cp -a --no-dereference "$ROOT/etc/resolv.conf" "$WORK/resolv.conf.original"
    if [ -e "$ROOT/usr/sbin/policy-rc.d" ];then cp -a "$ROOT/usr/sbin/policy-rc.d" "$WORK/policy.original";fi
else
    [ -e "$WORK/resolv.conf.original" ] || [ -L "$WORK/resolv.conf.original" ] || die 'resume lacks original resolver backup'
fi
rm -f "$ROOT/etc/resolv.conf";cp -L /etc/resolv.conf "$ROOT/etc/resolv.conf"
printf '#!/bin/sh\nexit 101\n' > "$ROOT/usr/sbin/policy-rc.d";chmod 755 "$ROOT/usr/sbin/policy-rc.d"
log 'Installing prerequisites inside the image'
bash "$REPO/install/phases/60-prereqs.sh" --root "$ROOT" --apply
mapfile -t EXTRAS < <(grep -Ev '^[[:space:]]*(#|$)' "$REPO/install/beta/extra-packages.txt")
chroot "$ROOT" /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${EXTRAS[@]}"
log 'Installing audited BMO frontend/backend/launchers/emulators'
bash "$REPO/install/bmo-install.sh" --beta-pins --apply --root "$ROOT" --ppsspp-runtime "$PPSSPP"
bash "$REPO/install/beta/integrate-system.sh" --root "$ROOT"
install -m 0755 "$REPO/image/armbian/userpatches/overlay/usr/local/sbin/bmo-firstboot" "$ROOT/usr/local/sbin/bmo-firstboot"
install -D -m 0644 "$REPO/image/armbian/userpatches/overlay/etc/profile.d/90-bmo-welcome.sh" "$ROOT/etc/profile.d/90-bmo-welcome.sh"
for file in BMO-FIRSTBOOT.txt README-FIRST-BOOT.txt;do
    cp "$REPO/image/armbian/userpatches/overlay/usr/share/bmo/$file" "$ROOT/boot/u-boot/$file"
    cp "$REPO/image/armbian/userpatches/overlay/usr/share/bmo/$file" "$ROOT/usr/share/bmo/$file"
done
cp "$REPO/scripts/windows/ABRIR-BMO.cmd" "$REPO/scripts/windows/BMO-Preparar-Cartao.ps1" "$REPO/scripts/windows/LEIA-ME.txt" "$ROOT/boot/u-boot/"
cp "$REPO/install/beta/README-BETA.txt" "$ROOT/boot/u-boot/README-BETA.txt"
install -d "$ROOT/usr/share/doc/bmo-beta"
cp "$REPO/THIRD_PARTY.md" "$REPO/CREDITS.md" "$ROOT/usr/share/doc/bmo-beta/"
printf 'BMO_READY_VERSION=%s\nBMO_SOURCE_COMMIT=%s\nBMO_BASE_RUN=40118103143\n' "$VERSION" "$GIT_SHA" > "$ROOT/etc/bmo/ready-version.env"
log 'Offline verification'
systemd-analyze --root="$ROOT" verify bmo-ready-firstboot.service bmo-kiosk.service bmo-xorg.service bmo-ui.service bmo-sd2-auto.service
bash "$REPO/install/phases/60-prereqs.sh" --root "$ROOT" --check
for command in chromium Xorg xdpyinfo xauth unclutter dbus-run-session pulseaudio retroarch moonlight-qt;do
    chroot "$ROOT" /bin/sh -c "command -v $command" || die "missing runtime: $command"
done
chroot "$ROOT" /bin/sh -c 'ldd /opt/src/ppsspp/build-bmo/PPSSPPSDL' > "$WORK/ppsspp-ldd.txt"
! grep -q 'not found' "$WORK/ppsspp-ldd.txt" || die 'PPSSPP shared library missing'
python3 - "$ROOT" "$REPO" <<'PY'
import pathlib,sys
r=pathlib.Path(sys.argv[1]);source=pathlib.Path(sys.argv[2])
for src in [source/"backend/bmo-control-api.py",source/"launchers/bmo-game-launcher.py"]:
    dest=r/"usr/local/bin"/src.name
    compile(dest.read_text(),str(dest),"exec")
    assert dest.read_bytes()==src.read_bytes()
for line in (source/"install/manifests/enabled-services.txt").read_text().splitlines():
    if not line or line.startswith("#"):continue
    assert (r/"etc/systemd/system"/line).is_file()
    assert list((r/"etc/systemd/system").glob("*.wants/"+line))
    drop=r/"etc/systemd/system"/(line+".d")/"10-ready-firstboot.conf"
    assert "Requires=bmo-ready-firstboot.service" in drop.read_text()
assert (r/"boot/u-boot/ABRIR-BMO.cmd").is_file()
assert (r/"boot/u-boot/BMO-FIRSTBOOT.txt").is_file()
policy=r/"etc/chromium/policies/managed/bmo-kiosk.json"
assert policy.is_file(), "Chromium translation policy missing from beta"
assert policy.read_bytes()==(source/"install/system/chromium/bmo-kiosk.json").read_bytes()
assert (r/"etc/systemd/system/bmo-ready-firstboot.service").is_file()
assert not (r/"root/.not_logged_in_yet").exists()
assert not [p for p in (r/"home/r36s/ROMs").rglob("*") if p.is_file()]
print("BMO_BETA_OFFLINE_CONTRACT_OK")
PY
chroot "$ROOT" dpkg-query -W -f='${Package}\t${Version}\n' > "$OUT/BMO-R36S-Ready-v$VERSION.packages.tsv"
chroot "$ROOT" apt-get clean
rm -f "$ROOT/usr/sbin/policy-rc.d"
if [ -e "$WORK/policy.original" ];then cp -a "$WORK/policy.original" "$ROOT/usr/sbin/policy-rc.d";fi
rm -f "$ROOT/etc/resolv.conf";cp -a --no-dereference "$WORK/resolv.conf.original" "$ROOT/etc/resolv.conf"
log 'Sanitizing image only'
bash "$REPO/install/phases/70-sanitize.sh" --root "$ROOT"
rm -rf "$ROOT/var/lib/bmo"
rm -f "$ROOT/boot/u-boot/BMO-IP.txt" "$ROOT/boot/u-boot/BMO-STATUS.txt" "$ROOT/boot/u-boot/BMO-RESUMO.txt"
rm -rf "$ROOT/boot/u-boot/logs"
rm -f "$ROOT/.bmo-ready-build-root" "$ROOT/.bmo-ready-sandbox" "$ROOT/.bmo-apply-v3-sandbox"
[ ! -e "$ROOT/root/.ssh" ] && [ ! -e "$ROOT/home/r36s/.ssh" ]
[ -z "$(find "$ROOT/etc/NetworkManager/system-connections" -type f -print -quit)" ]
sync;cleanup;ROOT="";LOOP=""
log 'Compressing candidate: one thread, bounded memory'
xz -T1 -3 --check=crc64 --keep "$IMAGE"
mv "$IMAGE.xz" "$OUTPUT"
xz -t "$OUTPUT"
(cd "$OUT" && sha256sum "$(basename "$OUTPUT")" > "$(basename "$OUTPUT").sha256")
{
    echo "BMO Ready $VERSION - private beta candidate"
    echo "Source commit: $GIT_SHA"
    echo "Base Run: 40118103143"
    echo "Base raw SHA256: $BASE_SHA"
    echo "PPSSPP runtime SHA256: $PPSSPP_SHA"
    echo "Boot/hardware validation: PENDING"
    echo "TF2: outside during first boot"
    echo "No ROMs, pairing, Wi-Fi profiles, SSH keys or Git credentials"
} > "$OUT/BMO-R36S-Ready-v$VERSION.manifest.txt"
log "BMO_READY_BETA_IMAGE_OK OUTPUT=$OUTPUT"
cat "$OUTPUT.sha256"
