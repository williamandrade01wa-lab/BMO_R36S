#!/usr/bin/env bash

set -euo pipefail

BMO_REPO_ROOT="$(
    cd "$(dirname "${BASH_SOURCE[0]}")/../.." &&
    pwd
)"

BMO_DEPLOY_CONFIG="${
    BMO_DEPLOY_CONFIG:-$HOME/.config/bmo/deploy.env
}"


if [ -r "$BMO_DEPLOY_CONFIG" ]; then

    # Arquivo pertence ao proprio usuario que executa deploy.
    # shellcheck disable=SC1090
    source "$BMO_DEPLOY_CONFIG"

fi


BMO_R36S_HOST="${BMO_R36S_HOST:-}"
BMO_R36S_USER="${BMO_R36S_USER:-r36s}"
BMO_R36S_KEY="${BMO_R36S_KEY:-}"

BMO_REMOTE_INCOMING="/home/r36s/.bmo-deploy/incoming"
BMO_REMOTE_HELPER="/usr/local/sbin/bmo-deploy-helper"


bmo_log() {
    printf '\n[%s] %s\n' "$1" "$2"
}


bmo_die() {
    echo "ERRO: $*" >&2
    exit 1
}


bmo_require_cmd() {

    command -v "$1" >/dev/null 2>&1 ||
        bmo_die "comando obrigatorio ausente: $1"

}


bmo_require_file() {

    [ -f "$1" ] ||
        bmo_die "arquivo obrigatorio ausente: $1"

}


bmo_load_target() {

    [ -n "$BMO_R36S_HOST" ] || {
        bmo_die \
            "BMO_R36S_HOST nao configurado em $BMO_DEPLOY_CONFIG"
    }

    [ -n "$BMO_R36S_KEY" ] || {
        bmo_die \
            "BMO_R36S_KEY nao configurado em $BMO_DEPLOY_CONFIG"
    }

    BMO_REMOTE="${BMO_R36S_USER}@${BMO_R36S_HOST}"
}


bmo_ssh() {

    bmo_load_target

    ssh \
        -i "$BMO_R36S_KEY" \
        -o IdentitiesOnly=yes \
        -o BatchMode=yes \
        -o ConnectTimeout=8 \
        -o StrictHostKeyChecking=accept-new \
        -o ServerAliveInterval=10 \
        -o ServerAliveCountMax=3 \
        "$BMO_REMOTE" \
        "$@"

}


bmo_scp() {

    bmo_load_target

    scp \
        -i "$BMO_R36S_KEY" \
        -o IdentitiesOnly=yes \
        -o BatchMode=yes \
        -o ConnectTimeout=8 \
        -o StrictHostKeyChecking=accept-new \
        "$@"

}


if [ "$(id -un)" = "root" ]; then
    bmo_die \
        "execute como usuario normal, nao como root"
fi


bmo_preflight() {

    bmo_require_cmd git
    bmo_require_cmd ssh
    bmo_require_cmd scp
    bmo_require_cmd sha256sum

    bmo_load_target
    bmo_require_file "$BMO_R36S_KEY"

    bmo_ssh \
        "test -x '$BMO_REMOTE_HELPER' &&
         sudo -n '$BMO_REMOTE_HELPER' status >/dev/null"

}
