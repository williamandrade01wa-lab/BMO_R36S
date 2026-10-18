#!/bin/bash

# BMO_MOONLIGHT_LAUNCHER_V1

set -u

# BMO_MOONLIGHT_HOST_CONFIG_V1
HOST_FILE="/etc/bmo/moonlight-host"
HOST="${BMO_MOONLIGHT_HOST:-}"
APP="${1:-Desktop}"

if [ -z "$HOST" ] && [ -f "$HOST_FILE" ]; then
    HOST="$(
        grep -Ev '^[[:space:]]*(#|$)' "$HOST_FILE" 2>/dev/null |
        head -n1 || true
    )"
fi

if [ -z "$HOST" ]; then
    echo "ERRO: Sunshine host nao configurado"
    echo "Configure /etc/bmo/moonlight-host"
    echo "ou defina BMO_MOONLIGHT_HOST."
    exit 19
fi

DISPLAY_NUM=":0"
XAUTH="/home/r36s/.Xauthority"

HOTKEY="/usr/local/bin/bmo-moonlight-hotkeys.py"

KIOSK_STOPPED=0
HOTKEY_PID=""


cleanup() {

    if [ -n "${HOTKEY_PID:-}" ]; then

        kill "$HOTKEY_PID" \
            2>/dev/null || true

        wait "$HOTKEY_PID" \
            2>/dev/null || true
    fi


    # Garante que qualquer Moonlight residual encerre.
    pkill \
        -TERM \
        -u r36s \
        -f '(^|/)(moonlight|moonlight-qt)( |$)' \
        2>/dev/null || true


    sleep 1


    if [ "$KIOSK_STOPPED" = "1" ]; then

        systemctl start \
            bmo-kiosk.service \
            >/dev/null 2>&1 || true
    fi
}


trap cleanup EXIT INT TERM


echo "============================================================"
echo " BMO MOONLIGHT"
echo " HOST: $HOST"
echo " APP : $APP"
echo "============================================================"


# Detecta binario.
if command -v moonlight >/dev/null 2>&1; then

    MOONLIGHT="$(command -v moonlight)"

elif command -v moonlight-qt >/dev/null 2>&1; then

    MOONLIGHT="$(command -v moonlight-qt)"

else

    echo "ERRO: Moonlight nao encontrado"
    exit 20
fi


echo "Moonlight: $MOONLIGHT"


# Fecha GUI Moonlight antiga, caso esteja aberta.
pkill \
    -TERM \
    -u r36s \
    -f '(^|/)(moonlight|moonlight-qt)( |$)' \
    2>/dev/null || true

sleep 1


echo "Parando BMO kiosk..."

systemctl stop \
    bmo-kiosk.service

KIOSK_STOPPED=1


# Xorg deve continuar funcionando.
if ! systemctl is-active \
        --quiet \
        bmo-xorg.service
then

    echo "ERRO: Xorg nao esta ativo"
    exit 21
fi


echo "Iniciando FN+SELECT..."

"$HOTKEY" &

HOTKEY_PID="$!"


echo
echo "Iniciando stream..."
echo "FN + SELECT = VOLTAR AO BMO"
echo


runuser \
    -u r36s \
    -- \
    /usr/bin/env \
    DISPLAY="$DISPLAY_NUM" \
    XAUTHORITY="$XAUTH" \
    HOME="/home/r36s" \
    USER="r36s" \
    LOGNAME="r36s" \
    XDG_RUNTIME_DIR="/run/user/1000" \
    PULSE_SERVER="unix:/run/user/1000/pulse/native" \
    SDL_ENABLE_STEAM_CONTROLLERS=1 \
    SENSOR_REPORT_RATE_LIMIT_HZ=0 \
    "$MOONLIGHT" \
    stream \
    "$HOST" \
    "$APP"

RC=$?

echo
echo "Moonlight encerrou RC=$RC"
echo "Voltando ao BMO..."

exit "$RC"
