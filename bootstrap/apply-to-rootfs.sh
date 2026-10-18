#!/usr/bin/env bash

# Injeta o preset BMO em uma BMO Linux Pure / Armbian ja montada.
# Uso:
#   sudo ./bootstrap/apply-to-rootfs.sh /mnt/bmo-rootfs
# ou:
#   sudo ./bootstrap/apply-to-rootfs.sh /mnt/bmo-rootfs /caminho/firstboot.local.conf

set -euo pipefail

ROOTFS="${1:-}"
CONFIG="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/firstboot.local.conf}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROVISIONING="$SCRIPT_DIR/provisioning.sh"

fail() {
    echo "ERRO: $*" >&2
    exit 1
}

[ "$EUID" -eq 0 ] || fail "execute com sudo/root"
[ -n "$ROOTFS" ] || fail "informe o ponto de montagem da rootfs"
[ -d "$ROOTFS" ] || fail "rootfs inexistente: $ROOTFS"

ROOTFS="$(readlink -f "$ROOTFS")"
[ "$ROOTFS" != "/" ] || fail "recusando modificar o sistema host"

[ -r "$ROOTFS/etc/os-release" ] || fail "nao parece uma rootfs Linux/Armbian"
[ -d "$ROOTFS/root" ] || fail "diretorio root ausente na rootfs"
[ -f "$CONFIG" ] || fail "config local ausente: $CONFIG"
[ -f "$PROVISIONING" ] || fail "provisioning ausente: $PROVISIONING"

# Ignora placeholders que estejam apenas em linhas comentadas
# (por exemplo, os campos de IP estatico quando DHCP esta ativo).
if grep -Ev '^[[:space:]]*(#|$)' "$CONFIG" |
    grep -q 'CHANGE_ME_'
then
    fail "preencha todos os CHANGE_ME_ ativos antes de aplicar"
fi

# O destino sempre sera privado, independentemente do modo local.
MODE="$(stat -c '%a' "$CONFIG")"
case "$MODE" in
    600|640|644) ;;
    *)
        echo "AVISO: modo atual do preset=$MODE; copiando destino como 0600"
        ;;
esac

install \
    -o root \
    -g root \
    -m 0600 \
    "$CONFIG" \
    "$ROOTFS/root/.not_logged_in_yet"

install \
    -o root \
    -g root \
    -m 0700 \
    "$PROVISIONING" \
    "$ROOTFS/root/provisioning.sh"

sync

cat <<EOF
============================================================
 BMO FIRSTBOOT PRESET APPLIED
============================================================
ROOTFS=$ROOTFS
CONFIG=/root/.not_logged_in_yet
PROVISIONING=/root/provisioning.sh
SECRETS_COMMITTED=NO
============================================================
EOF
