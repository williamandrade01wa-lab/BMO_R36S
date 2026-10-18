#!/bin/bash

# BMO R36S hardware baseline capture
# Read-only diagnostic. Does not change system configuration.
# Run with: sudo bash scripts/capture-r36s-baseline.sh

set -u

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="${1:-$PWD/bmo-r36s-baseline-${STAMP}.txt}"

section() {
    printf '\n\n============================================================\n' >> "$OUT"
    printf ' %s\n' "$1" >> "$OUT"
    printf '============================================================\n' >> "$OUT"
}

run() {
    printf '\n$ %s\n' "$*" >> "$OUT"
    "$@" >> "$OUT" 2>&1 || printf '[comando indisponivel ou retornou erro: %s]\n' "$*" >> "$OUT"
}

shell() {
    printf '\n$ %s\n' "$1" >> "$OUT"
    bash -lc "$1" >> "$OUT" 2>&1 || printf '[comando indisponivel ou retornou erro]\n' >> "$OUT"
}

: > "$OUT"
chmod 600 "$OUT" 2>/dev/null || true

cat >> "$OUT" <<'TXT'
BMO R36S HARDWARE BASELINE
LOCAL DIAGNOSTIC - DO NOT COMMIT THIS RAW FILE TO A PUBLIC REPOSITORY

Purpose: capture the working R36S base before building BMO Linux Base.
This script is read-only. Network secrets are not intentionally requested,
but kernel/system logs can still contain device identifiers or local data.
TXT

section "IDENTITY / OS"
run date -Is
run uname -a
run uname -m
run cat /etc/os-release
run hostnamectl
run systemd-detect-virt

section "CPU / MEMORY / STORAGE"
run lscpu
run free -h
run lsblk -o NAME,PATH,SIZE,FSTYPE,FSVER,LABEL,PARTLABEL,UUID,PARTUUID,MOUNTPOINTS
run df -hT
run findmnt

section "BOOT PARTITION / BOOT FILES"
shell 'find /boot -maxdepth 3 -printf "%y %m %u:%g %s %p -> %l\n" 2>/dev/null | sort'
shell 'find /boot -maxdepth 4 -type f \( -name "*.dtb" -o -name "*.dtbo" -o -name "boot.ini" -o -name "extlinux.conf" -o -name "armbianEnv.txt" -o -name "uEnv.txt" -o -name "firstrun_overrides.txt" \) -print 2>/dev/null'

section "BOOT FILE HASHES"
shell 'find /boot -maxdepth 4 -type f \( -name "*.dtb" -o -name "*.dtbo" -o -name "boot.ini" -o -name "extlinux.conf" -o -name "armbianEnv.txt" -o -name "uEnv.txt" \) -print0 2>/dev/null | sort -z | xargs -0 -r sha256sum'

section "SCREENFILES"
shell 'find /boot -maxdepth 4 -type f -path "*/ScreenFiles/*" -printf "%p\n" 2>/dev/null | sort'

section "KERNEL COMMAND LINE / CONFIG"
run cat /proc/cmdline
if [ -r /proc/config.gz ]; then
    shell 'zcat /proc/config.gz | grep -E "^(CONFIG_(USB|INPUT|HID|DRM|SND|SOUND|BACKLIGHT|LEDS|WLAN|CFG80211|MAC80211|RFKILL|ROCKCHIP|PWM|I2C|SPI|MMC|BT|BLUETOOTH).*=|# CONFIG_(USB|INPUT|HID|DRM|SND|SOUND|BACKLIGHT|LEDS|WLAN|CFG80211|MAC80211|RFKILL|ROCKCHIP|PWM|I2C|SPI|MMC|BT|BLUETOOTH).*)"'
else
    shell 'CFG="/boot/config-$(uname -r)"; if [ -r "$CFG" ]; then grep -E "^(CONFIG_(USB|INPUT|HID|DRM|SND|SOUND|BACKLIGHT|LEDS|WLAN|CFG80211|MAC80211|RFKILL|ROCKCHIP|PWM|I2C|SPI|MMC|BT|BLUETOOTH).*=|# CONFIG_(USB|INPUT|HID|DRM|SND|SOUND|BACKLIGHT|LEDS|WLAN|CFG80211|MAC80211|RFKILL|ROCKCHIP|PWM|I2C|SPI|MMC|BT|BLUETOOTH).*)" "$CFG"; else echo "kernel config not found"; fi'
fi

section "LOADED MODULES"
run lsmod

section "DEVICE TREE RUNTIME"
shell 'if [ -r /proc/device-tree/model ]; then tr -d "\0" < /proc/device-tree/model; echo; fi'
shell 'if [ -r /proc/device-tree/compatible ]; then tr "\0" "\n" < /proc/device-tree/compatible; fi'
shell 'find /proc/device-tree -maxdepth 3 -type f \( -name status -o -name compatible \) 2>/dev/null | head -n 300'

section "DRM / DISPLAY"
shell 'for c in /sys/class/drm/card*-*/status; do [ -r "$c" ] && echo "$c: $(cat "$c")"; done'
shell 'for m in /sys/class/drm/card*-*/modes; do [ -r "$m" ] && { echo "--- $m"; cat "$m"; }; done'
shell 'for x in /sys/class/drm/card*; do [ -e "$x" ] && readlink -f "$x/device/driver" 2>/dev/null; done'
run cat /sys/class/graphics/fb0/virtual_size

section "BACKLIGHT / BRIGHTNESS"
shell 'for b in /sys/class/backlight/*; do [ -d "$b" ] || continue; echo "--- $b"; for f in brightness actual_brightness max_brightness type; do [ -r "$b/$f" ] && echo "$f=$(cat "$b/$f")"; done; done'

section "INPUT DEVICES"
run cat /proc/bus/input/devices
shell 'for e in /sys/class/input/event*; do [ -e "$e" ] || continue; echo "--- $e"; [ -r "$e/device/name" ] && echo "name=$(cat "$e/device/name")"; [ -r "$e/device/id/vendor" ] && echo "vendor=$(cat "$e/device/id/vendor")"; [ -r "$e/device/id/product" ] && echo "product=$(cat "$e/device/id/product")"; [ -r "$e/device/id/version" ] && echo "version=$(cat "$e/device/id/version")"; [ -r "$e/device/modalias" ] && echo "modalias=$(cat "$e/device/modalias")"; [ -r "$e/device/capabilities/key" ] && echo "keys=$(cat "$e/device/capabilities/key")"; [ -r "$e/device/capabilities/abs" ] && echo "abs=$(cat "$e/device/capabilities/abs")"; done'
shell 'command -v libinput >/dev/null && libinput list-devices || true'

section "USB / OTG"
run lsusb
run lsusb -t
shell 'printf "usbcore.autosuspend="; cat /sys/module/usbcore/parameters/autosuspend 2>/dev/null || true'
shell 'for d in /sys/bus/usb/devices/*; do [ -d "$d" ] || continue; vid=""; pid=""; prod=""; pwr=""; [ -r "$d/idVendor" ] && vid=$(cat "$d/idVendor"); [ -r "$d/idProduct" ] && pid=$(cat "$d/idProduct"); [ -r "$d/product" ] && prod=$(cat "$d/product"); [ -r "$d/power/control" ] && pwr=$(cat "$d/power/control"); [ -n "$vid$pid$prod" ] && printf "%s vid=%s pid=%s product=%q power=%s\n" "$d" "$vid" "$pid" "$prod" "$pwr"; done'

section "NETWORK HARDWARE (NO PASSWORDS)"
run ip -br link
run rfkill list
run iw dev
shell 'command -v nmcli >/dev/null && nmcli -t -f DEVICE,TYPE,STATE device status || true'
shell 'for n in /sys/class/net/*; do [ -e "$n" ] || continue; echo "--- $(basename "$n")"; readlink -f "$n/device/driver" 2>/dev/null || true; [ -r "$n/device/modalias" ] && cat "$n/device/modalias"; done'

section "AUDIO"
run aplay -l
run aplay -L
run amixer
run cat /proc/asound/cards
run cat /proc/asound/devices

section "POWER / THERMAL / BATTERY"
shell 'for t in /sys/class/thermal/thermal_zone*; do [ -d "$t" ] || continue; printf "%s type=" "$t"; cat "$t/type" 2>/dev/null; printf " temp="; cat "$t/temp" 2>/dev/null; done'
shell 'for p in /sys/class/power_supply/*; do [ -d "$p" ] || continue; echo "--- $p"; for f in type status capacity voltage_now current_now; do [ -r "$p/$f" ] && echo "$f=$(cat "$p/$f")"; done; done'

section "SYSTEMD TARGETS / SERVICES"
run systemctl get-default
run systemctl list-unit-files --state=enabled
run systemctl --failed
run systemctl list-dependencies --plain multi-user.target
run systemctl list-dependencies --plain graphical.target

section "DISPLAY MANAGER / DESKTOP"
shell 'systemctl status display-manager --no-pager 2>&1 || true'
shell 'dpkg-query -W 2>/dev/null | grep -Ei "xfce|lightdm|xorg|chromium|wayland|weston|mesa|panfrost|mali" || true'

section "IMPORTANT PACKAGES"
shell 'dpkg-query -W 2>/dev/null | grep -Ei "^(linux-|armbian|u-boot|firmware|network-manager|netplan|openssh|git|sudo|python3|alsa|bluez|evtest|joystick|libinput|xserver|xorg|mesa|chromium|retroarch|ppsspp|moonlight)" || true'

section "UDEV RULES RELATED TO INPUT / USB / POWER"
shell 'grep -RniE "usb|input|gamepad|joystick|backlight|brightness|power/control|0a05|7211|0bda|0179" /etc/udev/rules.d /usr/lib/udev/rules.d 2>/dev/null | head -n 500 || true'

section "KERNEL LOG - HARDWARE RELEVANT"
shell 'dmesg 2>/dev/null | grep -Ei "usb|dwc|otg|input|gamepad|joystick|hid|drm|dsi|panel|display|gpu|panfrost|mali|snd|audio|codec|backlight|pwm|mmc|sdhci|wifi|wlan|rtl|rfkill" | tail -n 1000 || true'

section "BMO KNOWN PATHS IF PRESENT"
shell 'for p in /etc/bmo /opt/bmo-ui /usr/local/bin/bmo /usr/local/sbin/bmo-maintenance /etc/udev/rules.d/99-bmo-usb-power.rules; do if [ -e "$p" ]; then echo "--- $p"; ls -ld "$p"; [ -f "$p" ] && sha256sum "$p"; fi; done'

section "SUMMARY"
cat >> "$OUT" <<'TXT'
BASELINE_CAPTURE_COMPLETE

Next step:
1. Keep this raw report local.
2. Send/upload it for analysis.
3. We will extract a public-safe hardware manifest from it.
4. Button-to-code mapping is captured separately with an interactive test.
TXT

printf '\nBMO_BASELINE_CAPTURE_OK\n'
printf 'Arquivo: %s\n' "$OUT"
printf 'Nao versione o relatorio bruto no Git publico.\n'
