#!/bin/sh
# Status de boot sem SSID, senha ou chave. Instalado apenas na candidata Wi-Fi 5.
set -u
BOOT=/boot/u-boot
[ -d "$BOOT" ] || BOOT=/boot
OUT="$BOOT/BMO-WIFI5-STATUS.txt"
if [ "$(findmnt -n -o FSTYPE --target "$BOOT" 2>/dev/null)" != vfat ]; then
  mount "$BOOT" 2>/dev/null || true
fi
if [ "$(findmnt -n -o FSTYPE --target "$BOOT" 2>/dev/null)" != vfat ]; then
  OUT=/var/log/bmo-wifi5-status.txt
fi
TMP="$OUT.tmp"
{
  echo 'BMO READY WIFI5 BETA - STATUS'
  date -u '+DEVICE_UTC=%Y-%m-%dT%H:%M:%SZ'
  printf 'KERNEL='; uname -r
  echo '=== USB MODULE ==='
  FOUND=no
  for d in /sys/bus/usb/devices/*; do
    [ -f "$d/idVendor" ] || continue
    if [ "$(cat "$d/idVendor")" = 0bda ] && [ "$(cat "$d/idProduct")" = c811 ]; then FOUND=yes; fi
  done
  echo "RTL8811CU_USB=$FOUND"
  printf 'DRIVER_MODULE='; modinfo -F filename rtw88_8821cu 2>&1 || true
  echo '=== NETWORK ==='
  if command -v rfkill >/dev/null 2>&1; then rfkill list 2>&1 || true; fi
  if command -v iw >/dev/null 2>&1; then
    iw reg get 2>&1 | head -n 12 || true
    iw dev 2>&1 | grep -E 'Interface|type' || true
    if iw phy 2>/dev/null | grep -E '\*[[:space:]]*5[0-9]{3}[[:space:]]*MHz' | grep -v 'disabled' >/dev/null; then
      echo 'FIVE_GHZ_CHANNELS=available'
    else
      echo 'FIVE_GHZ_CHANNELS=not_seen'
    fi
    WLAN=$(iw dev 2>/dev/null | awk '$1=="Interface" {print $2; exit}')
    if [ -n "$WLAN" ]; then
      iw dev "$WLAN" link 2>/dev/null | grep -E 'freq:|signal:' || true
    fi
  else
    echo 'IW=unavailable'
  fi
  if command -v nmcli >/dev/null 2>&1; then
    nmcli -t -f DEVICE,TYPE,STATE device status 2>&1 || true
  fi
  ip -4 -o addr show scope global 2>&1 | awk '{print "IP4=" $4}' || true
  echo '=== SSH ==='
  printf 'SSH_ACTIVE='; systemctl is-active ssh 2>&1 || true
  printf 'SSH_ENABLED='; systemctl is-enabled ssh 2>&1 || true
  if [ -x /usr/sbin/sshd ]; then /usr/sbin/sshd -t 2>&1; echo "SSHD_CONFIG_EXIT=$?"; fi
  echo '=== DRIVER EVENTS ==='
  dmesg 2>&1 | grep -Ei '0bda|c811|rtw88|8821|firmware.*(fail|error)' | tail -n 40 || true
  echo '=== END ==='
} > "$TMP" 2>&1
mv -f "$TMP" "$OUT"
exit 0
