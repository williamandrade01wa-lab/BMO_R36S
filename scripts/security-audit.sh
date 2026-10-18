#!/usr/bin/env bash

set -euo pipefail

ROOT="$(
    cd "$(dirname "$0")/.." &&
    pwd
)"

cd "$ROOT"

echo "============================================================"
echo " BMO SECURITY AUDIT"
echo "============================================================"


echo
echo "[1/5] Arquivos proibidos..."

FORBIDDEN_FILE_REGEX='(^|/)(Moonlight\.conf|id_rsa|id_ed25519|github_deploy_key|bmo-runtime-config\.js|system-connections/)|\.(gba|gb|gbc|sfc|smc|nes|iso|cso|pbp|p12|pfx|key|pem|token|secret|credentials|img|raw|deb)$'

if git ls-files |
    grep -E "$FORBIDDEN_FILE_REGEX" \
    > /tmp/bmo-security-files.txt
then

    echo "ERRO: arquivos sensiveis rastreados:"
    cat /tmp/bmo-security-files.txt
    exit 10

fi

echo "TRACKED_FILES_OK"


echo
echo "[2/5] Segredos..."

SECRET_REGEX='BEGIN (OPENSSH|RSA|EC|DSA) PRIVATE KEY|github_pat_[A-Za-z0-9_]+|gh[pousr]_[A-Za-z0-9]+'

if git grep \
    -I \
    -n \
    -E \
    "$SECRET_REGEX" \
    -- \
    . \
    > /tmp/bmo-security-secrets.txt
then

    echo "ERRO: possivel segredo no Git:"
    cat /tmp/bmo-security-secrets.txt
    exit 20

fi

echo "SECRET_SCAN_OK"


echo
echo "[3/5] IP privado fixo em codigo..."

if git grep \
    -I \
    -n \
    -E \
    '(192\.168\.[0-9]+\.[0-9]+|10\.[0-9]+\.[0-9]+\.[0-9]+|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+)' \
    -- \
    '*.sh' \
    '*.py' \
    '*.html' \
    > /tmp/bmo-security-ip.txt
then

    echo "ERRO: IP privado fixo encontrado:"
    cat /tmp/bmo-security-ip.txt
    exit 30

fi

echo "NO_PRIVATE_IP_HARDCODE_OK"


echo
echo "[4/5] Sudo perigoso..."

if git grep \
    -I \
    -n \
    -E \
    'NOPASSWD:[[:space:]]*ALL([[:space:]]|$)' \
    -- \
    . \
    > /tmp/bmo-security-sudo.txt
then

    echo "ERRO: NOPASSWD ALL encontrado:"
    cat /tmp/bmo-security-sudo.txt
    exit 40

fi

echo "NO_NOPASSWD_ALL_OK"


echo
echo "[5/5] Git diff..."

git diff --check

echo "DIFF_CHECK_OK"


echo
echo "============================================================"
echo " BMO_SECURITY_AUDIT_OK"
echo "============================================================"
