#!/bin/bash

export DISPLAY=:0

get_usb_network() {

  for iface_path in /sys/class/net/*; do

    [ -e "$iface_path" ] || continue

    iface="$(basename "$iface_path")"

    [ "$iface" = "lo" ] && continue


    # Ignora interfaces wireless.
    # Isso impede que o dongle Wi-Fi USB seja confundido
    # com o tethering USB do celular.
    if [ -d "$iface_path/wireless" ]; then
      continue
    fi


    device_path="$(
      readlink -f "$iface_path/device" 2>/dev/null || true
    )"


    # A interface precisa realmente vir da árvore USB.
    case "$device_path" in
      *"/usb"* )
        ;;
      * )
        continue
        ;;
    esac


    ip="$(
      ip -4 -o addr show dev "$iface" scope global 2>/dev/null \
      | head -n1 \
      | sed -E 's/.* inet ([0-9.]+)\/.*/\1/'
    )"


    if [ -n "$ip" ]; then
      printf '%s|%s\n' "$iface" "$ip"
      return 0
    fi

  done

  return 1
}


find_xauth() {

  for f in \
    /home/r36s/.Xauthority \
    /root/.Xauthority
  do

    if [ -f "$f" ]; then
      echo "$f"
      return 0
    fi

  done

  return 1
}


show_message() {

  text="$1"

  xa="$(find_xauth || true)"

  if [ -n "$xa" ]; then
    export XAUTHORITY="$xa"
  fi


  if command -v xmessage >/dev/null 2>&1; then

    xmessage \
      -display :0 \
      -center \
      -timeout 15 \
      "$text" \
      >/dev/null 2>&1 &

    return 0
  fi


  if command -v notify-send >/dev/null 2>&1; then

    notify-send \
      -t 15000 \
      "BMO USB" \
      "$text" \
      >/dev/null 2>&1 || true

    return 0
  fi


  logger \
    -t bmo-usb-ip-watch \
    "SEM FERRAMENTA DE POPUP: $text"

  return 1
}


LAST=""

while true; do

  FOUND="$(get_usb_network || true)"


  if [ -n "$FOUND" ]; then

    IFACE="${FOUND%%|*}"
    IP="${FOUND#*|}"

    CURRENT="${IFACE}|${IP}"


    if [ "$CURRENT" != "$LAST" ]; then

      LAST="$CURRENT"


      logger \
        -t bmo-usb-ip-watch \
        "Tethering USB detectado: $IFACE $IP"


      show_message \
"USB CONECTADO

INTERFACE: $IFACE

IP: $IP

SSH:
ssh r36s@$IP"

    fi

  else

    LAST=""

  fi


  sleep 2

done
