#!/usr/bin/env python3

import os
import select
import struct
import subprocess
import signal
import sys

EV_KEY = 1

KEY_VOLUMEDOWN = 114
KEY_VOLUMEUP   = 115

BTN_MODE = 316

VOL_DEVICE = "/dev/input/event2"
PAD_DEVICE = "/dev/input/event3"

BACKLIGHT = "/sys/class/backlight/backlight"

running = True
fn_pressed = False

EVENT_FORMAT = "llHHi"
EVENT_SIZE = struct.calcsize(EVENT_FORMAT)


def stop(*_):
    global running
    running = False


signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)


def volume(delta):
    if delta > 0:
        value = "5%+"
    else:
        value = "5%-"

    subprocess.run(
        [
            "/usr/bin/amixer",
            "-q",
            "-c",
            "0",
            "sset",
            "Master",
            value,
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )


def brightness(delta):
    try:
        max_path = os.path.join(
            BACKLIGHT,
            "max_brightness"
        )

        cur_path = os.path.join(
            BACKLIGHT,
            "brightness"
        )

        with open(max_path) as f:
            maximum = int(f.read().strip())

        with open(cur_path) as f:
            current = int(f.read().strip())

        step = max(
            1,
            round(maximum * 0.05)
        )

        if delta < 0:
            step = -step

        new_value = max(
            1,
            min(
                maximum,
                current + step
            )
        )

        with open(cur_path, "w") as f:
            f.write(str(new_value))

    except Exception:
        pass


def read_event(fd):
    data = os.read(fd, EVENT_SIZE)

    if len(data) != EVENT_SIZE:
        return None

    sec, usec, ev_type, code, value = \
        struct.unpack(EVENT_FORMAT, data)

    return ev_type, code, value


def main():
    global fn_pressed

    vol_fd = os.open(
        VOL_DEVICE,
        os.O_RDONLY | os.O_NONBLOCK
    )

    pad_fd = os.open(
        PAD_DEVICE,
        os.O_RDONLY | os.O_NONBLOCK
    )

    try:
        while running:

            ready, _, _ = select.select(
                [vol_fd, pad_fd],
                [],
                [],
                0.25
            )

            for fd in ready:

                try:
                    event = read_event(fd)
                except BlockingIOError:
                    continue

                if not event:
                    continue

                ev_type, code, value = event

                if ev_type != EV_KEY:
                    continue

                # FN / BTN_MODE
                if fd == pad_fd and code == BTN_MODE:
                    fn_pressed = value != 0
                    continue

                # Volume físico
                if fd == vol_fd and value in (1, 2):

                    if code == KEY_VOLUMEUP:

                        if fn_pressed:
                            brightness(+1)
                        else:
                            volume(+1)

                    elif code == KEY_VOLUMEDOWN:

                        if fn_pressed:
                            brightness(-1)
                        else:
                            volume(-1)

    finally:
        os.close(vol_fd)
        os.close(pad_fd)


if __name__ == "__main__":
    main()
