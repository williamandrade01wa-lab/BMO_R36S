#!/usr/bin/env python3
import json, time, subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HOST = '0.0.0.0'
PORT = 8085

HTML = """<!DOCTYPE html><html><head><meta charset='utf-8'><title>LMO Console</title>
<style>body{background:#0d1117;color:#58a6ff;font-family:monospace;padding:20px}
.c{background:#161b22;border:1px solid #30363d;padding:15px;border-radius:6px;margin-bottom:12px}
button{background:#238636;color:#fff;border:none;padding:10px 16px;border-radius:6px;cursor:pointer;font-weight:bold;margin-right:8px}
button:hover{background:#2ea043}pre{background:#000;color:#3fb950;padding:10px;border-radius:6px}
h2{color:#7ee787;margin-top:0}</style>
</head><body><h2>[LMO R36S] Companion Agent Console</h2>
<div class='c'><h3>Telemetria RK3326</h3><div id='s'>Carregando...</div></div>
<div class='c'><h3>Gatilhos Instantaneos (Zero Delay)</h3>
<button onclick="act('happy')">Rosto Feliz</button>
<button onclick="act('sleep')">Modo Sono</button>
<button onclick="act('sound')">Tocar Som</button>
</div><script>
function up(){fetch('/api/status').then(r=>r.json()).then(d=>{document.getElementById('s').innerHTML='<pre>'+JSON.stringify(d,null,2)+'</pre>';});}
function act(a){fetch('/api/trigger',{method:'POST',body:JSON.stringify({action:a})}).then(r=>r.json()).then(d=>alert(d.msg));}
setInterval(up,2000);up();</script></body></html>"""

class H(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path in ['/', '/console']:
            self.send_response(200); self.send_header('Content-Type','text/html; charset=utf-8'); self.end_headers()
            self.wfile.write(HTML.encode())
        elif self.path == '/api/status':
            u = subprocess.getoutput('uptime -p')
            t = subprocess.getoutput('cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null')
            tc = f"{round(int(t)/1000,1)}C" if t.isdigit() else "N/A"
            m = subprocess.getoutput("free -m | awk '/Mem:/ {print $3 \"MB / \" $2 \"MB\"}'")
            d = {'device':'LMO R36S','status':'online','uptime':u,'temp':tc,'ram':m,'ts':time.time()}
            self.send_response(200); self.send_header('Content-Type','application/json'); self.end_headers()
            self.wfile.write(json.dumps(d).encode())
        else: self.send_response(404); self.end_headers()
    def do_POST(self):
        if self.path == '/api/trigger':
            l = int(self.headers.get('Content-Length',0))
            p = json.loads(self.rfile.read(l).decode() or '{}')
            a = p.get('action','ping')
            if a == 'sound': subprocess.run(['aplay','/opt/bmo/assets/sounds/happy.wav'], capture_output=True)
            self.send_response(200); self.send_header('Content-Type','application/json'); self.end_headers()
            self.wfile.write(json.dumps({'ok':True,'action':a,'msg':f'Gatilho [{a}] executado com ZERO delay!'}).encode())
        else: self.send_response(404); self.end_headers()
    def log_message(self,f,*a): pass

if __name__ == '__main__':
    ThreadingHTTPServer((HOST,PORT), H).serve_forever()
