#!/usr/bin/env bash

# Auditoria para uma futura EXPORTACAO PUBLICA do BMO.
#
# Uso:
#   bash scripts/public-release-audit.sh
#
# Diferente de scripts/security-audit.sh, este script pode e deve
# falhar enquanto o projeto ainda estiver em desenvolvimento privado.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BLOCKERS=0

blocker() {
    echo "BLOCKER: $*"
    BLOCKERS=$((BLOCKERS + 1))
}

ok() {
    echo "OK: $*"
}

echo "============================================================"
echo " BMO PUBLIC RELEASE AUDIT"
echo "============================================================"

# Primeiro executa a auditoria normal do projeto.
if bash scripts/security-audit.sh; then
    ok "security-audit"
else
    blocker "security-audit falhou"
fi

# Documentacao/proveniencia obrigatoria.
for file in \
    CREDITS.md \
    THIRD_PARTY.md \
    docs/PUBLIC-RELEASE.md \
    install/manifests/upstream-sources.env

do
    if [ -f "$file" ]; then
        ok "$file"
    else
        blocker "arquivo obrigatorio ausente: $file"
    fi
done

# A licenca do codigo BMO precisa ser deliberadamente escolhida.
if [ -f LICENSE ] || [ -f LICENSE.md ]; then
    ok "licenca do BMO presente"
else
    blocker "LICENSE do codigo BMO ainda nao foi escolhida"
fi

# Binarios externos usados no desenvolvimento privado nao devem entrar
# na exportacao publica final.
PUBLIC_BLOBS="$(
    git ls-files -- \
        'install/runtime/*.deb' \
        'install/runtime/*.tar.gz' \
        'install/runtime/*.AppImage' \
        2>/dev/null || true
)"

if [ -n "$PUBLIC_BLOBS" ]; then
    echo "$PUBLIC_BLOBS"
    blocker "runtimes de terceiros ainda estao rastreados no Git privado"
else
    ok "nenhum runtime de terceiro rastreado"
fi

# Credenciais nunca podem aparecer na arvore publica.
CREDENTIAL_FILES="$(
    git ls-files |
    grep -E '(^|/)(firstboot\.local\.conf|github_deploy_key|id_ed25519|id_rsa|Moonlight\.conf)$' \
    || true
)"

if [ -n "$CREDENTIAL_FILES" ]; then
    echo "$CREDENTIAL_FILES"
    blocker "arquivo de credencial/config privada rastreado"
else
    ok "nenhuma credencial conhecida rastreada"
fi

# Nenhum IP RFC1918 deve permanecer em codigo executavel.
PRIVATE_IPS="$(
    git grep -I -n -E \
        '(192\.168\.[0-9]+\.[0-9]+|10\.[0-9]+\.[0-9]+\.[0-9]+|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+)' \
        -- '*.sh' '*.py' '*.html' '*.js' \
        || true
)"

if [ -n "$PRIVATE_IPS" ]; then
    echo "$PRIVATE_IPS"
    blocker "IP privado fixo em codigo executavel"
else
    ok "nenhum IP privado fixo em codigo executavel"
fi

# Registros de origem precisam conter as versoes publicas verificadas.
grep -Fq 'BMO_PURE_UPSTREAM_SHA256=' install/manifests/upstream-sources.env \
    && ok "origem Pure registrada" \
    || blocker "origem Pure incompleta"

grep -Fq 'BMO_MOONLIGHT_DEB_SHA256=' install/manifests/upstream-sources.env \
    && ok "origem Moonlight registrada" \
    || blocker "origem Moonlight incompleta"

grep -Fq 'BMO_PPSSPP_APPIMAGE_SHA256=' install/manifests/upstream-sources.env \
    && ok "origem PPSSPP registrada" \
    || blocker "origem PPSSPP incompleta"

echo
echo "MANUAL_CHECKS_REQUIRED:"
echo "- confirmar que a instalacao upstream de Moonlight foi testada no R36S"
echo "- confirmar que o AppImage oficial PPSSPP funciona no R36S"
echo "- confirmar que a exportacao publica nao leva o historico privado"
echo "- revisar nome/e-mail de autoria que sera publicado"
echo "- revisar a release publica para nao re-hospedar a Pure sem necessidade"

echo
if [ "$BLOCKERS" -eq 0 ]; then
    echo "============================================================"
    echo " BMO_PUBLIC_RELEASE_READY_OK"
    echo "============================================================"
else
    echo "============================================================"
    echo " BMO_PUBLIC_RELEASE_BLOCKED"
    echo " BLOCKERS=$BLOCKERS"
    echo "============================================================"
    exit 1
fi
