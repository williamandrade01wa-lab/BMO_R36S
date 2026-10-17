#!/usr/bin/env python3

import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

HOST = "127.0.0.1"
PORT = 8083


def read_text(path):
    try:
        with open(path, "r") as f:
            return f.read().strip()
    except Exception:
        return None


def read_int(path):
    v = read_text(path)
    try:
        return int(v)
    except Exception:
        return None


def find_battery():
    base = "/sys/class/power_supply"

    try:
        entries = os.listdir(base)
    except Exception:
        return None

    preferred = []

    for name in entries:
        p = os.path.join(base, name)
        typ = read_text(os.path.join(p, "type"))

        if typ == "Battery":
            preferred.insert(0, p)
        elif os.path.exists(os.path.join(p, "capacity")):
            preferred.append(p)

    return preferred[0] if preferred else None


def battery_data():
    base = find_battery()

    if not base:
        return {
            "percent": None,
            "charging": False,
            "state": "unknown",
            "voltage": None,
            "current_ma": None,
            "charge_now": None,
            "charge_full": None
        }

    percent = read_int(os.path.join(base, "capacity"))
    current = read_int(os.path.join(base, "current_now"))

    if current is None:
        current = read_int(
            os.path.join(base, "current_avg")
        )

    voltage = read_int(os.path.join(base, "voltage_now"))

    if voltage is None:
        voltage = read_int(
            os.path.join(base, "voltage_avg")
        )

    charge_now = read_int(os.path.join(base, "charge_now"))
    charge_full = read_int(os.path.join(base, "charge_full"))

    if percent is None and charge_now is not None and charge_full:
        percent = round((charge_now / charge_full) * 100)

    #
    # Regra que usávamos no BMO:
    # > +50000 uA  -> charging
    # < -50000 uA  -> discharging
    # intervalo    -> idle
    #
    if current is not None:
        if current > 50000:
            state = "charging"
        elif current < -50000:
            state = "discharging"
        else:
            state = "idle"
    else:
        status = (read_text(os.path.join(base, "status")) or "").lower()

        if "charg" in status and "discharg" not in status:
            state = "charging"
        elif "discharg" in status:
            state = "discharging"
        else:
            state = "idle"

    return {
        "percent": percent,
        "charging": state == "charging",
        "state": state,
        "voltage": round(voltage / 1000000, 3)
                   if voltage is not None else None,
        "current_ma": round(current / 1000, 1)
                      if current is not None else None,
        "charge_now": charge_now,
        "charge_full": charge_full
    }


class Handler(BaseHTTPRequestHandler):

    def send_json(self, obj, status=200):
        data = json.dumps(obj, ensure_ascii=False).encode()

        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()

        self.wfile.write(data)

    def do_GET(self):
        path = urlparse(self.path).path

        if path == "/api/battery":
            self.send_json(battery_data())
        elif path == "/health":
            self.send_json({"status": "ok", "service": "battery"})
        else:
            self.send_json({"error": "not found"}, 404)

    def log_message(self, fmt, *args):
        pass


ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
