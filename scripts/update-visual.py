#!/usr/bin/env python3
"""Update only the BMO frontend from a Git checkout, through the existing helper."""
import argparse
import hashlib
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile

HELPER = '/usr/local/sbin/bmo-deploy-helper'
INCOMING = '/home/r36s/.bmo-deploy/incoming'
PRODUCTION = '/opt/bmo-ui/index.html'
CANDIDATE = '/opt/bmo-ui/index.bmo-next.html'
MARKERS = ('BMO_PC_STREAM_V1', 'BMO_MAIN_MENU_SCROLL_V2', 'BMO_GAMES_FAST_NAV_V1',
           'BMO_GAMES_VIRTUAL_WINDOW_V1', 'BMO_GAMES_LAZY_LOAD_V1', 'BMO_FAVORITES_XY_V1')


def run(argv, **kwargs):
    result = subprocess.run(argv, check=True, capture_output=True, **kwargs)
    return result.stdout


def frontend(data):
    text = data.decode('utf-8-sig')
    if '<html' not in text.lower() or any(marker not in text for marker in MARKERS):
        raise ValueError('Frontend incompleto ou sem os marcadores funcionais esperados')
    return hashlib.sha256(data).hexdigest()


def git_source(repo, ref):
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._/-]*', ref) or '..' in ref:
        raise ValueError('Branch invalida')
    run(['git', '-C', str(repo), 'check-ref-format', 'refs/heads/' + ref])
    origin = run(['git', '-C', str(repo), 'remote', 'get-url', 'origin']).decode().strip()
    canonical = origin[:-4] if origin.endswith('.git') else origin
    allowed = ('https://github.com/williamandrade01wa-lab/BMO_R36S',
               'git@github.com:williamandrade01wa-lab/BMO_R36S')
    if canonical not in allowed:
        raise ValueError('Origin precisa apontar para o repositorio BMO_R36S esperado')
    # Read a fetched commit; never reset, pull or modify the user's working files.
    run(['git', '-C', str(repo), 'fetch', '--no-tags', 'origin', ref])
    commit = run(['git', '-C', str(repo), 'rev-parse', 'FETCH_HEAD^{commit}']).decode().strip()
    data = run(['git', '-C', str(repo), 'show', commit + ':frontend/index.bmo-next.html'])
    return commit, data, frontend(data)


class Device:
    def __init__(self, target, identity, known_hosts=None):
        if not re.fullmatch(r'r36s@[A-Za-z0-9][A-Za-z0-9.-]*', target):
            raise ValueError('Destino esperado: r36s@IP ou r36s@hostname')
        key = Path(identity).expanduser().resolve()
        if not key.is_file():
            raise ValueError('Chave SSH nao encontrada')
        self.target = target
        self.options = ['-i', str(key), '-o', 'IdentitiesOnly=yes', '-o', 'BatchMode=yes',
                        '-o', 'ConnectTimeout=8', '-o', 'StrictHostKeyChecking=accept-new',
                        '-o', 'ServerAliveInterval=10', '-o', 'ServerAliveCountMax=3']
        if known_hosts:
            self.options += ['-o', 'UserKnownHostsFile=' + str(Path(known_hosts).resolve())]

    def ssh(self, command):
        return run(['ssh'] + self.options + [self.target, command]).decode().strip()

    def helper(self, *args):
        return self.ssh('sudo -n ' + shlex.join([HELPER, *args]))

    def digest(self, path):
        value = self.ssh('sha256sum ' + shlex.quote(path)).split()[0]
        if not re.fullmatch(r'[0-9a-f]{64}', value):
            raise ValueError('Hash remoto invalido')
        return value

    def health(self, entry):
        self.helper('status')
        for url in ('http://127.0.0.1:8090/' + entry, 'http://127.0.0.1:8088/health'):
            self.ssh('curl --fail --silent --show-error --max-time 5 --output /dev/null ' + shlex.quote(url))


def backup_id(output):
    match = re.search(r'^BACKUP_ID=(\d{8}-\d{6})$', output, re.M)
    if not match:
        raise ValueError('Helper nao retornou backup valido')
    return match.group(1)


def recover(device, backup):
    device.helper('rollback-frontend', backup)
    device.helper('restart-kiosk')
    device.health('index.html')


def candidate(device, data, sha):
    frontend(data)
    if hashlib.sha256(data).hexdigest() != sha:
        raise ValueError('Hash local divergente')
    device.helper('status')
    remote = INCOMING + '/visual-' + sha + '.html'
    backup = None
    try:
        device.ssh('mkdir -p ' + shlex.quote(INCOMING))
        with tempfile.TemporaryDirectory(prefix='bmo-visual-') as temp:
            source = Path(temp) / 'index.bmo-next.html'
            source.write_bytes(data)
            run(['scp'] + device.options + [str(source), device.target + ':' + remote])
        if device.digest(remote) != sha:
            raise ValueError('Upload divergente')
        backup = backup_id(device.helper('install-candidate', remote))
        if device.digest(CANDIDATE) != sha:
            raise ValueError('Candidate instalado divergente')
        device.helper('use-candidate')
        device.helper('restart-kiosk')
        device.health('index.bmo-next.html')
        if device.helper('kiosk-entry') != 'index.bmo-next.html':
            raise ValueError('Runtime nao ativou candidate')
        return backup
    except Exception:
        if backup:
            recover(device, backup)
        raise
    finally:
        try:
            device.ssh('rm -f -- ' + shlex.quote(remote))
        except Exception:
            pass


def promote(device, sha):
    if not re.fullmatch(r'[0-9a-f]{64}', sha):
        raise ValueError('Informe o SHA256 do candidate testado')
    if device.helper('kiosk-entry') != 'index.bmo-next.html' or device.digest(CANDIDATE) != sha:
        raise ValueError('Candidate ativo diverge do SHA testado')
    backup = backup_id(device.helper('promote-production'))
    try:
        device.helper('restart-kiosk')
        device.health('index.html')
        if device.digest(PRODUCTION) != sha or device.helper('kiosk-entry') != 'index.html':
            raise ValueError('Producao divergente')
    except Exception:
        recover(device, backup)
        raise
    return backup


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('check', 'candidate', 'promote', 'rollback'))
    parser.add_argument('--repo', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--ref', default='main')
    parser.add_argument('--target')
    parser.add_argument('--identity')
    parser.add_argument('--known-hosts')
    parser.add_argument('--tested-sha')
    parser.add_argument('--backup-id')
    args = parser.parse_args(argv)
    if args.action in ('check', 'candidate'):
        commit, data, sha = git_source(args.repo, args.ref)
        print('COMMIT=' + commit, 'SHA256=' + sha, sep='\n')
        if args.action == 'check':
            return
    if not args.target or not args.identity:
        parser.error('--target e --identity sao obrigatorios para acessar o R36S')
    device = Device(args.target, args.identity, args.known_hosts)
    if args.action == 'candidate':
        print('BACKUP_ID=' + candidate(device, data, sha))
        print('BMO_VISUAL_CANDIDATE_OK - teste no aparelho antes de promote')
    elif args.action == 'promote':
        if not args.tested_sha:
            parser.error('promote exige --tested-sha do candidate validado fisicamente')
        print('BACKUP_ID=' + promote(device, args.tested_sha))
        print('BMO_VISUAL_PROMOTE_OK')
    else:
        if not re.fullmatch(r'\d{8}-\d{6}', args.backup_id or ''):
            parser.error('rollback exige --backup-id no formato AAAAMMDD-HHMMSS')
        recover(device, args.backup_id)
        print('BMO_VISUAL_ROLLBACK_OK')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        print('ERRO: ' + str(error), file=sys.stderr)
        sys.exit(1)
