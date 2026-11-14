#!/usr/bin/env python3
"""Behavior checks for Wi-Fi scan and WPA connection without a radio."""

from pathlib import Path
from types import ModuleType
from unittest.mock import patch

source = Path(__file__).resolve().parents[1] / "backend" / "bmo-control-api.py"
api = ModuleType("bmo_control_api")
code = source.read_text(encoding="utf-8")
start_server = "ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()"
assert code.count(start_server) == 1
exec(compile(code.replace(start_server, ""), str(source), "exec"), api.__dict__)

device = [{"device": "wlan-test", "state": "connected", "connection": "old"}]

with patch.object(api, "wifi_devices", return_value=device):
    def scan_run(command, timeout=15):
        if "rescan" in command:
            return True, "", ""
        return True, (
            "*:Shared:60:2462 MHz:WPA2\n"
            ":Shared:90:5180 MHz:WPA2\n"
            ":Another:40:5500 MHz:WPA2"
        ), ""

    with patch.object(api, "run", side_effect=scan_run):
        networks = api.wifi_scan()
    assert len(networks) == 3
    assert {(n["ssid"], n["band"]) for n in networks} == {
        ("Shared", "2.4 GHz"), ("Shared", "5 GHz"), ("Another", "5 GHz")
    }

    commands = []

    def success_run(command, timeout=15):
        commands.append(command)
        return True, "ok", ""

    with patch.object(api, "run", side_effect=success_run):
        ok, _ = api.connect_wifi("Test 5G", "sample123!", "5 GHz")
    assert ok
    assert any("802-11-wireless.band" in c and "a" in c for c in commands)
    assert any("802-11-wireless-security.key-mgmt" in c and "wpa-psk" in c for c in commands)
    assert any("802-11-wireless-security.psk" in c for c in commands)
    assert any("connection.autoconnect" in c and "yes" in c for c in commands)
    assert not any("delete" in c for c in commands)

    commands.clear()

    def failed_up(command, timeout=15):
        commands.append(command)
        if "up" in command:
            return False, "", "Test 5G: sample123! failed"
        return True, "ok", ""

    with patch.object(api, "run", side_effect=failed_up):
        ok, error = api.connect_wifi("Test 5G", "sample123!", "5 GHz")
    assert not ok
    assert "Test 5G" not in error and "sample123!" not in error
    assert any("delete" in c for c in commands)

print("BMO_WIFI_CONTROL_OK")
