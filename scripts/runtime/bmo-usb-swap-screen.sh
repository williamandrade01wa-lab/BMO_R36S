#!/bin/bash

TTY="/dev/tty1"
LAST=""
BASE_USB=""

print_screen() {
  MSG="$1"

  logger -t bmo-usb-swap "$MSG"

  {
    printf '\033c'
    echo
    echo "========================================"
    echo "              BMO USB TEST"
    echo "========================================"
    echo
    printf '%s\n' "$MSG"
    echo
    echo "========================================"
  } > "$TTY"
}


usb_snapshot() {
  lsusb 2>/dev/null | sort
}


find_usb_network() {

  for P in /sys/class/net/*; do

    [ -e "$P" ] || continue

    IFACE="$(basename "$P")"

    [ "$IFACE" = "lo" ] && continue

    # ignora Wi-Fi USB
    [ -d "$P/wireless" ] && continue

    DEV="$(readlink -f "$P/device" 2>/dev/null || true)"

    case "$DEV" in
      *"/usb"*)
        echo "$IFACE"
        return 0
        ;;
    esac

  done

  return 1
}


get_ip() {
  ip -4 -o addr show dev "$1" scope global 2>/dev/null \
    | head -n1 \
    | sed -E 's/.* inet ([0-9.]+)\/.*/\1/'
}


# ------------------------------------------------------------
# Guarda estado USB inicial enquanto dongle ainda está presente
# ------------------------------------------------------------

BASE_USB="$(usb_snapshot)"

print_screen \
"MONITOR PRONTO

1. REMOVA O DONGLE WIFI
2. CONECTE O CELULAR
3. ATIVE ROTEADOR USB

AGUARDANDO TROCA..."

sleep 2


while true; do

  # ----------------------------------------------------------
  # Verifica Wi-Fi antigo
  # ----------------------------------------------------------

  WIFI="$(
    find /sys/class/net -maxdepth 2 \
      -type d -name wireless 2>/dev/null \
      | head -n1
  )"

  # ----------------------------------------------------------
  # Compara dispositivos USB
  # ----------------------------------------------------------

  NOW_USB="$(usb_snapshot)"

  # ----------------------------------------------------------
  # Procura interface Ethernet/RNDIS USB
  # ----------------------------------------------------------

  IFACE="$(find_usb_network || true)"


  if [ -n "$IFACE" ]; then

    ip link set "$IFACE" up 2>/dev/null || true

    nmcli device connect "$IFACE" \
      >/dev/null 2>&1 || true

    IP="$(get_ip "$IFACE")"


    if [ -n "$IP" ]; then

      STATE="CONNECTED:$IFACE:$IP"

      if [ "$STATE" != "$LAST" ]; then

        print_screen \
"SUCESSO!

USB NETWORK:
$IFACE

IP:
$IP

SSH:
ssh r36s@$IP"

        LAST="$STATE"

      fi

    else

      STATE="NOIP:$IFACE"

      if [ "$STATE" != "$LAST" ]; then

        print_screen \
"INTERFACE USB ENCONTRADA

$IFACE

SEM IP AINDA

TENTANDO DHCP..."

        LAST="$STATE"

      fi

    fi


  elif [ "$NOW_USB" != "$BASE_USB" ]; then

    STATE="USBCHANGE"

    if [ "$STATE" != "$LAST" ]; then

      print_screen \
"USB MUDOU!

UM DISPOSITIVO FOI
REMOVIDO OU CONECTADO.

MAS AINDA NAO EXISTE
INTERFACE DE REDE USB.

ATIVE ROTEADOR USB
NO CELULAR."

      LAST="$STATE"

    fi


  elif [ -z "$WIFI" ]; then

    STATE="NOWIFI"

    if [ "$STATE" != "$LAST" ]; then

      print_screen \
"DONGLE WIFI REMOVIDO

AGORA CONECTE
O CELULAR USB-C

E ATIVE
ROTEADOR USB."

      LAST="$STATE"

    fi


  else

    STATE="WAIT"

    if [ "$STATE" != "$LAST" ]; then

      print_screen \
"MONITOR ATIVO

DONGLE WIFI
AINDA PRESENTE

PODE REMOVER."

      LAST="$STATE"

    fi

  fi


  sleep 2

done
