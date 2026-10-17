#!/usr/bin/env python3

# BMO_MOONLIGHT_EXIT_HOTKEY_V1

import os
import select
import signal
import struct
import subprocess
import time

EV_KEY = 1

BTN_SELECT = 314
BTN_MODE   = 316

PAD_DEVICE = "/dev/input/event3"

EVENT_FORMAT = "llHHi"
EVENT_SIZE = struct.calcsize(EVENT_FORMAT)

running = True
fn_pressed = False


def stop(*_):
    global running
    running = False


signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)


def terminate_moonlight():

    # Mata apenas processos Moonlight do usuario r36s.
    subprocess.run(
        [
            "/usr/bin/pkill",
            "-TERM",
            "-u",
            "r36s",
            "-f",
            r"(^|/)(moonlight|moonlight-qt)( |$)"
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False
    )


def read_event(fd):

    data = os.read(
        fd,
        EVENT_SIZE
    )

    if len(data) != EVENT_SIZE:
        return None

    sec, usec, ev_type, code, value = \
        struct.unpack(
            EVENT_FORMAT,
            data
        )

    return (
        ev_type,
        code,
        value
    )


def main():

    global fn_pressed

    fd = os.open(
        PAD_DEVICE,
        os.O_RDONLY |
        os.O_NONBLOCK
    )

    try:

        while running:

            ready, _, _ = select.select(
                [fd],
                [],
                [],
                0.20
            )

            if not ready:
                continue

            try:
                event = read_event(fd)
            except BlockingIOError:
                continue

            if not event:
                continue

            ev_type, code, value = event

            if ev_type != EV_KEY:
                continue


            # FN
            if code == BTN_MODE:

                fn_pressed = (
                    value != 0
                )

                continue


            # FN + SELECT
            if (
                code == BTN_SELECT
                and value == 1
                and fn_pressed
            ):

                terminate_moonlight()

                time.sleep(0.2)

                break

    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
