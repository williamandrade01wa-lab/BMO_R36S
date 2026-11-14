#!/usr/bin/env python3

import json
import os
import re
import shutil
import subprocess

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

HOST = "127.0.0.1"
PORT = 8087
SOUND_DIR = "/opt/bmo-sounds"


def player():
    for cmd in ["aplay", "paplay", "ffplay"]:
        p = shutil.which(cmd)

        if p:
            return cmd, p

    return None, None


def play(name):
    if not re.fullmatch(r"[A-Za-z0-9_-]+", name or ""):
        return False, "nome de som inválido"

    candidates = [
        os.path.join(SOUND_DIR, name + ".wav"),
        os.path.join(SOUND_DIR, name + ".ogg"),
        os.path.join(SOUND_DIR, name + ".mp3")
    ]

    sound = next(
        (p for p in candidates if os.path.isfile(p)),
        None
    )

    if not sound:
        return False, "arquivo de som não encontrado"

    kind, exe = player()

    if not exe:
        return False, "player de áudio não encontrado"

    if kind == "aplay":
        cmd = [exe, "-q", sound]

    elif kind == "paplay":
        cmd = [exe, sound]

    else:
        cmd = [
            exe,
            "-nodisp",
            "-autoexit",
            "-loglevel",
            "quiet",
            sound
        ]

    subprocess.Popen(
        cmd,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )

    return True, os.path.basename(sound)


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
                "service": "r36s-sound",
                "sound_dir": SOUND_DIR
            })

        else:
            self.send_json({"error": "not found"}, 404)

    def do_POST(self):
        path = urlparse(self.path).path

        if path != "/api/sound":
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
            self.send_json(
                {"ok": False, "error": "json inválido"},
                400
            )
            return

        ok, result = play(str(data.get("sound", "")))

        self.send_json(
            {
                "ok": ok,
                "sound": data.get("sound"),
                "result": result
            },
            200 if ok else 404
        )

    def log_message(self, fmt, *args):
        pass


ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
