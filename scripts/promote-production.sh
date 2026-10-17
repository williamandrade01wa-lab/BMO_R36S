#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(
  cd "$(dirname "$0")" &&
  pwd
)"

# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

if [ "${1:-}" != "--confirmed" ]; then
  echo "Uso: $0 --confirmed" >&2
  echo
  echo "Use --confirmed somente depois do teste fisico do candidate." >&2
  exit 2
fi

CANDIDATE="$BMO_REPO_ROOT/frontend/index.bmo-next.html"

echo "============================================================"
echo " BMO PROMOTE PRODUCTION"
echo "============================================================"

bmo_log "15%" "Validando repositorio..."
"$SCRIPT_DIR/validate.sh"

bmo_log "30%" "Preflight..."
bmo_preflight

LOCAL_SHA="$(
  sha256sum "$CANDIDATE" |
  awk '{print $1}'
)"

REMOTE_CANDIDATE_SHA="$(
  bmo_ssh \
    "sha256sum /opt/bmo-ui/index.bmo-next.html | awk '{print \$1}'"
)"

[ "$LOCAL_SHA" = "$REMOTE_CANDIDATE_SHA" ] ||
  bmo_die "candidate remoto nao corresponde ao candidate deste checkout"

bmo_log "55%" "Promovendo candidate validado..."

OUTPUT="$(
  bmo_ssh \
    "sudo -n '$BMO_REMOTE_HELPER' promote-production"
)"

printf '%s\n' "$OUTPUT"

BACKUP_ID="$(
  printf '%s\n' "$OUTPUT" |
  sed -n 's/^BACKUP_ID=//p' |
  tail -n1
)"

[ -n "$BACKUP_ID" ] ||
  bmo_die "helper nao retornou BACKUP_ID"

bmo_log "80%" "Verificando producao..."

REMOTE_PRODUCTION_SHA="$(
  bmo_ssh \
    "sha256sum /opt/bmo-ui/index.html | awk '{print \$1}'"
)"

[ "$REMOTE_PRODUCTION_SHA" = "$LOCAL_SHA" ] ||
  bmo_die "producao nao corresponde ao candidate"

bmo_log "100%" "Promocao concluida."

echo
echo "BACKUP_ID=$BACKUP_ID"
echo "PRODUCTION_SHA256=$REMOTE_PRODUCTION_SHA"

echo
echo "============================================================"
echo " BMO_PROMOTE_PRODUCTION_OK"
echo "============================================================"
