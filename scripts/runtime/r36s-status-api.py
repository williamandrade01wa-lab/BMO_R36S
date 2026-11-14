#!/usr/bin/env python3

import json
import os
import shutil
import socket
import subprocess
import time

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse
from urllib.request import urlopen

HOST = "127.0.0.1"
PORT = 8086

BACKLIGHT = "/sys/class/backlight/backlight"


def read_text(path):
    try:
        with open(path, "r") as f:
            return f.read().strip()
    except Exception:
        return None


def read_int(path):
    try:
        return int(read_text(path))
    except Exception:
        return None


def run(cmd, timeout=4):
    try:
        p = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        return p.returncode == 0, p.stdout.strip()
    except Exception:
        return False, ""


def battery():
    try:
        with urlopen(
            "http://127.0.0.1:8083/api/battery",
            timeout=2
        ) as r:
            return json.loads(r.read())
    except Exception:
        return {
            "percent": None,
            "charging": False,
            "state": "unknown",
            "voltage": None,
            "current_ma": None,
            "charge_now": None,
            "charge_full": None
        }


def memory():
    values = {}

    try:
        with open("/proc/meminfo") as f:
            for line in f:
                k, v = line.split(":", 1)
                values[k] = int(v.strip().split()[0])
    except Exception:
        pass

    total = values.get("MemTotal", 0)
    available = values.get("MemAvailable", 0)
    used = max(0, total - available)

    total_mb = round(total / 1024, 1)
    used_mb = round(used / 1024, 1)
    percent = round((used / total) * 100, 1) if total else None

    return {
        "total_mb": total_mb,
        "used_mb": used_mb,
        "percent": percent
    }


def cpu_temp():
    import glob

    candidates = []

    for zone in glob.glob(
        "/sys/class/thermal/thermal_zone*"
    ):
        raw = read_int(
            os.path.join(zone, "temp")
        )

        if raw is None:
            continue

        value = (
            raw / 1000
            if abs(raw) > 1000
            else raw
        )

        if not (0 < value < 120):
            continue

        name = (
            read_text(
                os.path.join(zone, "type")
            )
            or ""
        )

        candidates.append(
            (name.lower(), value)
        )

    #
    # No R36S queremos preferencialmente
    # a temperatura do SoC.
    #
    for name, value in candidates:
        if "soc" in name:
            return round(value, 1)

    for name, value in candidates:
        if "cpu" in name:
            return round(value, 1)

    return (
        round(candidates[0][1], 1)
        if candidates
        else None
    )


def uptime_seconds():
    try:
        return int(float(read_text("/proc/uptime").split()[0]))
    except Exception:
        return 0


def format_uptime(seconds):
    days = seconds // 86400
    hours = (seconds % 86400) // 3600
    minutes = (seconds % 3600) // 60

    if days:
        return f"{days}d {hours}h {minutes}m"

    if hours:
        return f"{hours}h {minutes}m"

    return f"{minutes}m"


def network():
    ok, out = run([
        "nmcli",
        "-t",
        "-f",
        "DEVICE,TYPE,STATE,CONNECTION",
        "device"
    ])

    if not ok:
        return {
            "connected": False,
            "ssid": None,
            "signal": None,
            "ip": None,
            "interface": None
        }

    device = None
    connection = None

    for line in out.splitlines():
        parts = line.split(":", 3)

        if len(parts) < 4:
            continue

        dev, typ, state, conn = parts

        if typ == "wifi" and state == "connected":
            device = dev
            connection = conn
            break

    if not device:
        return {
            "connected": False,
            "ssid": None,
            "signal": None,
            "ip": None,
            "interface": None
        }

    _, ipout = run([
        "nmcli",
        "-g",
        "IP4.ADDRESS",
        "device",
        "show",
        device
    ])

    ip = ipout.split("/")[0] if ipout else None

    ok_wifi, wifiout = run([
        "nmcli",
        "-t",
        "-f",
        "IN-USE,SSID,SIGNAL",
        "device",
        "wifi",
        "list",
        "ifname",
        device
    ])

    ssid = connection
    signal = None

    if ok_wifi:
        for line in wifiout.splitlines():
            line = line.strip()

            if not line.startswith("*:"):
                continue

            parts = line.split(":", 2)

            if len(parts) == 3:
                if parts[1]:
                    ssid = parts[1]

                try:
                    signal = int(parts[2].strip())
                except Exception:
                    signal = None

            break

    #
    # Fallback para adaptadores Realtek do R36S.
    # /proc/net/wireless normalmente apresenta:
    # interface: status quality level noise ...
    #
    if signal is None:
        try:
            with open("/proc/net/wireless") as f:
                for line in f:
                    if ":" not in line:
                        continue

                    iface, values = line.split(":", 1)

                    if iface.strip() != device:
                        continue

                    cols = values.split()

                    if len(cols) >= 2:
                        quality = float(
                            cols[1].rstrip(".")
                        )

                        #
                        # Linux Wireless Extensions:
                        # qualidade típica é 0..70
                        #
                        signal = round(
                            max(
                                0,
                                min(
                                    100,
                                    (quality / 70.0) * 100
                                )
                            )
                        )

                    break

        except Exception:
            pass

    return {
        "connected": True,
        "ssid": ssid,
        "signal": signal,
        "ip": ip,
        "interface": device
    }


def brightness():
    cur = read_int(os.path.join(BACKLIGHT, "brightness"))
    actual = read_int(os.path.join(BACKLIGHT, "actual_brightness"))
    maxv = read_int(os.path.join(BACKLIGHT, "max_brightness"))

    return cur if cur is not None else actual, maxv


def status():
    bat = battery()
    net = network()
    mem = memory()

    up = uptime_seconds()
    temp = cpu_temp()

    bcur, bmax = brightness()

    disk = shutil.disk_usage("/")
    disk_pct = round((disk.used / disk.total) * 100, 1)

    try:
        l1, l5, l15 = os.getloadavg()
    except Exception:
        l1 = l5 = l15 = 0

    result = {
        "device": "R36S",
        "hostname": socket.gethostname(),

        "battery": bat,

        "network": net,

        "system": {
            "uptime_seconds": up,
            "temperature_c": temp,
            "memory": mem,
            "load": {
                "load_1m": round(l1, 2),
                "load_5m": round(l5, 2),
                "load_15m": round(l15, 2)
            }
        },

        "temperature_c": temp,
        "ip": net.get("ip"),

        "brightness": bcur,
        "max_brightness": bmax,

        "battery_percent": bat.get("percent"),
        "battery_status": bat.get("state"),
        "battery_voltage_v": bat.get("voltage"),

        "ram_used_mb": mem.get("used_mb"),
        "ram_total_mb": mem.get("total_mb"),

        "disk_percent": disk_pct,

        "uptime": format_uptime(up),
        "load": f"{l1:.2f}",

        "timestamp": time.time()
    }

    return result


class Handler(BaseHTTPRequestHandler):

    def send_json(self, obj, status_code=200):
        raw = json.dumps(obj, ensure_ascii=False).encode()

        self.send_response(status_code)
        self.send_header(
            "Content-Type",
            "application/json; charset=utf-8"
        )
        self.send_header("Content-Length", str(len(raw)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()

        self.wfile.write(raw)

    def do_GET(self):
        path = urlparse(self.path).path

        if path == "/api/status":
            self.send_json(status())

        elif path == "/health":
            self.send_json({
                "status": "ok",
                "service": "r36s-status"
            })

        else:
            self.send_json({"error": "not found"}, 404)

    def log_message(self, fmt, *args):
        pass


ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
