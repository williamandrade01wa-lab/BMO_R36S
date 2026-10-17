#!/bin/bash

export DISPLAY=:0
export HOME=/home/r36s

BMO_KIOSK_DEFAULT="/etc/default/bmo-kiosk"
BMO_UI_ENTRY="index.html"

if [ -r "$BMO_KIOSK_DEFAULT" ]; then
    # shellcheck disable=SC1090
    . "$BMO_KIOSK_DEFAULT"
fi

case "${BMO_UI_ENTRY:-index.html}" in
    index.html|index.bmo-next.html)
        ;;
    *)
        BMO_UI_ENTRY="index.html"
        ;;
esac

for i in $(seq 1 100); do
    xdpyinfo >/dev/null 2>&1 && break
    sleep 0.1
done

xset s off >/dev/null 2>&1 || true
xset -dpms >/dev/null 2>&1 || true
xset s noblank >/dev/null 2>&1 || true

unclutter -idle 0.1 -root >/dev/null 2>&1 &

mkdir -p /home/r36s/.config/r36s-kiosk

exec dbus-run-session -- chromium --remote-debugging-address=127.0.0.1 --remote-debugging-port=9223 \
  --ozone-platform=x11 \
  --kiosk \
  --no-sandbox \
  --disable-dev-shm-usage \
  --disable-extensions \
  --no-first-run \
  --no-default-browser-check \
  --disable-search-engine-choice-screen \
  --lang=pt-BR \
  --accept-lang=pt-BR,pt \
  --disable-features=Translate,TranslateUI \
  --disable-translate \
  --disable-session-crashed-bubble \
  --disable-component-update \
  --disable-background-networking \
  --disable-sync \
  --window-size=640,480 \
  --window-position=0,0 \
  --user-data-dir=/home/r36s/.config/r36s-kiosk \
  "http://127.0.0.1:8090/${BMO_UI_ENTRY}?v=$(date +%s)"
