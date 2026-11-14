#!/bin/bash

export DISPLAY=:0

LOGTAG="bmo-usb-tether"


# ============================================================
# MOSTRAR MENSAGEM NA TELA
# ============================================================

show_screen() {

  MSG="$1"

  logger -t "$LOGTAG" "$MSG"

  XAUTH=""

  for F in \
    /home/r36s/.Xauthority \
    /root/.Xauthority
  do
    if [ -f "$F" ]; then
      XAUTH="$F"
      break
    fi
  done


  if command -v xmessage >/dev/null 2>&1; then

    if [ -n "$XAUTH" ]; then
      XAUTHORITY="$XAUTH" \
      DISPLAY=:0 \
      xmessage \
        -center \
        -timeout 12 \
        "$MSG" \
        >/dev/null 2>&1 &
    else
      DISPLAY=:0 \
      xmessage \
        -center \
        -timeout 12 \
        "$MSG" \
        >/dev/null 2>&1 &
    fi

  fi
}


# ============================================================
# LOCALIZA INTERFACE USB QUE NAO SEJA WIFI
# ============================================================

find_usb_net() {

  for P in /sys/class/net/*; do

    [ -e "$P" ] || continue

    IFACE="$(basename "$P")"

    [ "$IFACE" = "lo" ] && continue


    # Ignora Wi-Fi, inclusive dongle USB atual
    if [ -d "$P/wireless" ]; then
      continue
    fi


    DEV="$(
      readlink -f "$P/device" 2>/dev/null || true
    )"


    case "$DEV" in
      *"/usb"*)
        echo "$IFACE"
        return 0
        ;;
    esac

  done

  return 1
}


# ============================================================
# PEGA IPV4
# ============================================================

get_ipv4() {

  IFACE="$1"

  ip -4 -o addr show dev "$IFACE" scope global 2>/dev/null \
    | head -n1 \
    | sed -E 's/.* inet ([0-9.]+)\/.*/\1/'
}


# ============================================================
# FORCA NETWORKMANAGER / DHCP
# ============================================================

bring_up_usb() {

  IFACE="$1"

  logger -t "$LOGTAG" \
    "Interface USB detectada: $IFACE"


  ip link set "$IFACE" up 2>/dev/null || true


  # Primeiro tenta conectar normalmente
  nmcli device connect "$IFACE" \
    >/dev/null 2>&1 || true


  sleep 3


  IP="$(get_ipv4 "$IFACE")"

  if [ -n "$IP" ]; then
    echo "$IP"
    return 0
  fi


  # Se ainda nao pegou IP, cria perfil DHCP proprio
  PROFILE="BMO-USB-TETHER-$IFACE"


  if ! nmcli -t -f NAME connection show \
       | grep -Fxq "$PROFILE"; then

    nmcli connection add \
      type ethernet \
      ifname "$IFACE" \
      con-name "$PROFILE" \
      ipv4.method auto \
      ipv6.method ignore \
      connection.autoconnect yes \
      >/dev/null 2>&1 || true

  fi


  nmcli connection up "$PROFILE" \
    >/dev/null 2>&1 || true


  # Espera ate 30 segundos por DHCP
  for N in $(seq 1 30); do

    IP="$(get_ipv4 "$IFACE")"

    if [ -n "$IP" ]; then
      echo "$IP"
      return 0
    fi

    sleep 1

  done


  return 1
}


# ============================================================
# LOOP PRINCIPAL
# ============================================================

LAST=""

while true; do

  IFACE="$(find_usb_net || true)"


  if [ -z "$IFACE" ]; then

    if [ "$LAST" != "WAIT" ]; then

      logger -t "$LOGTAG" \
        "Aguardando tethering USB"

      LAST="WAIT"

    fi

    sleep 2
    continue
  fi


  CURRENT="IFACE:$IFACE"


  if [ "$LAST" != "$CURRENT" ]; then

    show_screen \
"USB DETECTADO

$IFACE

CONFIGURANDO REDE..."

    LAST="$CURRENT"

  fi


  IP="$(get_ipv4 "$IFACE")"


  if [ -z "$IP" ]; then

    IP="$(bring_up_usb "$IFACE" || true)"

  fi


  if [ -n "$IP" ]; then

    STATE="IP:$IFACE:$IP"

    if [ "$LAST" != "$STATE" ]; then

      show_screen \
"USB CONECTADO

INTERFACE:
$IFACE

IP:
$IP

SSH:
ssh r36s@$IP"

      LAST="$STATE"

    fi

  else

    STATE="FAIL:$IFACE"

    if [ "$LAST" != "$STATE" ]; then

      show_screen \
"USB DETECTADO

$IFACE

SEM IP

ATIVE
ROTEADOR USB
NO CELULAR"

      LAST="$STATE"

    fi

  fi


  sleep 3

done
