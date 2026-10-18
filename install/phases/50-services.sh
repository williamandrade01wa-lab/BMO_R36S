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

ENABLED="$REPO_ROOT/install/manifests/enabled-services.txt"
OPTIONAL="$REPO_ROOT/install/manifests/optional-services.txt"

TARGET_ROOT=""


die() {
    echo "ERRO: $*" >&2
    exit 1
}


target_path() {

    local path="$1"

    case "$path" in
        /*) ;;
        *) die "caminho precisa ser absoluto: $path" ;;
    esac

    printf '%s%s\n' \
        "${TARGET_ROOT%/}" \
        "$path"
}


service_list() {

    grep -Ev \
        '^[[:space:]]*(#|$)' \
        "$1"
}


while [ "$#" -gt 0 ]; do

    case "$1" in

        --root)
            [ "$#" -ge 2 ] || die "--root requer caminho"
            TARGET_ROOT="$2"
            shift 2
            ;;

        *)
            die "argumento desconhecido: $1"
            ;;

    esac

done


[ "$EUID" -eq 0 ] || die "fase requer root"
[ -n "$TARGET_ROOT" ] || die "--root e obrigatorio"

case "$TARGET_ROOT" in
    /*) ;;
    *) die "--root precisa ser absoluto" ;;
esac

[ -d "$TARGET_ROOT" ] || {
    die "TARGET_ROOT precisa existir"
}

TARGET_ROOT="$(
    readlink -f -- "$TARGET_ROOT"
)"

[ "$TARGET_ROOT" != "/" ] || {
    die "TARGET_ROOT=/ e proibido"
}

[ -f "$TARGET_ROOT/.bmo-ready-sandbox" ] || {
    die "marker .bmo-ready-sandbox ausente"
}

SYSTEMD_DIR="$(
    target_path /etc/systemd/system
)"

[ -d "$SYSTEMD_DIR" ] || {
    die "Phase 40 ainda nao instalou /etc/systemd/system"
}

echo "============================================================"
echo " BMO READY - PHASE 50 SERVICES"
echo "============================================================"
echo "TARGET_ROOT=$TARGET_ROOT"


echo
echo "[1/3] Validando units..."

while IFS= read -r UNIT; do

    [ -f "$SYSTEMD_DIR/$UNIT" ] || {
        die "unit enabled ausente: $UNIT"
    }

done < <(service_list "$ENABLED")

while IFS= read -r UNIT; do

    [ -f "$SYSTEMD_DIR/$UNIT" ] || {
        die "unit optional ausente: $UNIT"
    }

done < <(service_list "$OPTIONAL")

echo "UNIT_FILES_OK"


echo
echo "[2/3] Materializando enabled..."

LINK_COUNT=0

while IFS= read -r UNIT; do

    UNIT_FILE="$SYSTEMD_DIR/$UNIT"

    WANTED_BY="$(
        awk -F= '
            /^[[:space:]]*WantedBy=/ {
                print $2
            }
        ' "$UNIT_FILE"
    )"

    [ -n "$WANTED_BY" ] || {
        die "WantedBy ausente: $UNIT"
    }

    for TARGET in $WANTED_BY; do

        WANTS_DIR="$SYSTEMD_DIR/$TARGET.wants"

        install \
            -d \
            -o root \
            -g root \
            -m 0755 \
            "$WANTS_DIR"

        LINK="$WANTS_DIR/$UNIT"

        rm -f "$LINK"

        (
            cd "$WANTS_DIR"
            ln -s "../$UNIT" "$UNIT"
        )

        [ -L "$LINK" ] || {
            die "falha criando symlink: $UNIT"
        }

        [ "$(readlink "$LINK")" = "../$UNIT" ] || {
            die "symlink inesperado: $LINK"
        }

        echo "ENABLE $UNIT -> $TARGET"

        LINK_COUNT=$((LINK_COUNT + 1))

    done

done < <(service_list "$ENABLED")

echo "ENABLED_LINKS_CREATED=$LINK_COUNT"


echo
echo "[3/3] Garantindo opcionais disabled..."

while IFS= read -r UNIT; do

    while IFS= read -r LINK; do
        [ -n "$LINK" ] || continue
        rm -f "$LINK"
    done < <(
        find "$SYSTEMD_DIR" \
            -type l \
            -name "$UNIT" \
            -print
    )

    echo "DISABLED $UNIT"

done < <(service_list "$OPTIONAL")


OPTIONAL_LINKS=0

while IFS= read -r UNIT; do

    COUNT="$(
        find "$SYSTEMD_DIR" \
            -type l \
            -name "$UNIT" |
        wc -l
    )"

    OPTIONAL_LINKS=$((OPTIONAL_LINKS + COUNT))

done < <(service_list "$OPTIONAL")

echo "OPTIONAL_LINKS=$OPTIONAL_LINKS"

[ "$OPTIONAL_LINKS" -eq 0 ] || {
    die "servico optional ficou enabled"
}

echo
echo "SYSTEMCTL_EXECUTED=NO"

echo
echo "============================================================"
echo " BMO_READY_PHASE50_SERVICES_OK"
echo "============================================================"
