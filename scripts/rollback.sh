#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(
  cd "$(dirname "$0")" &&
  pwd
)"

# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  echo "Uso:"
  echo "  $0 --list"
  echo "  $0 <backup-id> --confirmed"
}

echo "============================================================"
echo " BMO ROLLBACK"
echo "============================================================"

bmo_preflight

if [ "${1:-}" = "--list" ]; then
  bmo_ssh \
    "sudo -n '$BMO_REMOTE_HELPER' list-backups"
  exit 0
fi

BACKUP_ID="${1:-}"
CONFIRM="${2:-}"

[[ "$BACKUP_ID" =~ ^[0-9]{8}-[0-9]{6}$ ]] || {
  usage >&2
  exit 2
}

[ "$CONFIRM" = "--confirmed" ] || {
  usage >&2
  echo >&2
  echo "Rollback exige confirmacao explicita." >&2
  exit 2
}

bmo_log "25%" "Estado antes do rollback..."
bmo_ssh \
  "sudo -n '$BMO_REMOTE_HELPER' status"

bmo_log "50%" "Restaurando frontend do backup $BACKUP_ID..."

bmo_ssh \
  "sudo -n '$BMO_REMOTE_HELPER' rollback-frontend '$BACKUP_ID'"

bmo_log "75%" "Reiniciando somente kiosk..."

bmo_ssh \
  "sudo -n '$BMO_REMOTE_HELPER' restart-kiosk"

bmo_log "90%" "Health checks..."

bmo_ssh \
  "python3 -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:8090/index.bmo-next.html', timeout=3).read(1)\""

bmo_ssh \
  "python3 -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:8088/health', timeout=3).read(1)\""

bmo_log "100%" "Rollback concluido."

echo
echo "============================================================"
echo " BMO_ROLLBACK_OK"
echo " BACKUP_ID=$BACKUP_ID"
echo "============================================================"
