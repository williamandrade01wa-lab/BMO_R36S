#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
BASE="$(realpath -e "$1")";WORK="$2";OUT="$3";LOOP="";ROOT=""
[ "$EUID" -eq 0 ] && [ "$(uname -m)" = aarch64 ]
[ ! -e "$WORK" ];mkdir -p "$WORK" "$OUT";WORK="$(realpath -e "$WORK")";OUT="$(realpath -e "$OUT")"
echo "33e250518619c9cfecc2a846fa9a68e4bc213a5f1731d93cd07cffcaa61e9996  $BASE" | sha256sum -c -
cleanup(){ if [ -n "$ROOT" ] && mountpoint -q "$ROOT";then umount -R "$ROOT";fi;[ -z "$LOOP" ] || losetup -d "$LOOP"; }
trap cleanup EXIT
IMAGE="$WORK/BMO-R36S-Light-v0.1.0-core.img"
cp --reflink=auto --sparse=always "$BASE" "$IMAGE"
LOOP="$(losetup --find --show --partscan "$IMAGE")";udevadm settle
ROOT="$WORK/root";mkdir "$ROOT";mount "$LOOP"p2 "$ROOT"
mount "$LOOP"p1 "$ROOT/boot/u-boot"
touch "$ROOT/.bmo-ready-build-root"
rm -f "$ROOT/root/.not_logged_in_yet"
install -m 0755 "$REPO/image/armbian/userpatches/overlay/usr/local/sbin/bmo-firstboot" "$ROOT/usr/local/sbin/bmo-firstboot"
mount --rbind /dev "$ROOT/dev";mount --make-rslave "$ROOT/dev"
mount -t proc proc "$ROOT/proc";mount --rbind /sys "$ROOT/sys";mount --make-rslave "$ROOT/sys"
mount -t tmpfs -o mode=0755 tmpfs "$ROOT/run"
cp -a --no-dereference "$ROOT/etc/resolv.conf" "$WORK/resolv.original"
rm -f "$ROOT/etc/resolv.conf";cp -L /etc/resolv.conf "$ROOT/etc/resolv.conf"
[ ! -e "$ROOT/usr/sbin/policy-rc.d" ] || cp -a "$ROOT/usr/sbin/policy-rc.d" "$WORK/policy.original"
printf '#!/bin/sh\nexit 101\n' > "$ROOT/usr/sbin/policy-rc.d";chmod 755 "$ROOT/usr/sbin/policy-rc.d"
printf 'APT::Install-Recommends "false";\nAPT::Install-Suggests "false";\n' > "$ROOT/etc/apt/apt.conf.d/91-bmo-light"
mapfile -t CANDIDATES < <(grep -Ev '^[[:space:]]*(#|$)' "$REPO/install/light/prune-candidates.txt")
REMOVE=()
for pkg in "${CANDIDATES[@]}";do
    if chroot "$ROOT" dpkg-query -W -f='${db:Status-Abbrev}' "$pkg" 2>/dev/null | grep -q '^ii ';then REMOVE+=("$pkg");fi
done
if [ "${#REMOVE[@]}" -gt 0 ];then
    chroot "$ROOT" apt-get -s -o APT::Get::AutomaticRemove=false purge "${REMOVE[@]}" | tee "$OUT/prune-plan.txt"
    while read -r pkg;do
        printf '%s\n' "${CANDIDATES[@]}" | grep -Fxq "$pkg" || { echo "Unexpected removal: $pkg" >&2;exit 1; }
    done < <(awk '/^(Remv|Purg) / {print $2}' "$OUT/prune-plan.txt")
    chroot "$ROOT" /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o APT::Get::AutomaticRemove=false purge "${REMOVE[@]}"
fi
SOURCE="$ROOT/usr/share/bmo/light/source";mkdir -p "$SOURCE"
for item in backend frontend launchers configs system systemd deploy/r36s scripts/runtime install/manifests install/packages install/phases install/beta install/light install/bmo-install.sh;do
    mkdir -p "$SOURCE/$(dirname "$item")";cp -a "$REPO/$item" "$SOURCE/$item"
done
# Payload contains source/config only, never .git, runtime archives or credentials.
for item in CREDITS.md THIRD_PARTY.md LICENSE;do [ ! -f "$REPO/$item" ] || cp "$REPO/$item" "$SOURCE/$item";done
(cd "$SOURCE" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)
install -m 0755 "$REPO/install/light/bmo-light-install" "$ROOT/usr/local/sbin/bmo-light-install"
install -m 0644 "$REPO/install/light/bmo-light-install.service" "$ROOT/etc/systemd/system/"
install -m 0644 "$REPO/install/beta/bmo-ready-firstboot.service" "$ROOT/etc/systemd/system/"
install -m 0755 "$REPO/install/light/firstboot-finish" "$ROOT/usr/local/sbin/bmo-ready-firstboot-finish"
mkdir -p "$ROOT/usr/local/libexec"
install -m 0755 "$REPO/image/armbian/userpatches/overlay/usr/local/bin/bmo" "$ROOT/usr/local/libexec/bmo-base"
install -m 0755 "$REPO/install/light/bmo-light-cli" "$ROOT/usr/local/bin/bmo"
install -m 0644 "$REPO/image/armbian/userpatches/overlay/etc/profile.d/90-bmo-welcome.sh" "$ROOT/etc/profile.d/"
for file in BMO-FIRSTBOOT.txt README-FIRST-BOOT.txt;do
    cp "$REPO/image/armbian/userpatches/overlay/usr/share/bmo/$file" "$ROOT/boot/u-boot/$file"
    cp "$REPO/image/armbian/userpatches/overlay/usr/share/bmo/$file" "$ROOT/usr/share/bmo/$file"
done
cp "$REPO/scripts/windows/ABRIR-BMO.cmd" "$REPO/scripts/windows/BMO-Preparar-Cartao.ps1" "$REPO/scripts/windows/LEIA-ME.txt" "$ROOT/boot/u-boot/"
cp "$REPO/install/light/README-LIGHT.txt" "$ROOT/boot/u-boot/"
install -d "$ROOT/etc/bmo"
printf 'BMO_LIGHT_VERSION=0.1.0\nBMO_LIGHT_SOURCE=%s\n' "$(git -c safe.directory="$REPO" -C "$REPO" rev-parse HEAD)" > "$ROOT/etc/bmo/light-image.env"
rm -f "$ROOT/etc/systemd/system/getty@.service.d/override.conf" "$ROOT/etc/systemd/system/serial-getty@.service.d/override.conf"
systemctl --root="$ROOT" enable bmo-ready-firstboot.service bmo-light-install.service
systemctl --root="$ROOT" enable armbian-resize-filesystem.service
systemd-analyze --root="$ROOT" verify bmo-ready-firstboot.service bmo-light-install.service
bash "$REPO/install/light/bmo-light-install" --verify "$ROOT" --allow-missing-runtime
chroot "$ROOT" dpkg-query -W -f='${Package}\t${Version}\t${Installed-Size}\n' > "$OUT/light-core-packages.tsv"
for pkg in chromium retroarch moonlight-qt;do
    if chroot "$ROOT" dpkg-query -W -f='${db:Status-Abbrev}' "$pkg" 2>/dev/null | grep -q '^ii ';then echo "Not light: $pkg";exit 1;fi
done
[ -x "$ROOT/usr/bin/nmcli" ] && [ -x "$ROOT/usr/bin/python3" ]
chroot "$ROOT" apt-get clean
rm -rf "$ROOT/var/lib/apt/lists/"*
rm -f "$ROOT/usr/sbin/policy-rc.d";[ ! -e "$WORK/policy.original" ] || cp -a "$WORK/policy.original" "$ROOT/usr/sbin/policy-rc.d"
rm -f "$ROOT/etc/resolv.conf";cp -a --no-dereference "$WORK/resolv.original" "$ROOT/etc/resolv.conf"
bash "$REPO/install/phases/70-sanitize.sh" --root "$ROOT"
rm -rf "$ROOT/var/lib/bmo"
rm -f "$ROOT/boot/u-boot/BMO-IP.txt" "$ROOT/boot/u-boot/BMO-STATUS.txt" "$ROOT/boot/u-boot/BMO-RESUMO.txt" "$ROOT/.bmo-ready-build-root"
sync;cleanup;ROOT="";LOOP=""
bash "$REPO/install/light/minimize-image.sh" "$IMAGE" 128
gzip -1 -c "$IMAGE" > "$OUT/$(basename "$IMAGE").gz"
gzip -t "$OUT/$(basename "$IMAGE").gz"
(cd "$OUT" && sha256sum "$(basename "$IMAGE").gz" > "$(basename "$IMAGE").gz.sha256")
echo BMO_LIGHT_CORE_OK_RUNTIME_INJECTION_PENDING
