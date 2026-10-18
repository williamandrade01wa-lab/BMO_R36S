#!/usr/bin/env bash

set -euo pipefail

TARGET_ROOT=""


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


echo "============================================================"
echo " BMO READY - PHASE 70 SANITIZE"
echo "============================================================"


echo
echo "[1/5] Removendo credenciais/runtime pessoais..."

rm -rf \
    "$TARGET_ROOT/home/r36s/.ssh" \
    "$TARGET_ROOT/root/.ssh" \
    "$TARGET_ROOT/home/r36s/.config/moonlight" \
    "$TARGET_ROOT/home/r36s/.cache/moonlight" \
    "$TARGET_ROOT/home/r36s/.local/share/moonlight" \
    "$TARGET_ROOT/home/r36s/.config/chromium" \
    "$TARGET_ROOT/home/r36s/.cache/chromium" \
    "$TARGET_ROOT/home/r36s/.config/ppsspp/PSP/SAVEDATA" \
    "$TARGET_ROOT/home/r36s/.config/ppsspp/PSP/CACHE" \
    "$TARGET_ROOT/opt/bmo-ui/game-covers"

find "$TARGET_ROOT/home/r36s" \
    -type f \
    -name 'Moonlight.conf' \
    -delete 2>/dev/null || true

rm -f \
    "$TARGET_ROOT/home/r36s/.bash_history" \
    "$TARGET_ROOT/root/.bash_history"

echo "PERSONAL_DATA_CLEAN_OK"


echo
echo "[1b/5] Limpando identidade clonavel..."

rm -f     "$TARGET_ROOT/etc/bmo/moonlight-host"     "$TARGET_ROOT/var/lib/systemd/random-seed"     2>/dev/null || true

if [ -f "$TARGET_ROOT/etc/machine-id" ] &&
   [ ! -L "$TARGET_ROOT/etc/machine-id" ]
then
    : > "$TARGET_ROOT/etc/machine-id"
fi

DBUS_MACHINE_ID="$TARGET_ROOT/var/lib/dbus/machine-id"

if [ -f "$DBUS_MACHINE_ID" ] &&
   [ ! -L "$DBUS_MACHINE_ID" ]
then
    : > "$DBUS_MACHINE_ID"
fi

echo "GENERIC_IDENTITY_CLEAN_OK"


echo
echo "[2/5] Removendo Wi-Fi salvo..."

NM="$TARGET_ROOT/etc/NetworkManager/system-connections"

if [ -d "$NM" ]; then
    find "$NM" \
        -mindepth 1 \
        -maxdepth 1 \
        -type f \
        -delete
fi

rm -f \
    "$TARGET_ROOT/var/lib/NetworkManager/seen-bssids" 2>/dev/null || true

echo "NETWORK_CREDENTIALS_CLEAN_OK"


echo
echo "[3/5] Zerando ROM layout..."

rm -rf "$TARGET_ROOT/home/r36s/ROMs"

install \
    -d \
    -o 1000 \
    -g 1000 \
    -m 0755 \
    "$TARGET_ROOT/home/r36s/ROMs" \
    "$TARGET_ROOT/home/r36s/ROMs/gba" \
    "$TARGET_ROOT/home/r36s/ROMs/sfc" \
    "$TARGET_ROOT/home/r36s/ROMs/psp"

ROM_FILES="$(
    find "$TARGET_ROOT/home/r36s/ROMs" \
        -type f |
    wc -l
)"

echo "ROM_FILES=$ROM_FILES"

[ "$ROM_FILES" -eq 0 ]

echo "ROM_SANITIZE_OK"


echo
echo "[4/5] Limpando histories/logs/cache..."

find "$TARGET_ROOT/home/r36s/.config/retroarch" \
    -maxdepth 1 \
    -type f \
    \( \
        -name '*history*' \
        -o -name '*recent*' \
        -o -name '*.lpl' \
    \) \
    -delete 2>/dev/null || true

if [ -d "$TARGET_ROOT/var/log" ]; then
    find "$TARGET_ROOT/var/log" \
        -type f \
        -exec truncate -s 0 {} \; \
        2>/dev/null || true
fi

rm -rf \
    "$TARGET_ROOT/tmp/"* \
    "$TARGET_ROOT/var/tmp/"* \
    "$TARGET_ROOT/var/cache/apt/archives/"*.deb \
    2>/dev/null || true

echo "RUNTIME_CLEAN_OK"


echo
echo "[5/5] Validando sanitizacao..."

[ ! -e "$TARGET_ROOT/home/r36s/.ssh" ]
[ ! -e "$TARGET_ROOT/root/.ssh" ]
[ ! -e "$TARGET_ROOT/home/r36s/.config/moonlight" ]
[ ! -e "$TARGET_ROOT/home/r36s/.config/chromium" ]
[ ! -e "$TARGET_ROOT/home/r36s/.config/ppsspp/PSP/SAVEDATA" ]
[ ! -e "$TARGET_ROOT/opt/bmo-ui/game-covers" ]

if [ -d "$NM" ]; then
    NM_COUNT="$(
        find "$NM" \
            -mindepth 1 \
            -maxdepth 1 \
            -type f |
        wc -l
    )"

    [ "$NM_COUNT" -eq 0 ]
fi

echo
echo "============================================================"
echo " BMO_READY_PHASE70_SANITIZE_OK"
echo "============================================================"
