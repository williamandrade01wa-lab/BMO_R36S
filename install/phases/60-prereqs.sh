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

TARGET_ROOT="$(readlink -f -- "$TARGET_ROOT")"

[ "$TARGET_ROOT" != "/" ] || die "TARGET_ROOT=/ e proibido"

[ -f "$TARGET_ROOT/.bmo-ready-build-root" ] || {
    die "marker .bmo-ready-build-root ausente"
}

[ -f "$PACKAGES_FILE" ] || die "manifest de pacotes ausente"
[ -f "$GROUPS_FILE" ] || die "manifest de grupos ausente"

in_target() {
    chroot "$TARGET_ROOT" \
        /usr/bin/env -i \
        HOME=/root \
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        "$@"
}

echo "============================================================"
echo " BMO READY - PHASE 60 PREREQUISITES"
echo " MODE=$MODE"
echo "============================================================"

ARCH="$(in_target dpkg --print-architecture)"

echo "TARGET_ARCH=$ARCH"

[ "$ARCH" = "arm64" ] || die "arquitetura alvo precisa ser arm64"


echo
echo "[1/3] Usuario..."

if ! in_target id r36s >/dev/null 2>&1; then

    [ "$MODE" = "apply" ] || die "usuario r36s ausente"

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
echo "[2/3] Pacotes..."

if [ "$MODE" = "apply" ]; then

    mapfile -t PKGS < <(
        grep -Ev '^[[:space:]]*(#|$)' "$PACKAGES_FILE"
    )

    in_target apt-get update

    in_target apt-get install \
        -y \
        "${PKGS[@]}"
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

[ "$MISSING" -eq 0 ] || die "pacotes obrigatorios ausentes"

echo "PACKAGES_OK"


echo
echo "[3/3] Grupos..."

if [ "$MODE" = "apply" ]; then

    while IFS= read -r GROUP; do

        [ -n "$GROUP" ] || continue

        in_target getent group "$GROUP" >/dev/null 2>&1 || {
            in_target groupadd "$GROUP"
        }

        in_target usermod \
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
