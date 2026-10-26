#!/usr/bin/env python3
"""Validate PureLight runtime sources before mounting/building an image."""
from pathlib import Path
import hashlib,json,struct
root=Path(__file__).resolve().parents[2]
def manifest(base,path):
    count=0
    for line in path.read_text().splitlines():
        if not line.strip() or line.startswith('#'):continue
        sha,name=line.split(None,1);name=name.strip()
        assert not Path(name).is_absolute() and '..' not in Path(name).parts,name
        assert hashlib.sha256((base/name).read_bytes()).hexdigest()==sha,name
        count+=1
    return count
assert manifest(root/'assets/sounds',root/'assets/sounds/SHA256SUMS')==12
manifest(root,root/'install/manifests/system-config.sha256')
policy=json.loads((root/'install/system/chromium/bmo-kiosk.json').read_text())
assert policy['TranslateEnabled'] is False
logo=(root/'assets/boot/logo.bmp').read_bytes()
assert len(logo)==921654 and struct.unpack_from('<iiHHI',logo,18)==(640,480,1,24,0)
manifest(root/'assets/boot',root/'assets/boot/logo.bmp.sha256')
wizard=(root/'scripts/windows/BMO-Preparar-Cartao.ps1').read_text(encoding='utf-8-sig')
assert "version='0.2.1'" in wizard and 'Ensure-BmoDirectory' in wizard
installer=(root/'install/bmo-install.sh').read_text()
assert 'assets/sounds/$SOUND' in installer and 'apply_copy' in installer
builder=(root/'install/light/build-light-image.sh').read_text()
assert 'assets/sounds' in builder and 'install/system' in builder
assert 'BMO_LIGHT_VERSION=0.1.0-beta' in builder
print('PURELIGHT_UPDATED_SOURCE_CONTRACT_OK')
