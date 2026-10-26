#!/usr/bin/env python3
"""Validate the application snapshot without booting an image."""
from pathlib import Path
import hashlib
import re
import struct
import subprocess
import wave

root=Path(__file__).resolve().parents[1]
for folder in ('backend','launchers','scripts','tests'):
    for path in (root/folder).rglob('*.py'):
        compile(path.read_text(encoding='utf-8-sig'),str(path),'exec')
for name in ('index.html','index.bmo-next.html'):
    source=(root/'frontend'/name).read_text(encoding='utf-8-sig')
    for marker in ('BMO_PC_STREAM_V1','BMO_MAIN_MENU_SCROLL_V2','BMO_GAMES_FAST_NAV_V1','BMO_GAMES_VIRTUAL_WINDOW_V1','BMO_GAMES_LAZY_LOAD_V1','BMO_FAVORITES_XY_V1'):
        assert marker in source,(name,marker)
    blocks=re.findall(r'<script\b[^>]*>(.*?)</script\s*>',source,flags=re.S|re.I)
    for i,block in enumerate(blocks):
        result=subprocess.run(['node','--check'],input=block.encode('utf-8'),capture_output=True)
        if result.returncode:raise RuntimeError(f'{name} script {i}: '+result.stderr.decode())
lines=(root/'assets/sounds/SHA256SUMS').read_text().splitlines()
assert len(lines)==12
for line in lines:
    sha,name=line.split(None,1);path=root/'assets/sounds'/name.strip()
    assert hashlib.sha256(path.read_bytes()).hexdigest()==sha,name
    with wave.open(str(path),'rb') as w:assert w.getnframes()>0 and w.getsampwidth()==2
logo=(root/'assets/boot/logo.bmp').read_bytes()
assert logo[:2]==b'BM' and len(logo)==921654
assert struct.unpack_from('<iiHHI',logo,18)==(640,480,1,24,0)
assert hashlib.sha256(logo).hexdigest()==(root/'assets/boot/logo.bmp.sha256').read_text().split()[0]
print('BMO_APP_SNAPSHOT_VALIDATION_OK')
