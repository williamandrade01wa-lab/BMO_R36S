#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

REPO_ROOT="$(
    cd "$SCRIPT_DIR/../.." &&
    pwd
)"

PACKAGES_FILE="$REPO_ROOT/install/manifests/required-packages.txt"
GROUPS_FILE="$REPO_ROOT/install/manifests/required-groups.txt"
READY_ENV="$REPO_ROOT/install/manifests/ready-v1.0.0.env"

TARGET_ROOT=""
MODE=""


die() {
    echo "ERRO: $*" >&2
    exit 1
}


while [ "$#" -gt 0 ]; do

    case "$1" in

        --root)
            [ "$#" -ge 2 ] || die "--root requer caminho"
            TARGET_ROOT="$2"
            shift 2
            ;;

        --check)
            MODE="check"
            shift
            ;;

        --apply)
            MODE="apply"
            shift
            ;;

        *)
            die "argumento desconhecido: $1"
            ;;

    esac

done


[ "$EUID" -eq 0 ] || die "fase requer root"
[ -n "$TARGET_ROOT" ] || die "--root e obrigatorio"
[ -n "$MODE" ] || die "--check ou --apply e obrigatorio"

case "$TARGET_ROOT" in
    /*) ;;
    *) die "--root precisa ser absoluto" ;;
esac

[ -d "$TARGET_ROOT" ] || die "TARGET_ROOT nao existe"

TARGET_ROOT="$(
    readlink -f -- "$TARGET_ROOT"
)"

[ "$TARGET_ROOT" != "/" ] || {
    die "TARGET_ROOT=/ e proibido"
}

[ -f "$TARGET_ROOT/.bmo-ready-build-root" ] || {
    die "marker .bmo-ready-build-root ausente"
}

[ -f "$PACKAGES_FILE" ] || die "manifest pacotes ausente"
[ -f "$GROUPS_FILE" ] || die "manifest grupos ausente"
[ -f "$READY_ENV" ] || die "manifest Ready ausente"

# shellcheck disable=SC1090
source "$READY_ENV"

MOONLIGHT_VERSION="$BMO_MOONLIGHT_QT_VERSION"


in_target() {

    chroot "$TARGET_ROOT" \
        /usr/bin/env -i \
        HOME=/root \
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        DEBIAN_FRONTEND=noninteractive \
        "$@"
}


echo "============================================================"
echo " BMO READY - PHASE 60 PREREQUISITES"
echo " MODE=$MODE"
echo "============================================================"


ARCH="$(
    in_target dpkg --print-architecture
)"

echo "TARGET_ARCH=$ARCH"

[ "$ARCH" = "arm64" ] || {
    die "arquitetura alvo precisa ser arm64"
}


echo
echo "[1/4] Usuario..."

if ! in_target id r36s >/dev/null 2>&1; then

    [ "$MODE" = "apply" ] || {
        die "usuario r36s ausente"
    }

    if in_target getent passwd 1000 >/dev/null 2>&1; then
        die "UID 1000 ocupado"
    fi

    if ! in_target getent group r36s >/dev/null 2>&1; then

        if in_target getent group 1000 >/dev/null 2>&1; then
            die "GID 1000 ocupado"
        fi

        in_target groupadd \
            --gid 1000 \
            r36s
    fi

    in_target useradd \
        --uid 1000 \
        --gid 1000 \
        --create-home \
        --shell /bin/bash \
        --comment R36S \
        r36s

fi

[ "$(in_target id -u r36s)" = "1000" ]
[ "$(in_target id -g r36s)" = "1000" ]

echo "USER_OK"


echo
echo "[2/4] Repositorios / Moonlight..."

if [ "$MODE" = "apply" ]; then

    in_target apt-get update

    in_target apt-get install \
        -y \
        ca-certificates \
        curl

    if ! in_target \
        apt-cache \
        show \
        moonlight-qt \
        >/dev/null 2>&1
    then

        echo "Configurando repositorio oficial Moonlight/Cloudsmith..."

        in_target \
            /bin/bash \
            -lc \
            "curl -1sLf 'https://dl.cloudsmith.io/public/moonlight-game-streaming/moonlight-qt/setup.deb.sh' | bash"

        in_target apt-get update

    fi


    echo "Versoes Moonlight disponiveis:"

    in_target \
        apt-cache \
        policy \
        moonlight-qt || true


    AVAILABLE="$(
        in_target \
            apt-cache \
            madison \
            moonlight-qt 2>/dev/null |
        awk '{print $3}' |
        grep -Fx "$MOONLIGHT_VERSION" |
        head -n1 || true
    )"

    [ "$AVAILABLE" = "$MOONLIGHT_VERSION" ] || {
        die "Moonlight $MOONLIGHT_VERSION nao disponivel"
    }

fi

echo "MOONLIGHT_REPOSITORY_OK"


echo
echo "[3/4] Pacotes..."

if [ "$MODE" = "apply" ]; then

    mapfile -t PKGS < <(
        grep -Ev \
            '^[[:space:]]*(#|$)' \
            "$PACKAGES_FILE" |
        grep -Fvx \
            'moonlight-qt'
    )

    in_target \
        apt-get \
        install \
        -y \
        "${PKGS[@]}"

    in_target \
        apt-get \
        install \
        -y \
        "moonlight-qt=$MOONLIGHT_VERSION"

fi


MISSING=0

while IFS= read -r PKG; do

    [ -n "$PKG" ] || continue

    if ! in_target \
        dpkg-query \
        -W \
        -f='${db:Status-Abbrev}' \
        "$PKG" 2>/dev/null |
        grep -q '^ii '
    then

        echo "MISSING_PACKAGE=$PKG"
        MISSING=$((MISSING + 1))

    fi

done < "$PACKAGES_FILE"

echo "MISSING_PACKAGES=$MISSING"

[ "$MISSING" -eq 0 ] || {
    die "pacotes obrigatorios ausentes"
}


INSTALLED_MOONLIGHT="$(
    in_target \
        dpkg-query \
        -W \
        -f='${Version}' \
        moonlight-qt
)"

echo "MOONLIGHT_INSTALLED_VERSION=$INSTALLED_MOONLIGHT"

[ "$INSTALLED_MOONLIGHT" = "$MOONLIGHT_VERSION" ] || {
    die "versao Moonlight divergente"
}

echo "PACKAGES_OK"


echo
echo "[4/4] Grupos..."

if [ "$MODE" = "apply" ]; then

    while IFS= read -r GROUP; do

        [ -n "$GROUP" ] || continue

        in_target \
            getent \
            group \
            "$GROUP" \
            >/dev/null 2>&1 || {
                in_target groupadd "$GROUP"
            }

        in_target \
            usermod \
            -a \
            -G "$GROUP" \
            r36s

    done < "$GROUPS_FILE"

fi


while IFS= read -r GROUP; do

    [ -n "$GROUP" ] || continue

    in_target id -nG r36s |
        tr ' ' '\n' |
        grep -Fxq "$GROUP" || {
            die "grupo ausente: $GROUP"
        }

done < "$GROUPS_FILE"

echo "USER_GROUPS_OK"


echo
echo "============================================================"
echo " BMO_READY_PHASE60_PREREQS_OK"
echo "============================================================"
