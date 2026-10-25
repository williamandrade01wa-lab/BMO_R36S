#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
TMP="$(mktemp -d)";LOOP="";MNT="$TMP/mnt"
cleanup(){ mountpoint -q "$MNT" && umount "$MNT" || true;[ -z "$LOOP" ] || losetup -d "$LOOP";rm -rf -- "$TMP"; }
trap cleanup EXIT
ROOT="$TMP/root";mkdir -p "$ROOT/etc/bmo" "$ROOT/usr/share/bmo/light/source"
touch "$ROOT/etc/bmo/light-image.env"
printf 'fixture\n' > "$ROOT/usr/share/bmo/light/source/file"
(cd "$ROOT/usr/share/bmo/light/source" && sha256sum file > SHA256SUMS)
bash "$REPO/install/light/bmo-light-install" --verify "$ROOT" --allow-missing-runtime
if bash "$REPO/install/light/bmo-light-install" --verify "$ROOT";then echo 'missing runtime accepted';exit 1;fi
echo corrupt >> "$ROOT/usr/share/bmo/light/source/file"
if bash "$REPO/install/light/bmo-light-install" --verify "$ROOT" --allow-missing-runtime;then echo 'corrupt payload accepted';exit 1;fi
IMAGE="$TMP/test.img";truncate -s 512M "$IMAGE"
printf 'label: dos\nunit: sectors\n\nstart=32768,size=131072,type=c\nstart=163840,type=83\n' | sfdisk "$IMAGE"
LOOP="$(losetup --find --show --partscan "$IMAGE")";udevadm settle
mkfs.vfat -F 32 "$LOOP"p1
mkfs.ext4 -q -F -b 4096 "$LOOP"p2
UUID="$(blkid -s UUID -o value "$LOOP"p2)"
mkdir "$MNT";mount "$LOOP"p2 "$MNT"
mkdir "$MNT/etc";printf 'preserve-me\n' > "$MNT/etc/fixture"
umount "$MNT";losetup -d "$LOOP";LOOP=""
BEFORE="$(stat -c %s "$IMAGE")"
bash "$REPO/install/light/minimize-image.sh" "$IMAGE" 16
[ "$(stat -c %s "$IMAGE")" -lt "$BEFORE" ]
LOOP="$(losetup --find --show --partscan "$IMAGE")";udevadm settle
[ "$(blkid -s UUID -o value "$LOOP"p2)" = "$UUID" ]
e2fsck -fn "$LOOP"p2
mount -o ro "$LOOP"p2 "$MNT"
grep -Fxq preserve-me "$MNT/etc/fixture"
umount "$MNT";losetup -d "$LOOP";LOOP=""
echo BMO_LIGHT_SAFETY_AND_SHRINK_TESTS_OK
