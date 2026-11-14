#!/usr/bin/env python3
"""Servidor local dos portais BMO Preview e BMO Gamepad (Maestri), porta 8360.

- GET /                 -> frontend/index.bmo-next.html com gamepad-inject.js injetado (arquivo do app intacto)
- GET /gamepad.html     -> emulador de gamepad
- GET /gamepad-state    -> {ts, buttons[17], axes[4]} lido pelo gamepad-inject.js
- POST /gamepad         -> {"type":"press"|"release","btn":N}
- POST /gamepad/tap     -> {"btn":N} (press + release apos 150 ms)
Somente 127.0.0.1. Uso: python -I scripts/preview-server.py [porta]
"""
import json
import sys
import threading
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "frontend"
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8360
N_BTN, N_AXES = 17, 4
LOCK = threading.Lock()
STATE = {"ts": 0, "buttons": [{"pressed": False, "value": 0} for _ in range(N_BTN)], "axes": [0] * N_AXES}


def set_btn(btn, pressed):
    if 0 <= btn < N_BTN:
        with LOCK:
            STATE["buttons"][btn] = {"pressed": pressed, "value": 1 if pressed else 0}
            STATE["ts"] = int(time.time() * 1000)


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=str(ROOT), **k)

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")

    def _json(self, obj, code=200):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self._cors()
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        path = self.path.split("?")[0]
        if path == "/gamepad-state":
            with LOCK:
                return self._json(STATE)
        if path in ("/", "/index.html", "/preview"):
            html = (ROOT / "index.bmo-next.html").read_text(encoding="utf-8")
            ver = int((ROOT / "gamepad-inject.js").stat().st_mtime)  # evita cache do webview
            tag = f'<script src="/gamepad-inject.js?v={ver}"></script>'
            html = html.replace("</head>", tag + "</head>", 1) if "</head>" in html else tag + html
            body = html.encode()
            self.send_response(200)
            self._cors()
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            return self.wfile.write(body)
        return super().do_GET()

    def do_POST(self):
        path = self.path.split("?")[0]
        try:
            data = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0)) or 0) or b"{}")
            btn = int(data.get("btn", -1))
        except (ValueError, TypeError):
            return self._json({"ok": False, "error": "json/btn invalido"}, 400)
        if path == "/gamepad":
            kind = data.get("type")
            if kind not in ("press", "release"):
                return self._json({"ok": False, "error": "type invalido"}, 400)
            set_btn(btn, kind == "press")
        elif path == "/gamepad/tap":
            set_btn(btn, True)
            threading.Timer(0.15, set_btn, (btn, False)).start()
        else:
            return self._json({"ok": False, "error": "rota"}, 404)
        return self._json({"ok": True})

    def log_message(self, *a):
        pass


if __name__ == "__main__":
    srv = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"BMO Preview/Gamepad em http://127.0.0.1:{PORT}/ (frontend: {ROOT})", flush=True)
    srv.serve_forever()
