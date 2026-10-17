#!/bin/bash

export DISPLAY=:0

for i in $(seq 1 100); do
    xdpyinfo >/dev/null 2>&1 && break
    sleep 0.1
done

xhost +SI:localuser:r36s >/dev/null 2>&1 || true
xsetroot -solid black >/dev/null 2>&1 || true
