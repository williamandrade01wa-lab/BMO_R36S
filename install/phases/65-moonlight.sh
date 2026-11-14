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

MANIFEST="$REPO_ROOT/install/manifests/moonlight.env"

TARGET_ROOT=""
MODE=""
DEB=""


die() {
    echo "ERRO: $*" >&2
    exit 1
}


while [ "$#" -gt 0 ]; do

    case "$1" in

        --root)
            TARGET_ROOT="$2"
            shift 2
            ;;

        --deb)
            DEB="$2"
            shift 2
            ;;

        --apply)
            MODE="apply"
            shift
            ;;

        --check)
            MODE="check"
            shift
            ;;

        *)
            die "argumento desconhecido: $1"
            ;;

    esac

done


[ "$EUID" -eq 0 ] || die "fase requer root"
[ -n "$TARGET_ROOT" ] || die "--root obrigatorio"
[ -n "$MODE" ] || die "--apply ou --check obrigatorio"

TARGET_ROOT="$(
    readlink -f "$TARGET_ROOT"
)"

[ "$TARGET_ROOT" != "/" ] || {
    die "TARGET_ROOT=/ e proibido"
}

[ -f "$TARGET_ROOT/.bmo-ready-build-root" ] || {
    die "marker .bmo-ready-build-root ausente"
}

# shellcheck disable=SC1090
source "$MANIFEST"


in_target() {

    chroot "$TARGET_ROOT" \
        /usr/bin/env -i \
        HOME=/root \
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        DEBIAN_FRONTEND=noninteractive \
        "$@"
}


echo "============================================================"
echo " BMO READY - PHASE 65 MOONLIGHT"
echo " MODE=$MODE"
echo "============================================================"


if [ "$MODE" = "apply" ]; then

    [ -f "$DEB" ] || {
        die "--deb obrigatorio no apply"
    }

    SHA="$(
        sha256sum "$DEB" |
        awk '{print $1}'
    )"

    echo "DEB_SHA256=$SHA"

    [ "$SHA" = "$BMO_MOONLIGHT_DEB_SHA256" ] || {
        die "SHA do .deb divergente"
    }


    PKG="$(
        dpkg-deb -f "$DEB" Package
    )"

    VER="$(
        dpkg-deb -f "$DEB" Version
    )"

    ARCH="$(
        dpkg-deb -f "$DEB" Architecture
    )"

    [ "$PKG" = "moonlight-qt" ]
    [ "$VER" = "$BMO_MOONLIGHT_VERSION" ]
    [ "$ARCH" = "$BMO_MOONLIGHT_ARCH" ]


    install \
        -o root \
        -g root \
        -m 0644 \
        "$DEB" \
        "$TARGET_ROOT/tmp/bmo-moonlight.deb"


    in_target \
        apt-get \
        install \
        -y \
        /tmp/bmo-moonlight.deb


    rm -f \
        "$TARGET_ROOT/tmp/bmo-moonlight.deb"

fi


INSTALLED="$(
    in_target \
        dpkg-query \
        -W \
        -f='${Version}' \
        moonlight-qt 2>/dev/null || true
)"

echo "INSTALLED_VERSION=$INSTALLED"

[ "$INSTALLED" = "$BMO_MOONLIGHT_VERSION" ] || {
    die "Moonlight nao instalado na versao esperada"
}


BIN="$TARGET_ROOT/usr/bin/moonlight-qt"

[ -x "$BIN" ] || {
    die "moonlight-qt ausente"
}


BIN_SHA="$(
    sha256sum "$BIN" |
    awk '{print $1}'
)"

echo "BINARY_SHA256=$BIN_SHA"

[ "$BIN_SHA" = "$BMO_MOONLIGHT_BINARY_SHA256" ] || {
    die "Moonlight binary SHA divergente"
}


echo
echo "============================================================"
echo " BMO_READY_PHASE65_MOONLIGHT_OK"
echo "============================================================"
