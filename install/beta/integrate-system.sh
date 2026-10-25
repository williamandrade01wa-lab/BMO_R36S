#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"
ROOT=""
while [ "$#" -gt 0 ]; do case "$1" in --root) ROOT="$2";shift 2;; *) echo "unknown argument" >&2;exit 1;; esac; done
[ "$EUID" -eq 0 ] && [ -n "$ROOT" ] || exit 1
ROOT="$(realpath -e "$ROOT")"
[ "$ROOT" != / ] && [ -f "$ROOT/.bmo-ready-build-root" ] || { echo 'invalid beta target' >&2;exit 1; }
FSTAB_BEFORE="$(sha256sum "$ROOT/etc/fstab" | cut -d' ' -f1)"
STAGE="$(mktemp -d)"
trap 'rm -rf -- "$STAGE"' EXIT
touch "$STAGE/.bmo-ready-sandbox"
bash "$REPO/install/phases/40-system-config.sh" --root "$STAGE"
cp -a "$STAGE/etc/." "$ROOT/etc/"
cp -a "$STAGE/usr/." "$ROOT/usr/"
bash "$REPO/install/phases/50-services.sh" --root "$ROOT"
install -D -m 0644 "$SCRIPT_DIR/bmo-ready-firstboot.service" "$ROOT/etc/systemd/system/bmo-ready-firstboot.service"
install -D -m 0755 "$SCRIPT_DIR/bmo-ready-firstboot-finish" "$ROOT/usr/local/sbin/bmo-ready-firstboot-finish"
install -D -m 0755 "$SCRIPT_DIR/bmo-sd2-auto" "$ROOT/usr/local/sbin/bmo-sd2-auto"
install -D -m 0644 "$SCRIPT_DIR/bmo-sd2-auto.service" "$ROOT/etc/systemd/system/bmo-sd2-auto.service"
while IFS= read -r unit; do
    [[ -z "$unit" || "$unit" == \#* ]] && continue
    install -d "$ROOT/etc/systemd/system/$unit.d"
    cat > "$ROOT/etc/systemd/system/$unit.d/10-ready-firstboot.conf" <<'UNIT'
[Unit]
After=bmo-ready-firstboot.service
Requires=bmo-ready-firstboot.service
UNIT
done < "$REPO/install/manifests/enabled-services.txt"
# User manager supplies /run/user/1000 and the PulseAudio socket used by launchers.
install -d "$ROOT/var/lib/systemd/linger"
touch "$ROOT/var/lib/systemd/linger/r36s"
cat > "$ROOT/etc/systemd/system/bmo-kiosk.service.d/20-audio.conf" <<'UNIT'
[Unit]
After=user@1000.service bmo-sd2-auto.service
Wants=user@1000.service bmo-sd2-auto.service
[Service]
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=PULSE_SERVER=unix:/run/user/1000/pulse/native
UNIT
systemctl --root="$ROOT" --global enable pulseaudio.socket
systemctl --root="$ROOT" enable bmo-ready-firstboot.service bmo-sd2-auto.service
# The dedicated service replaces interactive Armbian firstlogin on this beta.
rm -f "$ROOT/root/.not_logged_in_yet" "$ROOT/etc/systemd/system/getty@.service.d/override.conf" "$ROOT/etc/systemd/system/serial-getty@.service.d/override.conf"
[ "$(sha256sum "$ROOT/etc/fstab" | cut -d' ' -f1)" = "$FSTAB_BEFORE" ]
echo BMO_BETA_SYSTEM_INTEGRATION_OK
