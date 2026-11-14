#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd -- "$(dirname -- "$0")/../../.." && pwd)"
[ "$EUID" -eq 0 ] || { echo 'Run as root for offline integration fixture';exit 1; }
T="$(mktemp -d)"
trap 'rm -rf -- "$T"' EXIT
mkdir -p "$T/etc/systemd/system/multi-user.target.wants" "$T/usr/lib/systemd/user" "$T/usr/local/sbin"
touch "$T/.bmo-ready-build-root" "$T/.bmo-ready-sandbox"
echo PRESERVE_FSTAB > "$T/etc/fstab"
echo PRESERVE_EXISTING > "$T/etc/systemd/system/existing.service"
ln -s ../existing.service "$T/etc/systemd/system/multi-user.target.wants/existing.service"
cat > "$T/usr/lib/systemd/user/pulseaudio.socket" <<'UNIT'
[Socket]
ListenStream=%t/pulse/native
[Install]
WantedBy=sockets.target
UNIT
bash "$REPO/install/beta/integrate-system.sh" --root "$T"
grep -qx PRESERVE_FSTAB "$T/etc/fstab"
test -L "$T/etc/systemd/system/multi-user.target.wants/existing.service"
test -L "$T/etc/systemd/system/multi-user.target.wants/bmo-kiosk.service"
test -L "$T/etc/systemd/system/multi-user.target.wants/bmo-ready-firstboot.service"
test -f "$T/etc/systemd/system/bmo-kiosk.service.d/10-ready-firstboot.conf"
test -f "$T/etc/systemd/system/bmo-kiosk.service.d/20-audio.conf"
test -f "$T/var/lib/systemd/linger/r36s"
test -x "$T/usr/local/sbin/bmo-sd2-auto"
echo BMO_BETA_INTEGRATION_FIXTURE_OK
