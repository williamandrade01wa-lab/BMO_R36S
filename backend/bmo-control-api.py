#!/usr/bin/env python3

import json
import os
import re
import subprocess
import uuid
from pathlib import Path

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse
from urllib.request import Request, urlopen

HOST = "127.0.0.1"
PORT = 8088

BACKLIGHT = "/sys/class/backlight/backlight"
SOUND_API = "http://127.0.0.1:8087/api/sound"


def run(cmd, timeout=15):
    try:
        p = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )

        return (
            p.returncode == 0,
            p.stdout.strip(),
            p.stderr.strip()
        )

    except Exception as e:
        return False, "", str(e)


def read_int(path):
    try:
        with open(path) as f:
            return int(f.read().strip())
    except Exception:
        return None


def get_brightness():
    cur = read_int(f"{BACKLIGHT}/brightness")
    maxv = read_int(f"{BACKLIGHT}/max_brightness")

    pct = (
        round((cur / maxv) * 100)
        if cur is not None and maxv
        else None
    )

    return {
        "raw": cur,
        "max": maxv,
        "percent": pct
    }


def set_brightness_delta(delta_pct):
    info = get_brightness()

    if info["raw"] is None or info["max"] is None:
        return False, "backlight indisponível"

    step = round(
        info["max"] * (delta_pct / 100)
    )

    if step == 0:
        step = 1 if delta_pct > 0 else -1

    new_value = max(
        1,
        min(info["max"], info["raw"] + step)
    )

    try:
        with open(f"{BACKLIGHT}/brightness", "w") as f:
            f.write(str(new_value))

        return True, get_brightness()

    except Exception as e:
        return False, str(e)


def wifi_devices():
    ok, out, err = run([
        "nmcli",
        "-t",
        "-e",
        "no",
        "-f",
        "DEVICE,TYPE,STATE,CONNECTION",
        "device"
    ])

    result = []

    if not ok:
        return result

    for line in out.splitlines():
        parts = line.split(":", 3)

        if len(parts) < 4:
            continue

        dev, typ, state, conn = parts

        if typ == "wifi":
            result.append({
                "device": dev,
                "state": state,
                "connection": conn
            })

    return result


def wifi_scan():
    devices = wifi_devices()

    if not devices:
        return []

    dev = devices[0]["device"]

    run([
        "nmcli",
        "device",
        "wifi",
        "rescan",
        "ifname",
        dev
    ], 8)

    ok, out, err = run([
        "nmcli",
        "-t",
        "-f",
        "IN-USE,SSID,SIGNAL,FREQ,SECURITY",
        "device",
        "wifi",
        "list",
        "ifname",
        dev
    ], 10)

    if not ok:
        return []

    result = []
    seen = set()

    for line in out.splitlines():
        active, sep, rest = line.partition(":")

        if not sep or rest.count(":") < 3:
            continue

        ssid, signal, freq, security = rest.rsplit(":", 3)

        if not ssid:
            continue

        try:
            sig = int(signal)
        except Exception:
            sig = None

        match = re.search(r"\d+", freq)
        f = int(match.group()) if match else None

        band = None

        if f:
            band = "5 GHz" if f >= 4900 else "2.4 GHz"

        key = (ssid, band)
        if key in seen:
            continue
        seen.add(key)

        result.append({
            "ssid": ssid,
            "signal": sig,
            "frequency": f,
            "band": band,
            "security": security,
            "connected": active == "*"
        })

    result.sort(
        key=lambda x: (
            not x["connected"],
            -(x["signal"] or 0)
        )
    )

    return result


def reconnect_wifi():
    devices = wifi_devices()

    if not devices:
        return False, "nenhum adaptador Wi-Fi"

    dev = devices[0]["device"]

    ok, out, err = run([
        "nmcli",
        "device",
        "reapply",
        dev
    ])

    if ok:
        return True, out or "reapply OK"

    conn = devices[0].get("connection")

    if conn and conn != "--":
        ok, out, err = run([
            "nmcli",
            "connection",
            "up",
            conn
        ], 20)

        if ok:
            return True, out or "reconectado"

    return False, err or "falha ao reconectar"



def connect_wifi(ssid, password="", band=None):

    if not isinstance(ssid, str):
        return False, "SSID invalido"

    ssid = ssid.strip()

    if not ssid:
        return False, "SSID vazio"

    if len(ssid) > 64:
        return False, "SSID muito longo"


    if password is None:
        password = ""

    if not isinstance(password, str):
        return False, "senha invalida"

    if len(password) > 63:
        return False, "senha muito longa"

    if password and len(password) < 8:
        return False, "senha muito curta"

    if band not in (None, "2.4 GHz", "5 GHz"):
        return False, "banda Wi-Fi invalida"


    devices = wifi_devices()

    if not devices:
        return False, "nenhum adaptador Wi-Fi"

    dev = devices[0]["device"]


    profile = "bmo-wifi-" + uuid.uuid4().hex[:12]
    created = False

    def failure(message):
        # Never echo credentials or the private SSID in API errors.
        if password:
            message = message.replace(password, "[PASSWORD]")
        message = message.replace(ssid, "[SSID]")
        return False, message or "falha ao conectar"

    try:
        ok, out, err = run([
            "nmcli", "connection", "add", "type", "wifi",
            "ifname", dev, "con-name", profile, "ssid", ssid,
            "connection.autoconnect", "no"
        ], 15)
        if not ok:
            return failure(err or out)
        created = True

        settings = ["nmcli", "connection", "modify", profile]
        if band:
            settings += ["802-11-wireless.band", "a" if band == "5 GHz" else "bg"]
        if password:
            settings += [
                "802-11-wireless-security.key-mgmt", "wpa-psk",
                "802-11-wireless-security.psk", password
            ]
        ok, out, err = run(settings, 15)
        if not ok:
            return failure(err or out)

        ok, out, err = run([
            "nmcli", "--wait", "35", "connection", "up", profile
        ], 40)
        if not ok:
            return failure(err or out)

        run([
            "nmcli", "connection", "modify", profile,
            "connection.autoconnect", "yes"
        ], 10)
        created = False
        return True, out or "Wi-Fi conectado"
    finally:
        if created:
            run(["nmcli", "connection", "delete", profile], 10)


def sound_test():
    try:
        req = Request(
            SOUND_API,
            data=json.dumps({
                "sound": "success"
            }).encode(),
            headers={
                "Content-Type": "application/json"
            },
            method="POST"
        )

        with urlopen(req, timeout=3) as r:
            return True, json.loads(r.read())

    except Exception as e:
        return False, str(e)



def service_status():

    units = {
        "ui": "bmo-ui.service",
        "kiosk": "bmo-kiosk.service",
        "battery": "r36s-battery-api.service",
        "status": "r36s-status-api.service",
        "sound": "r36s-sound-api.service",
        "control": "bmo-control-api.service"
    }

    result = {}

    for name, unit in units.items():

        ok, out, err = run([
            "systemctl",
            "is-active",
            unit
        ])

        result[name] = (
            ok
            and out.strip() == "active"
        )

    return result


def diagnostics():
    return True, {
        "brightness": get_brightness(),
        "wifi": wifi_devices(),
        "networks": len(wifi_scan())
    }


def restart_kiosk():
    ok, out, err = run([
        "systemctl",
        "restart",
        "bmo-kiosk.service"
    ])

    return ok, out or err or "reiniciado"


def reload_ui():
    return restart_kiosk()



# BMO_AUDIO_BRIGHTNESS_SHORTCUT_V1

def get_volume():
    ok, out, err = run(
        [
            "amixer",
            "sget",
            "Master"
        ],
        timeout=5
    )

    if not ok:
        return {
            "percent": None,
            "error": err or out or "audio indisponível"
        }

    import re

    values = re.findall(
        r"\[(\d+)%\]",
        out or ""
    )

    percent = (
        int(values[0])
        if values
        else None
    )

    return {
        "percent": percent
    }


def set_volume_delta(delta):
    token = (
        f"{abs(int(delta))}%+"
        if int(delta) > 0
        else f"{abs(int(delta))}%-"
    )

    ok, out, err = run(
        [
            "amixer",
            "sset",
            "Master",
            token
        ],
        timeout=5
    )

    if not ok:
        return (
            False,
            err or out or "falha ao alterar volume"
        )

    return (
        True,
        get_volume()
    )



# BMO_SYSTEM_POWER_V1
def schedule_power(mode):

    commands = {
        "reboot": "reboot",
        "poweroff": "poweroff"
    }

    command = commands.get(mode)

    if not command:
        return False, "acao de energia invalida"

    ok, out, err = run([
        "systemd-run",
        "--on-active=2s",
        "--collect",
        "/usr/bin/systemctl",
        command
    ], 5)

    return (
        ok,
        out or err or
        f"{mode} agendado"
    )



# =========================================================
# BMO_GAMES_API_V1
# =========================================================

GAME_LAUNCHER = "/usr/local/bin/bmo-game-launcher.py"

# BMO_GAMES_GBA_SNES_API_V1
# BMO_GAMES_PSP_API_V1
# BMO_RECURSIVE_ROMS_API_V1

GAME_SYSTEMS = {
    # BMO_GBA_ZIP_V1
    "gba": {
        "extensions": {
            ".gba",
            ".zip"
        }
    },

    "snes": {
        "extensions": {
            ".sfc",
            ".smc"
        }
    },

    "psp": {
        "extensions": {
            ".iso",
            ".cso",
            ".pbp"
        }
    }
}


# BMO_GAME_COVERS_V1

GAME_COVER_ROOT = Path(
    "/opt/bmo-ui/game-covers"
)

GAME_COVER_EXTENSIONS = {
    ".png",
    ".jpg",
    ".jpeg",
    ".webp"
}


# BMO_GAME_COVER_CACHE_V1

GAME_COVER_CACHE = {}


def build_game_cover_cache(system_id):

    if system_id not in GAME_SYSTEMS:
        return {}

    cover_dir = (
        GAME_COVER_ROOT /
        system_id
    )

    index = {}

    if not cover_dir.is_dir():
        GAME_COVER_CACHE[system_id] = index
        return index

    try:
        for candidate in cover_dir.iterdir():

            if not candidate.is_file():
                continue

            if (
                candidate.suffix.lower()
                not in GAME_COVER_EXTENSIONS
            ):
                continue

            key = candidate.stem.casefold()

            if key not in index:
                index[key] = candidate.name

    except Exception:
        index = {}

    GAME_COVER_CACHE[system_id] = index

    return index


def game_cover_cache(system_id):

    cached = GAME_COVER_CACHE.get(
        system_id
    )

    if cached is None:
        cached = build_game_cover_cache(
            system_id
        )

    return cached


def find_game_cover(system_id, game_file):

    if system_id not in GAME_SYSTEMS:
        return None

    wanted_stem = (
        Path(game_file)
        .stem
        .casefold()
    )

    return game_cover_cache(
        system_id
    ).get(
        wanted_stem
    )


def games_list(system_id):
    if system_id not in GAME_SYSTEMS:
        return False, {
            "error": "sistema nao permitido"
        }

    try:
        proc = subprocess.run(
            [
                GAME_LAUNCHER,
                "list",
                system_id
            ],
            capture_output=True,
            text=True,
            timeout=5
        )

        if proc.returncode != 0:
            return False, {
                "error": proc.stderr.strip()
                         or proc.stdout.strip()
                         or "falha ao listar jogos"
            }

        payload = json.loads(proc.stdout)

        games = payload.get("games", [])

        if isinstance(games, list):

            for game in games:

                if not isinstance(game, dict):
                    continue

                game_file = (
                    game.get("file")
                    or game.get("id")
                    or ""
                )

                game["cover"] = (
                    find_game_cover(
                        system_id,
                        game_file
                    )
                )

        payload["cover_base"] = (
            "/game-covers/" +
            system_id +
            "/"
        )

        return True, payload

    except Exception as e:
        return False, {
            "error": str(e)
        }



# =========================================================
# BMO_GAME_FAVORITES_V1
# =========================================================

FAVORITES_FILE = Path(
    "/home/r36s/.config/bmo/favorites.json"
)


def favorite_game_valid(system_id, game):
    if system_id not in GAME_SYSTEMS:
        return False, "sistema nao permitido"

    if not isinstance(game, str) or not game:
        return False, "jogo invalido"

    if (
        "\\" in game
        or game.startswith("/")
        or "\x00" in game
    ):
        return False, "nome de jogo invalido"

    parts = game.split("/")

    if any(
        part in ("", ".", "..")
        for part in parts
    ):
        return False, "nome de jogo invalido"

    ext = os.path.splitext(game)[1].lower()

    if (
        ext
        not in
        GAME_SYSTEMS[system_id]["extensions"]
    ):
        return False, "extensao nao permitida"

    return True, "ok"


def favorites_load():
    try:
        if not FAVORITES_FILE.is_file():
            return []

        data = json.loads(
            FAVORITES_FILE.read_text(
                encoding="utf-8"
            )
        )

        if not isinstance(data, list):
            return []

        result = []
        seen = set()

        for item in data:
            if not isinstance(item, dict):
                continue

            system_id = item.get("system")
            game = item.get("game")

            ok, _ = favorite_game_valid(
                system_id,
                game
            )

            if not ok:
                continue

            key = (system_id, game)

            if key in seen:
                continue

            seen.add(key)

            result.append({
                "system": system_id,
                "game": game
            })

        return result

    except Exception:
        return []


def favorites_save(items):
    FAVORITES_FILE.parent.mkdir(
        parents=True,
        exist_ok=True
    )

    temp = FAVORITES_FILE.with_suffix(
        ".json.tmp"
    )

    temp.write_text(
        json.dumps(
            items,
            ensure_ascii=False,
            indent=2
        ) + "\n",
        encoding="utf-8"
    )

    os.replace(
        temp,
        FAVORITES_FILE
    )



# ============================================================
# BMO_MOONLIGHT_CONTROL_ACTION_V1
#
# Executa o launcher Moonlight em uma unidade systemd
# transitória, independente da requisição HTTP.
# ============================================================

def moonlight_launch(app):

    import os as _os
    import subprocess as _subprocess


    allowed_apps = {
        "Desktop":
            "Desktop",

        "Steam Big Picture":
            "Steam Big Picture",
    }


    app = str(
        app or ""
    ).strip()


    if app not in allowed_apps:

        return False, {
            "error":
                "invalid_moonlight_app",

            "app":
                app,
        }


    launcher = (
        "/usr/local/bin/"
        "bmo-moonlight-launch.sh"
    )


    if not _os.path.isfile(
        launcher
    ):

        return False, {
            "error":
                "moonlight_launcher_not_found",

            "launcher":
                launcher,
        }


    if not _os.access(
        launcher,
        _os.X_OK
    ):

        return False, {
            "error":
                "moonlight_launcher_not_executable",

            "launcher":
                launcher,
        }


    try:

        proc = _subprocess.run(
            [
                "systemd-run",
                "--quiet",
                "--collect",
                "--property=Type=exec",

                launcher,
                allowed_apps[app],
            ],

            stdout=
                _subprocess.PIPE,

            stderr=
                _subprocess.PIPE,

            text=True,

            timeout=10,
        )


        output = (
            (proc.stdout or "")
            +
            (
                "\n" + proc.stderr
                if proc.stderr
                else ""
            )
        ).strip()


        if proc.returncode != 0:

            return False, {
                "error":
                    "moonlight_launch_failed",

                "returncode":
                    proc.returncode,

                "output":
                    output,
            }


        return True, {
            "status":
                "launching",

            "app":
                allowed_apps[app],
        }


    except Exception as exc:

        return False, {
            "error":
                "moonlight_launch_exception",

            "message":
                str(exc),
        }



def favorite_toggle(system_id, game):
    ok, message = favorite_game_valid(
        system_id,
        game
    )

    if not ok:
        return False, message

    # Confirma tambem que a ROM realmente existe
    # usando o mesmo launcher seguro do BMO.
    check = subprocess.run(
        [
            GAME_LAUNCHER,
            "dry-run",
            system_id,
            game
        ],
        capture_output=True,
        text=True,
        timeout=5
    )

    if check.returncode != 0:
        return False, "jogo nao encontrado"

    items = favorites_load()

    key = (system_id, game)

    found = False
    result = []

    for item in items:
        item_key = (
            item["system"],
            item["game"]
        )

        if item_key == key:
            found = True
            continue

        result.append(item)

    if found:
        favorite = False

    else:
        result.append({
            "system": system_id,
            "game": game
        })

        favorite = True

    favorites_save(result)

    return True, {
        "favorite": favorite,
        "favorites": result
    }


def game_launch(system_id, game):
    if system_id not in GAME_SYSTEMS:
        return False, "sistema nao permitido"

    if not isinstance(game, str) or not game:
        return False, "jogo invalido"

    # Caminho relativo seguro.
    # Necessario para sistemas organizados em subpastas,
    # como o SNES.
    if (
        "\\" in game
        or game.startswith("/")
        or "\x00" in game
    ):
        return False, "nome de jogo invalido"

    parts = game.split("/")

    if any(
        part in ("", ".", "..")
        for part in parts
    ):
        return False, "nome de jogo invalido"

    ext = os.path.splitext(game)[1].lower()

    if ext not in GAME_SYSTEMS[system_id]["extensions"]:
        return False, "extensao nao permitida"

    # valida primeiro pelo proprio launcher
    check = subprocess.run(
        [
            GAME_LAUNCHER,
            "dry-run",
            system_id,
            game
        ],
        capture_output=True,
        text=True,
        timeout=5
    )

    if check.returncode != 0:
        return False, (
            check.stdout.strip()
            or check.stderr.strip()
            or "jogo nao encontrado"
        )

    # evita dois launches simultaneos
    active = subprocess.run(
        [
            "/usr/bin/pgrep",
            "-f",
            "bmo-game-launcher.py launch"
        ],
        capture_output=True
    )

    if active.returncode == 0:
        return False, "jogo ja em execucao"

    log = open(
        "/tmp/bmo-game-launch.log",
        "ab",
        buffering=0
    )

    subprocess.Popen(
        [
            GAME_LAUNCHER,
            "launch",
            system_id,
            game
        ],
        stdout=log,
        stderr=log,
        stdin=subprocess.DEVNULL,
        start_new_session=True
    )

    return True, "launch iniciado"


class Handler(BaseHTTPRequestHandler):

    def send_json(self, obj, code=200):
        raw = json.dumps(obj, ensure_ascii=False).encode()

        self.send_response(code)
        self.send_header(
            "Content-Type",
            "application/json; charset=utf-8"
        )
        self.send_header("Content-Length", str(len(raw)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()

        self.wfile.write(raw)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header(
            "Access-Control-Allow-Headers",
            "Content-Type"
        )
        self.send_header(
            "Access-Control-Allow-Methods",
            "GET,POST,OPTIONS"
        )
        self.end_headers()

    def do_GET(self):
        path = urlparse(self.path).path

        if path == "/health":
            self.send_json({
                "status": "ok",
                "service": "bmo-control"
            })

        elif path == "/api/control/status":
            self.send_json({
                "ok": True,
                "brightness": get_brightness(),
                "wifi": wifi_devices()
            })

        elif path == "/api/wifi/scan":
            self.send_json({
                "ok": True,
                "networks": wifi_scan()
            })

        elif path == "/api/control/diagnostics":

            ok, result = diagnostics()

            self.send_json({
                "ok": ok,
                "services": service_status(),
                "brightness": get_brightness(),
                "wifi": wifi_devices(),
                "networks": result.get("networks", 0)
                    if isinstance(result, dict)
                    else 0
            })

        elif path == "/api/favorites":
            self.send_json({
                "ok": True,
                "favorites": favorites_load()
            })

        elif path.startswith("/api/games/"):
            system_id = path[len("/api/games/"):]

            if (
                not system_id
                or "/" in system_id
                or system_id not in GAME_SYSTEMS
            ):
                self.send_json(
                    {"error": "not found"},
                    404
                )
                return

            ok, result = games_list(system_id)

            self.send_json(
                result,
                200 if ok else 500
            )

        else:
            self.send_json({"error": "not found"}, 404)

    def do_POST(self):
        path = urlparse(self.path).path

        if path != "/api/control/action":
            self.send_json({"error": "not found"}, 404)
            return

        try:
            length = int(
                self.headers.get("Content-Length", "0")
            )

            data = json.loads(
                self.rfile.read(length) or b"{}"
            )

        except Exception:
            self.send_json({
                "ok": False,
                "error": "json inválido"
            }, 400)
            return

        action = data.get("action")

        if action == "wifi_scan":
            self.send_json({
                "ok": True,
                "networks": wifi_scan()
            })
            return

        elif action == "wifi_reconnect":
            ok, result = reconnect_wifi()

        elif action == "wifi_connect":
            ok, result = connect_wifi(
                data.get("ssid"),
                data.get("password", ""),
                data.get("band")
            )

        elif action == "brightness_up":
            ok, result = set_brightness_delta(5)

        elif action == "brightness_down":
            ok, result = set_brightness_delta(-5)

        elif action == "volume_up":
            ok, result = set_volume_delta(5)

        elif action == "volume_down":
            ok, result = set_volume_delta(-5)

        elif action == "sound_test":
            ok, result = sound_test()

        elif action == "diagnostics":
            ok, result = diagnostics()

        elif action == "system_reboot":
            ok, result = schedule_power(
                "reboot"
            )

        elif action == "system_poweroff":
            ok, result = schedule_power(
                "poweroff"
            )

        elif action == "kiosk_restart":
            ok, result = restart_kiosk()

        elif action == "ui_reload":
            ok, result = reload_ui()

        elif action == "favorite_toggle":
            system_id = data.get("system", "")
            game = data.get("game", "")

            ok, result = favorite_toggle(
                system_id,
                game
            )

        elif action == "moonlight_launch":

            app = data.get(
                "app",
                ""
            )

            ok, result = moonlight_launch(
                app
            )


        elif action == "game_launch":
            system_id = data.get("system", "")
            game = data.get("game", "")

            ok, result = game_launch(
                system_id,
                game
            )

        else:
            self.send_json({
                "ok": False,
                "error": "ação inválida"
            }, 403)
            return

        self.send_json({
            "ok": ok,
            "action": action,
            "result": result
        }, 200 if ok else 500)

    def log_message(self, fmt, *args):
        pass


ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
