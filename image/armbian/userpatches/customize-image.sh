#!/usr/bin/env bash
set -euo pipefail
RELEASE="$1"; LINUXFAMILY="$2"; BOARD="$3"; BUILD_DESKTOP="$4"; ARCH="${5:-}"
[ "$BOARD" = "r36s" ] || exit 0
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates git sudo openssh-client openssh-server network-manager netplan.io wpasupplicant wireless-regdb iw rfkill iproute2 python3 locales avahi-daemon alsa-utils
install -d -m 0755 /usr/share/bmo /usr/local/bin /usr/local/sbin /etc/bmo /etc/NetworkManager/conf.d /etc/netplan /etc/udev/rules.d
install -m 0755 /tmp/overlay/usr/local/bin/bmo /usr/local/bin/bmo
install -m 0755 /tmp/overlay/usr/local/sbin/bmo-firstboot /usr/local/sbin/bmo-firstboot
install -m 0644 /tmp/overlay/usr/share/bmo/BMO-FIRSTBOOT.txt /usr/share/bmo/BMO-FIRSTBOOT.txt
install -m 0644 /tmp/overlay/usr/share/bmo/README-FIRST-BOOT.txt /usr/share/bmo/README-FIRST-BOOT.txt
install -m 0644 /tmp/overlay/etc/bmo/source.conf /etc/bmo/source.conf
install -m 0644 /tmp/overlay/etc/bmo/base-version.env /etc/bmo/base-version.env
install -m 0644 /tmp/overlay/etc/NetworkManager/conf.d/20-bmo.conf /etc/NetworkManager/conf.d/20-bmo.conf
install -m 0600 /tmp/overlay/etc/netplan/90-bmo-networkmanager.yaml /etc/netplan/90-bmo-networkmanager.yaml
install -m 0644 /tmp/overlay/etc/udev/rules.d/99-bmo-usb-power.rules /etc/udev/rules.d/99-bmo-usb-power.rules
install -d -m 0755 /etc/profile.d
install -m 0644 /tmp/overlay/etc/profile.d/90-bmo-welcome.sh /etc/profile.d/90-bmo-welcome.sh
systemctl disable systemd-networkd.service systemd-networkd-wait-online.service 2>/dev/null || true
systemctl enable NetworkManager.service
systemctl disable ssh.service 2>/dev/null || true
systemctl disable avahi-daemon.service 2>/dev/null || true
rm -f /etc/ssh/ssh_host_* || true
rm -f /etc/netplan/30-wifis-dhcp.yaml
netplan generate || true
if [ -d /boot/u-boot ]; then
    install -m 0644 /usr/share/bmo/BMO-FIRSTBOOT.txt /boot/u-boot/BMO-FIRSTBOOT.txt
    install -m 0644 /usr/share/bmo/README-FIRST-BOOT.txt /boot/u-boot/README-FIRST-BOOT.txt
fi
python3 -m py_compile /usr/local/sbin/bmo-firstboot
bash -n /usr/local/bin/bmo
echo "BMO_LINUX_BASE_V02_CUSTOMIZE_OK"
