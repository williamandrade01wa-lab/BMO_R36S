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

MANIFEST="$REPO_ROOT/install/manifests/system-config.sha256"

TARGET_ROOT=""


die() {
    echo "ERRO: $*" >&2
    exit 1
}


target_path() {

    local path="$1"

    case "$path" in
        /*) ;;
        *) die "caminho destino precisa ser absoluto: $path" ;;
    esac

    printf '%s%s\n' \
        "${TARGET_ROOT%/}" \
        "$path"
}


copy_root_file() {

    local source="$1"
    local destination="$2"
    local mode="$3"

    local src="$REPO_ROOT/$source"
    local dst

    [ -f "$src" ] || {
        die "fonte ausente: $source"
    }

    dst="$(target_path "$destination")"

    install \
        -D \
        -o root \
        -g root \
        -m "$mode" \
        "$src" \
        "$dst"

    cmp -s "$src" "$dst" || {
        die "copia divergente: $destination"
    }

    echo "OK $mode $destination"
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


[ "$EUID" -eq 0 ] || {
    die "fase requer root"
}

[ -n "$TARGET_ROOT" ] || {
    die "--root e obrigatorio"
}

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


echo "============================================================"
echo " BMO READY - PHASE 40 SYSTEM CONFIG"
echo "============================================================"

echo "TARGET_ROOT=$TARGET_ROOT"


echo
echo "[1/4] Validando fontes..."

[ -f "$MANIFEST" ] || {
    die "manifest system-config ausente"
}

(
    cd "$REPO_ROOT"
    sha256sum -c install/manifests/system-config.sha256
)

command -v visudo >/dev/null 2>&1 || {
    die "visudo ausente"
}

visudo \
    -cf "$REPO_ROOT/deploy/r36s/bmo-deploy.sudoers" \
    >/dev/null

echo "SOURCE_VALIDATION_OK"


echo
echo "[2/4] System config..."

copy_root_file \
    "deploy/r36s/bmo-kiosk.default" \
    "/etc/default/bmo-kiosk" \
    "0644"

copy_root_file \
    "install/system/udev/99-bmo-usb-power.rules" \
    "/etc/udev/rules.d/99-bmo-usb-power.rules" \
    "0644"

copy_root_file \
    "deploy/r36s/bmo-deploy.sudoers" \
    "/etc/sudoers.d/bmo-deploy" \
    "0440"

copy_root_file \
    "deploy/r36s/bmo-deploy-helper" \
    "/usr/local/sbin/bmo-deploy-helper" \
    "0755"

visudo \
    -cf "$(target_path /etc/sudoers.d/bmo-deploy)" \
    >/dev/null

echo "SYSTEM_CONFIG_OK"


echo
echo "[3/4] Systemd unit files..."

UNITS=(
    bmo-control-api.service
    bmo-kiosk.service
    bmo-ui.service
    bmo-usb-ip-watch.service
    bmo-usb-swap-screen.service
    bmo-usb-tether-auto.service
    bmo-vt.service
    bmo-x-init.service
    bmo-xorg.service
    r36s-battery-api.service
    r36s-console.service
    r36s-sound-api.service
    r36s-status-api.service
)

for unit in "${UNITS[@]}"; do

    copy_root_file \
        "systemd/$unit" \
        "/etc/systemd/system/$unit" \
        "0644"

done

echo "SYSTEMD_UNIT_FILES=${#UNITS[@]}"


echo
echo "[4/4] Garantias..."

SYMLINKS="$(
    find "$(target_path /etc/systemd/system)" \
        -type l 2>/dev/null |
    wc -l
)"

echo "SYSTEMD_SYMLINKS=$SYMLINKS"

[ "$SYMLINKS" -eq 0 ] || {
    die "fase criou symlink systemd"
}

[ ! -e "$(target_path /etc/fstab)" ] || {
    die "fase criou /etc/fstab"
}

[ ! -e "$(target_path /etc/X11/xorg.conf)" ] || {
    die "fase criou xorg.conf"
}

echo "NO_SYSTEMCTL_ACTIONS=YES"
echo "FSTAB_UNTOUCHED=YES"
echo "XORG_UNTOUCHED=YES"

echo
echo "============================================================"
echo " BMO_READY_PHASE40_SYSTEM_CONFIG_OK"
echo "============================================================"
