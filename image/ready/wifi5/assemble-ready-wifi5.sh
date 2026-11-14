#!/bin/bash
set -euo pipefail
BASE=${1:?Usage: assemble-ready-wifi5.sh WORK_DIR_WITH_Ready-base.img_AND_modules}
ASSETS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
IMG="$BASE/Ready-base.img"
ROOT=/mnt/bmo-ready-wifi5-root
BOOT=/mnt/bmo-ready-wifi5-boot
K=6.12.32-lts-rk3326
test "$(stat -c %s "$IMG")" = 12884901888
for n in rtw88_usb rtw88_8821c rtw88_8821cu; do
  test -s "$BASE/modules/$n.ko"
  test "$(modinfo -F vermagic "$BASE/modules/$n.ko" | awk '{print $1}')" = "$K"
done
modinfo -F alias "$BASE/modules/rtw88_8821cu.ko" | grep -qi 'v0BDApC811'
mkdir -p "$ROOT" "$BOOT"
mounted_root=0
mounted_boot=0
cleanup() {
  sync
  if [ "$mounted_boot" -eq 1 ]; then umount "$BOOT"; fi
  if [ "$mounted_root" -eq 1 ]; then umount "$ROOT"; fi
}
trap cleanup EXIT
mount -o rw,loop,offset=$((557056*512)),sizelimit=$((24608768*512)) "$IMG" "$ROOT"
mounted_root=1
mount -o rw,loop,offset=$((32768*512)),sizelimit=$((524288*512)) "$IMG" "$BOOT"
mounted_boot=1
test -f "$ROOT/opt/bmo-ui/index.html"
test -f "$ROOT/usr/local/sbin/bmo-firstboot"
test -d "$ROOT/lib/modules/$K"
test -f "$ROOT/lib/firmware/rtw88/rtw8821c_fw.bin"
DEST="$ROOT/lib/modules/$K/kernel/drivers/net/wireless/realtek/rtw88"
for n in rtw88_usb rtw88_8821c rtw88_8821cu; do
  install -m 0644 "$BASE/modules/$n.ko" "$DEST/$n.ko"
done
depmod -b "$ROOT" "$K"
modprobe -d "$ROOT" -S "$K" -n -v rtw88_8821cu > "$BASE/modprobe-dry-run.txt"
grep -q rtw88_8821cu "$BASE/modprobe-dry-run.txt"
install -m 0755 "$ASSETS/bmo-wifi5-report.sh" "$ROOT/usr/local/sbin/bmo-wifi5-report"
install -m 0644 "$ASSETS/bmo-wifi5-report.service" "$ROOT/etc/systemd/system/bmo-wifi5-report.service"
ln -s ../bmo-wifi5-report.service "$ROOT/etc/systemd/system/multi-user.target.wants/bmo-wifi5-report.service"
cat > "$BOOT/BMO-WIFI5-BETA.txt" <<'EOF'
BMO Ready v1.0.0-beta.2 WiFi5 - candidata privada

Base: Ready v1.0.0-beta.1, BMO completo ja instalado.
Driver interno: RTL8811CU / USB 0bda:c811.

Para testar:
1. Grave esta imagem em outro cartao de 16 GB ou maior. Preserve o cartao atual.
2. Abra a BOOT e execute ABRIR-BMO.cmd; selecione o painel correto.
3. Configure sua rede Wi-Fi de 5 GHz, senha do usuario nova e ACESSO_REMOTO=sim.
4. Ligue com TF2 fora. Aguarde o primeiro boot e eventual reinicio de expansao.
5. Depois de desligar, leia BMO-WIFI5-STATUS.txt na BOOT.

O status mostra USB, driver, canais de 5 GHz, frequencia da conexao,
IP e estado do SSH. Nao coloque senhas neste arquivo de status.
EOF
cat > "$ROOT/etc/bmo-wifi5-candidate" <<'EOF'
BMO_READY_CANDIDATE=1.0.0-beta.2-wifi5
BASE=1.0.0-beta.1
KERNEL=6.12.32-lts-rk3326
USB_ID=0bda:c811
EOF
for n in rtw88_usb rtw88_8821c rtw88_8821cu; do
  test -s "$DEST/$n.ko"
done
test -L "$ROOT/etc/systemd/system/multi-user.target.wants/bmo-wifi5-report.service"
echo BMO_READY_WIFI5_IMAGE_PATCH_OK
