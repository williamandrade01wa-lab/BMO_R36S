#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(
  cd "$(dirname "$0")" &&
  pwd
)"

# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

CANDIDATE="$BMO_REPO_ROOT/frontend/index.bmo-next.html"

echo "============================================================"
echo " BMO DEPLOY CANDIDATE"
echo "============================================================"

bmo_log "10%" "Validando repositorio..."
"$SCRIPT_DIR/validate.sh"

bmo_log "25%" "Preflight SSH/helper..."
bmo_preflight

bmo_log "40%" "Preparando upload..."

LOCAL_SHA="$(
  sha256sum "$CANDIDATE" |
  awk '{print $1}'
)"

STAMP="$(date +%Y%m%d-%H%M%S)"
REMOTE_FILE="$BMO_REMOTE_INCOMING/index.bmo-next.${STAMP}.${LOCAL_SHA:0:12}.html"

cleanup() {
  bmo_ssh "rm -f '$REMOTE_FILE'" >/dev/null 2>&1 || true
}
trap cleanup EXIT

bmo_scp \
  "$CANDIDATE" \
  "$BMO_REMOTE:$REMOTE_FILE"

bmo_log "55%" "Validando SHA256 remoto..."

REMOTE_SHA="$(
  bmo_ssh "sha256sum '$REMOTE_FILE' | awk '{print \$1}'"
)"

[ "$LOCAL_SHA" = "$REMOTE_SHA" ] ||
  bmo_die "SHA256 divergente apos upload"

echo "SHA256_OK=$LOCAL_SHA"

bmo_log "70%" "Instalando candidate com backup automatico..."

INSTALL_OUTPUT="$(
  bmo_ssh \
    "sudo -n '$BMO_REMOTE_HELPER' install-candidate '$REMOTE_FILE'"
)"

printf '%s\n' "$INSTALL_OUTPUT"

BACKUP_ID="$(
  printf '%s\n' "$INSTALL_OUTPUT" |
  sed -n 's/^BACKUP_ID=//p' |
  tail -n1
)"

[ -n "$BACKUP_ID" ] ||
  bmo_die "helper nao retornou BACKUP_ID"

bmo_log "82%" "Reiniciando somente kiosk..."

bmo_ssh \
  "sudo -n '$BMO_REMOTE_HELPER' restart-kiosk"

bmo_log "92%" "Health checks..."

bmo_ssh \
  "python3 -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:8090/index.bmo-next.html', timeout=3).read(1)\""

bmo_ssh \
  "python3 -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:8088/health', timeout=3).read(1)\""

REMOTE_INSTALLED_SHA="$(
  bmo_ssh \
    "sha256sum /opt/bmo-ui/index.bmo-next.html | awk '{print \$1}'"
)"

[ "$REMOTE_INSTALLED_SHA" = "$LOCAL_SHA" ] ||
  bmo_die "candidate instalado nao corresponde ao Git"

bmo_log "100%" "Candidate implantado."

echo
echo "BACKUP_ID=$BACKUP_ID"
echo "CANDIDATE_SHA256=$LOCAL_SHA"
echo
echo "TESTE FISICO OBRIGATORIO NO R36S."
echo "NAO PROMOVER PRODUCAO AUTOMATICAMENTE."

echo
echo "============================================================"
echo " BMO_DEPLOY_CANDIDATE_OK"
echo "============================================================"
