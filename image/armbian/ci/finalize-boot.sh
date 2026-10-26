#!/usr/bin/env bash
# Populate the final FAT partition after upstream bootloader/image hooks.
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCES="$SCRIPT_DIR/../userpatches/overlay/usr/share/bmo"
IMAGE="${1:?usage: finalize-boot.sh IMAGE}"
BOOT_LOGO="$SCRIPT_DIR/../../../assets/boot/logo.bmp"
(cd "$(dirname "$BOOT_LOGO")" && sha256sum -c logo.bmp.sha256)
LOOP=""
BOOT_MOUNT=""
cleanup() {
    if [[ -n "$BOOT_MOUNT" ]]; then
        if mountpoint -q "$BOOT_MOUNT"; then umount "$BOOT_MOUNT" || return 1; fi
        rmdir "$BOOT_MOUNT"
    fi
    if [[ -n "$LOOP" ]]; then losetup -d "$LOOP"; fi
}
trap cleanup EXIT
[[ "$EUID" -eq 0 ]] || { echo 'ERROR: root required' >&2; exit 1; }
[[ -f "$IMAGE" && -s "$IMAGE" ]] || { echo 'ERROR: expected nonempty image file' >&2; exit 1; }
for name in BMO-FIRSTBOOT.txt README-FIRST-BOOT.txt; do
    [[ -s "$SOURCES/$name" ]] || { echo "ERROR: missing source: $name" >&2; exit 1; }
done
LOOP="$(losetup --find --show --partscan "$IMAGE")"
udevadm settle
mapfile -t BOOT_PARTS < <(lsblk -lnpo NAME,FSTYPE "$LOOP" | awk '$2 == "vfat" {print $1}')
[[ "${#BOOT_PARTS[@]}" -eq 1 ]] || { echo 'ERROR: expected exactly one FAT boot partition' >&2; exit 1; }
BOOT_MOUNT="$(mktemp -d)"
mount -o rw,nosuid,nodev,noexec "${BOOT_PARTS[0]}" "$BOOT_MOUNT"
for name in BMO-FIRSTBOOT.txt README-FIRST-BOOT.txt; do
    cp -- "$SOURCES/$name" "$BOOT_MOUNT/$name"
    cmp -- "$SOURCES/$name" "$BOOT_MOUNT/$name"
    echo "OK: final BOOT/$name matches versioned source"
done
cp -- "$BOOT_LOGO" "$BOOT_MOUNT/logo.bmp"
cmp -- "$BOOT_LOGO" "$BOOT_MOUNT/logo.bmp"
echo "OK: final BOOT/logo.bmp matches versioned art"
sync -f "$BOOT_MOUNT"
echo BMO_FINAL_BOOT_OK