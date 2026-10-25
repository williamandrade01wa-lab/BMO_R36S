#!/usr/bin/env bash
# BMO Linux Base v0.2: offline welcome/status update.
# Does not apply firstboot, change passwords, or reconnect the network.
set -euo pipefail
[ "$EUID" -eq 0 ] || { echo "Use sudo para executar este arquivo."; exit 1; }
ROOT="${BMO_UPDATE_TEST_ROOT:-/}"
ROOT="$(realpath -e "$ROOT")"
[ -f "$ROOT/etc/bmo/base-version.env" ] && [ -f "$ROOT/usr/local/sbin/bmo-firstboot" ] || {
 echo "Esta atualizacao exige BMO Linux Base instalada."; exit 1;
}
WORK="$(mktemp -d)"
trap 'rm -rf -- "$WORK"' EXIT
cat > "$WORK/bmo-firstboot" <<'BMO_FIRSTBOOT_SOURCE_EOF'
#!/usr/bin/env python3
import ipaddress, os, re, shutil, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path
BASE_VERSION='0.2.0'; BOOT_CANDIDATES=[Path('/boot/u-boot'),Path('/boot')]; DEFAULT_CONFIG=Path('/usr/share/bmo/BMO-FIRSTBOOT.txt'); STATE_DIR=Path('/var/lib/bmo'); STATE_FILE=STATE_DIR/'firstboot-state.env'; MARKER=STATE_DIR/'firstboot.done'; LOG_FILE=Path('/var/log/bmo-firstboot.log'); SENTINELS={'','CHANGE_ME','__APPLIED__'}
DEFAULTS={'USER_NAME':'r36s','USER_PASSWORD':'r36s','ROOT_PASSWORD':'LOCKED','HOSTNAME':'bmo-r36s','TIMEZONE':'America/Sao_Paulo','LOCALE':'pt_BR.UTF-8','NETWORK_ENABLED':'yes','WIFI_ENABLED':'no','WIFI_SSID':'','WIFI_SECURITY':'wpa-psk','WIFI_PASSWORD':'','WIFI_HIDDEN':'no','WIFI_AUTOCONNECT':'yes','WIFI_IPV4_MODE':'dhcp','WIFI_STATIC_ADDRESS':'','WIFI_STATIC_GATEWAY':'','WIFI_STATIC_DNS':'','WIRED_ENABLED':'yes','WIRED_AUTOCONNECT':'yes','WIRED_IPV4_MODE':'dhcp','WIRED_STATIC_ADDRESS':'','WIRED_STATIC_GATEWAY':'','WIRED_STATIC_DNS':'','SSH_ENABLED':'no','SSH_PASSWORD_AUTH':'yes','SSH_PORT':'22','MDNS_ENABLED':'yes','BMO_AUTO_INSTALL':'no'}
ALIASES={'REDE_WIFI':'WIFI_SSID','SENHA_WIFI':'WIFI_PASSWORD','SENHA_USUARIO':'USER_PASSWORD','ACESSO_REMOTO':'SSH_ENABLED'}
ALLOWED_KEYS=set(DEFAULTS)|set(ALIASES); SECRET_KEYS={'USER_PASSWORD','ROOT_PASSWORD','WIFI_PASSWORD','SENHA_WIFI','SENHA_USUARIO'}
def log(m):
 l=f'{datetime.now(timezone.utc).isoformat()} {m}'; print(l)
 try:
  LOG_FILE.parent.mkdir(parents=True,exist_ok=True); open(LOG_FILE,'a',encoding='utf-8').write(l+'\n')
 except OSError: pass
def run(a,check=True,input_text=None): return subprocess.run(a,check=check,text=True,input=input_text,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
def yes(v): return str(v).strip().lower() in {'1','yes','true','on','sim','s'}
def boot_dir():
 for p in BOOT_CANDIDATES:
  if p.is_dir(): return p
 return BOOT_CANDIDATES[0]
def config_path(): return boot_dir()/'BMO-FIRSTBOOT.txt'
def ensure_boot_config():
 p=config_path()
 if not p.exists() and DEFAULT_CONFIG.exists(): p.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(DEFAULT_CONFIG,p)
 return p
def parse_config(p):
 c=dict(DEFAULTS); seen=set()
 if not p.exists(): return c
 for n,r in enumerate(p.read_text(encoding='utf-8-sig',errors='replace').splitlines(),1):
  line=r.rstrip('\r\n')
  if not line.strip() or line.lstrip().startswith('#'): continue
  if '=' not in line: raise ValueError(f'linha {n}: esperado CHAVE=VALOR')
  k,v=line.split('=',1); k=k.strip(); v=v.strip()
  if k not in ALLOWED_KEYS: raise ValueError(f'linha {n}: chave desconhecida: {k}')
  dest=ALIASES.get(k,k)
  if dest in seen: raise ValueError(f'linha {n}: configuracao repetida: {dest}')
  seen.add(dest); c[dest]=v
 if c['WIFI_SSID'] and 'WIFI_ENABLED' not in seen: c['WIFI_ENABLED']='yes'
 return c
def validate_ipv4(mode,address,gateway,label):
 if mode not in {'dhcp','static'}: raise ValueError(f'{label}_IPV4_MODE invalido')
 if mode=='static':
  if not address or not gateway: raise ValueError(f'{label}: endereco e gateway obrigatorios')
  if ipaddress.ip_interface(address).version!=4 or ipaddress.ip_address(gateway).version!=4: raise ValueError(f'{label}: apenas IPv4')
def validate(c):
 if not re.fullmatch(r'[a-z_][a-z0-9_-]{0,31}',c['USER_NAME']): raise ValueError('USER_NAME invalido')
 if not re.fullmatch(r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?',c['HOSTNAME']): raise ValueError('HOSTNAME invalido')
 if c['WIFI_SECURITY'] not in {'wpa-psk','open'}: raise ValueError('WIFI_SECURITY invalido')
 validate_ipv4(c['WIFI_IPV4_MODE'],c['WIFI_STATIC_ADDRESS'],c['WIFI_STATIC_GATEWAY'],'WIFI'); validate_ipv4(c['WIRED_IPV4_MODE'],c['WIRED_STATIC_ADDRESS'],c['WIRED_STATIC_GATEWAY'],'WIRED')
 port=int(c['SSH_PORT']);
 if port<1 or port>65535: raise ValueError('SSH_PORT invalido')
 if not (Path('/usr/share/zoneinfo')/c['TIMEZONE']).exists(): raise ValueError('TIMEZONE invalido')
 if yes(c['WIFI_ENABLED']) and not c['WIFI_SSID']: raise ValueError('WIFI_SSID obrigatorio')
 if c['WIFI_SECURITY']=='wpa-psk' and yes(c['WIFI_ENABLED']) and c['WIFI_PASSWORD'] not in SENTINELS and len(c['WIFI_PASSWORD'])<8: raise ValueError('WIFI_PASSWORD WPA precisa ter ao menos 8 caracteres')
def read_state():
 s={}
 if STATE_FILE.exists():
  for l in STATE_FILE.read_text().splitlines():
   if '=' in l: k,v=l.split('=',1); s[k.strip()]=v.strip()
 return s
def write_state(s): STATE_DIR.mkdir(parents=True,exist_ok=True); STATE_FILE.write_text('\n'.join(f'{k}={v}' for k,v in sorted(s.items()))+'\n'); os.chmod(STATE_FILE,0o600)
def ensure_user(c,s):
 import pwd
 u=c['USER_NAME']
 try:
  pw=pwd.getpwnam(u)
  if pw.pw_uid!=1000: raise RuntimeError(f'usuario {u} existe mas UID nao e 1000')
 except KeyError:
  try: raise RuntimeError(f'UID 1000 ja pertence a {pwd.getpwuid(1000).pw_name}')
  except KeyError: run(['useradd','--uid','1000','--user-group','--create-home','--shell','/bin/bash',u])
 for g in ['sudo','netdev','audio','video','disk','tty','users','games','dialout','plugdev','input','bluetooth','systemd-journal','ssh','render']:
  if run(['getent','group',g],check=False).returncode==0: run(['usermod','-aG',g,u])
 for p in [Path(f'/home/{u}/ROMs/gba'),Path(f'/home/{u}/ROMs/snes'),Path(f'/home/{u}/ROMs/psp')]: p.mkdir(parents=True,exist_ok=True); shutil.chown(p,user=u,group=u)
 p=c['USER_PASSWORD']
 if p not in SENTINELS: run(['chpasswd'],input_text=f'{u}:{p}\n'); s['USER_PASSWORD_DEFAULT']='yes' if p=='r36s' else 'no'
 elif 'USER_PASSWORD_DEFAULT' not in s: s['USER_PASSWORD_DEFAULT']='yes'
 r=c['ROOT_PASSWORD']
 if r=='LOCKED': run(['passwd','-l','root'],check=False)
 elif r not in SENTINELS: run(['chpasswd'],input_text=f'root:{r}\n')
 return u
def identity(c):
 Path('/etc/hostname').write_text(c['HOSTNAME']+'\n'); run(['hostnamectl','set-hostname',c['HOSTNAME']],check=False); run(['timedatectl','set-timezone',c['TIMEZONE']],check=False)
 lg=Path('/etc/locale.gen'); line=f"{c['LOCALE']} UTF-8"
 if lg.exists():
  a=[]; found=False
  for x in lg.read_text(errors='replace').splitlines():
   if x.lstrip('# ').startswith(c['LOCALE']+' '): a.append(line); found=True
   else: a.append(x)
  if not found: a.append(line)
  lg.write_text('\n'.join(a)+'\n'); run(['locale-gen',c['LOCALE']],check=False)
 Path('/etc/default/locale').write_text(f"LANG={c['LOCALE']}\n")
def nm_exists(n): return run(['nmcli','-g','NAME','connection','show',n],check=False).returncode==0
def nm_get(n,f):
 r=run(['nmcli','-g',f,'connection','show',n],check=False); return r.stdout.strip() if r.returncode==0 else ''
def ipv4(n,mode,address,gateway,dns):
 if mode=='dhcp': run(['nmcli','connection','modify',n,'ipv4.method','auto','ipv4.addresses','','ipv4.gateway','','ipv4.dns',''])
 else: run(['nmcli','connection','modify',n,'ipv4.method','manual','ipv4.addresses',address,'ipv4.gateway',gateway,'ipv4.dns',dns or ''])
 run(['nmcli','connection','modify',n,'ipv6.method','auto'])
def wifi(c):
 n='bmo-wifi'
 if not yes(c['WIFI_ENABLED']):
  if nm_exists(n): run(['nmcli','connection','delete',n],check=False)
  return 'disabled'
 ssid,sec,pw=c['WIFI_SSID'],c['WIFI_SECURITY'],c['WIFI_PASSWORD']; real=pw not in SENTINELS; recreate=not nm_exists(n)
 if not recreate:
  oldssid=nm_get(n,'802-11-wireless.ssid'); oldsec=nm_get(n,'802-11-wireless-security.key-mgmt')
  if oldssid!=ssid:
   if sec=='wpa-psk' and not real: raise RuntimeError('novo WIFI_SSID exige nova WIFI_PASSWORD')
   recreate=True
  if sec=='open' and oldsec: recreate=True
  if sec=='wpa-psk' and not oldsec and not real: raise RuntimeError('WIFI_PASSWORD obrigatoria para WPA')
 if recreate and nm_exists(n): run(['nmcli','connection','delete',n])
 if not nm_exists(n): run(['nmcli','connection','add','type','wifi','ifname','*','con-name',n,'ssid',ssid])
 run(['nmcli','connection','modify',n,'802-11-wireless.ssid',ssid,'802-11-wireless.hidden','yes' if yes(c['WIFI_HIDDEN']) else 'no','connection.autoconnect','yes' if yes(c['WIFI_AUTOCONNECT']) else 'no'])
 if sec=='wpa-psk':
  if real: run(['nmcli','connection','modify',n,'802-11-wireless-security.key-mgmt','wpa-psk','802-11-wireless-security.psk',pw])
  elif not nm_get(n,'802-11-wireless-security.key-mgmt'): raise RuntimeError('WIFI_PASSWORD ausente')
 ipv4(n,c['WIFI_IPV4_MODE'],c['WIFI_STATIC_ADDRESS'],c['WIFI_STATIC_GATEWAY'],c['WIFI_STATIC_DNS'])
 if yes(c['WIFI_AUTOCONNECT']):
  r=run(['nmcli','--wait','20','connection','up',n],check=False); return 'connected' if r.returncode==0 else 'configured-waiting-device'
 return 'configured'
def wired(c):
 n='bmo-wired'
 if not yes(c['WIRED_ENABLED']):
  if nm_exists(n): run(['nmcli','connection','delete',n],check=False)
  return 'disabled'
 if not nm_exists(n): run(['nmcli','connection','add','type','ethernet','ifname','*','con-name',n])
 run(['nmcli','connection','modify',n,'connection.autoconnect','yes' if yes(c['WIRED_AUTOCONNECT']) else 'no']); ipv4(n,c['WIRED_IPV4_MODE'],c['WIRED_STATIC_ADDRESS'],c['WIRED_STATIC_GATEWAY'],c['WIRED_STATIC_DNS'])
 if yes(c['WIRED_AUTOCONNECT']):
  r=run(['nmcli','--wait','20','connection','up',n],check=False); return 'connected' if r.returncode==0 else 'configured-waiting-device'
 return 'configured'
def network(c):
 run(['systemctl','enable','NetworkManager'],check=False); run(['systemctl','start','NetworkManager'],check=False)
 if not yes(c['NETWORK_ENABLED']): run(['nmcli','networking','off'],check=False); return {'network':'offline','wifi':'disabled','wired':'disabled'}
 run(['nmcli','networking','on'],check=False); return {'network':'configured','wifi':wifi(c),'wired':wired(c)}
def ssh(c,s):
 en=yes(c['SSH_ENABLED']); pa=yes(c['SSH_PASSWORD_AUTH'])
 if en and pa and s.get('USER_PASSWORD_DEFAULT','yes')=='yes': raise RuntimeError('Para ligar ACESSO_REMOTO, troque SENHA_USUARIO por uma senha diferente de r36s.')
 d=Path('/etc/ssh/sshd_config.d'); d.mkdir(parents=True,exist_ok=True); (d/'90-bmo.conf').write_text('PermitRootLogin no\n'+f"PasswordAuthentication {'yes' if pa else 'no'}\n"+'PubkeyAuthentication yes\n'+f"Port {int(c['SSH_PORT'])}\n")
 if en: run(['ssh-keygen','-A'],check=False); run(['systemctl','enable','ssh'],check=False); run(['systemctl','restart','ssh'],check=False); return 'enabled' if run(['systemctl','is-active','--quiet','ssh'],check=False).returncode==0 else 'error'
 run(['systemctl','disable','ssh'],check=False); run(['systemctl','stop','ssh'],check=False); return 'disabled'
def mdns(c):
 if yes(c['MDNS_ENABLED']) and yes(c['NETWORK_ENABLED']): run(['systemctl','enable','avahi-daemon'],check=False); run(['systemctl','restart','avahi-daemon'],check=False); return 'enabled'
 run(['systemctl','disable','avahi-daemon'],check=False); run(['systemctl','stop','avahi-daemon'],check=False); return 'disabled'
def ips():
 r=run(['ip','-4','-o','addr','show','up','scope','global'],check=False); addresses=[]
 for line in r.stdout.splitlines():
  fields=line.split()
  if len(fields)<4 or fields[1].split('@')[0].startswith(('lo','tailscale','tun','docker','veth','br-')): continue
  try: address=ipaddress.ip_interface(fields[3]).ip
  except ValueError: continue
  if address.version==4 and not address.is_link_local and not address.is_loopback:
   addresses.append(str(address))
 return list(dict.fromkeys(addresses))

def summary_lines(c,ns,ss,result,addresses):
 lines=['','========================================','          BMO - PRIMEIRO BOOT','========================================']
 lines.append('Configuracao: CONCLUIDA' if result=='OK' else 'Configuracao: PRECISA DE ATENCAO')
 if not yes(c['NETWORK_ENABLED']): lines.append('Rede: DESLIGADA na configuracao')
 elif addresses:
  lines.append('Rede local: CONECTADA')
  lines.extend(f'IP: {address}' for address in addresses)
  lines.append('Internet: nao testada')
 else:
  lines.extend(['Rede: SEM CONEXAO / SEM IP','Confira o Wi-Fi ou o cabo/adaptador.','Ajuste BMO-FIRSTBOOT.txt se precisar.'])
 if ss=='enabled':
  lines.append('SSH: LIGADO (acesso remoto)')
  if addresses:
   lines.extend(['No computador, use:',f'ssh -p {c["SSH_PORT"]} {c["USER_NAME"]}@{addresses[0]}'])
  else: lines.append('SSH precisa de uma rede com IP.')
 elif ss=='error': lines.append('SSH: FALHOU ao iniciar')
 else: lines.append('SSH: DESLIGADO')
 if result!='OK': lines.append('Veja BMO-STATUS.txt na BOOT.')
 lines.extend(['','Resumo salvo em BMO-RESUMO.txt na BOOT.','TF2: desligue antes de inserir o cartao.','========================================',''])
 return lines

def show_summary():
 c=parse_config(config_path()); saved={}
 p=boot_dir()/'BMO-STATUS.txt'
 if p.exists():
  for line in p.read_text(errors='replace').splitlines():
   if '=' in line:
    key,value=line.split('=',1); saved[key]=value
 result=saved.get('FIRSTBOOT','PENDING')
 ss='enabled' if run(['systemctl','is-active','--quiet','ssh'],check=False).returncode==0 else 'disabled'
 print('\n'.join(summary_lines(c,{},ss,result,ips())),flush=True)

def status(c,ns,ss,ms,result='OK'):
 b=boot_dir(); a=ips()
 network_state='offline' if not yes(c['NETWORK_ENABLED']) else ('connected' if a else 'disconnected')
 if result!='OK': network_state='error'
 summary='\n'.join(summary_lines(c,ns,ss,result,a))
 print(summary,flush=True)
 try: b.mkdir(parents=True,exist_ok=True); (b/'logs').mkdir(parents=True,exist_ok=True)
 except OSError: return
 l=[f'HOSTNAME={c["HOSTNAME"]}']+[f'IPV4_{i}={v}' for i,v in enumerate(a,1)]
 if ss=='enabled' and a: l.append(f'SSH=ssh -p {c["SSH_PORT"]} {c["USER_NAME"]}@{a[0]}')
 (b/'BMO-IP.txt').write_text('\n'.join(l)+'\n')
 (b/'BMO-RESUMO.txt').write_text(summary+'\n',encoding='utf-8')
 (b/'BMO-STATUS.txt').write_text('\n'.join([f'BMO_BASE_VERSION={BASE_VERSION}',f'FIRSTBOOT={result}',f'NETWORK={network_state}',f'WIFI={ns.get("wifi","unknown")}',f'WIRED={ns.get("wired","unknown")}',f'SSH={ss}',f'MDNS={ms}',f'HOSTNAME={c["HOSTNAME"]}',f'UPDATED_UTC={datetime.now(timezone.utc).isoformat()}'])+'\n')
 if LOG_FILE.exists():
  try: shutil.copy2(LOG_FILE,b/'logs'/'firstboot.log')
  except OSError: pass

def safe_error(e):
 # CalledProcessError includes its command, which can contain a Wi-Fi password.
 if isinstance(e,subprocess.CalledProcessError):
  return 'Falha ao configurar o sistema/rede. Confira BMO-FIRSTBOOT.txt e o adaptador.'
 if isinstance(e,(ValueError,RuntimeError)): return str(e)
 return 'Nao foi possivel concluir a configuracao. Confira BMO-FIRSTBOOT.txt.'

def sanitize(p):
 if not p.exists(): return
 out=[]
 for r in p.read_text(encoding='utf-8-sig',errors='replace').splitlines():
  if '=' not in r or r.lstrip().startswith('#'): out.append(r); continue
  k,_=r.split('=',1); out.append(f'{k.strip()}=__APPLIED__' if k.strip() in SECRET_KEYS else r)
 p.write_text('\n'.join(out)+'\n')
BUILD_MARKER=Path('/.bmo-ready-build-root')

def main():
 if BUILD_MARKER.exists():
  print('BMO: imagem em preparacao; primeiro boot adiado.',flush=True); return 0
 if '--summary' in sys.argv: show_summary(); return 0
 mode='network' if '--network-only' in sys.argv else 'apply'; p=ensure_boot_config(); c=parse_config(p); validate(c); s=read_state(); log(f'BMO firstboot {BASE_VERSION}: inicio mode={mode}')
 if mode!='network': s['USER_NAME']=ensure_user(c,s); identity(c)
 elif 'USER_PASSWORD_DEFAULT' not in s: s['USER_PASSWORD_DEFAULT']='yes'
 print('Conectando a rede. Aguarde...',flush=True); ns=network(c); ss=ssh(c,s); ms=mdns(c); s.update({'BMO_BASE_VERSION':BASE_VERSION,'FIRSTBOOT_LAST_UTC':datetime.now(timezone.utc).isoformat(),'FIRSTBOOT_DONE':'yes'}); write_state(s); MARKER.touch(); sanitize(p); log('BMO_FIRSTBOOT_OK'); status(c,ns,ss,ms,'OK'); return 0
if __name__=='__main__':
 try: raise SystemExit(main())
 except Exception as e:
  message=safe_error(e); log(f'BMO_FIRSTBOOT_ERROR: {message}')
  try:
   c=dict(DEFAULTS); p=config_path(); c.update(parse_config(p) if p.exists() else {}); status(c,{'network':'error','wifi':'error','wired':'error'},'disabled','disabled','ERROR')
  except Exception: pass
  print(f'ERRO: {message}',file=sys.stderr); raise SystemExit(1)
BMO_FIRSTBOOT_SOURCE_EOF
cat > "$WORK/90-bmo-welcome.sh" <<'BMO_WELCOME_SOURCE_EOF'
# Show current firstboot/network information at interactive login, including
# after the automatic resize reboot. Never apply configuration from a profile.
if [ -t 1 ] && [ -x /usr/local/sbin/bmo-firstboot ] && [ -f /var/lib/bmo/firstboot.done ]; then
    /usr/local/sbin/bmo-firstboot --summary || true
fi
BMO_WELCOME_SOURCE_EOF
cat > "$WORK/BMO-FIRSTBOOT-MODELO.txt" <<'BMO_TEMPLATE_SOURCE_EOF'
# BMO - COMECE AQUI
# Abra no Bloco de Notas. Edite somente depois do sinal =.
# Nao coloque aspas. Mantenha cada resposta em uma unica linha.
# Retire o cartao TF2 de jogos durante todo o primeiro boot!

# 1. WI-FI
# Digite o nome e a senha exatamente como no seu roteador.
# Para usar cabo/adaptador Ethernet ou ficar sem rede, deixe vazio.
REDE_WIFI=
SENHA_WIFI=

# 2. SENHA DO R36S
# Escolha sua senha. Voce nao precisa enviar essa senha a ninguem.
# Para acesso remoto, ela precisa ser diferente de r36s.
SENHA_USUARIO=r36s

# 3. ACESSO PELO COMPUTADOR (SSH)
# sim = permitir acesso remoto; nao = manter desligado.
ACESSO_REMOTO=nao

# PRONTO! Salve, remova o cartao com seguranca e ligue o R36S.
# O IP e o resultado aparecerao na tela e em BMO-RESUMO.txt.
# As senhas serao apagadas deste arquivo apos a configuracao.
#
# Nao precisa preencher nada abaixo para uma instalacao comum.
# Opcoes avancadas continuam aceitas: WIFI_ENABLED, WIFI_HIDDEN,
# WIFI_SECURITY, WIFI_IPV4_MODE, WIRED_IPV4_MODE, SSH_PORT,
# USER_NAME, HOSTNAME, TIMEZONE e LOCALE.
# Use os nomes antigos OU os nomes acima; nao repita a mesma opcao.
BMO_TEMPLATE_SOURCE_EOF
python3 - "$WORK/bmo-firstboot" <<'BMO_VALIDATE_EOF'
import pathlib,sys
p=pathlib.Path(sys.argv[1])
compile(p.read_text(encoding="utf-8"),str(p),"exec")
BMO_VALIDATE_EOF
sh -n "$WORK/90-bmo-welcome.sh"
BACKUP="$ROOT/var/backups/bmo-firstboot-$(date -u +%Y%m%dT%H%M%SZ)-$$"
install -d -m 0700 "$BACKUP"
cp -a "$ROOT/usr/local/sbin/bmo-firstboot" "$BACKUP/"
if [ -f "$ROOT/etc/profile.d/90-bmo-welcome.sh" ]; then cp -a "$ROOT/etc/profile.d/90-bmo-welcome.sh" "$BACKUP/"; fi
install -D -m 0755 "$WORK/bmo-firstboot" "$ROOT/usr/local/sbin/bmo-firstboot"
install -D -m 0644 "$WORK/90-bmo-welcome.sh" "$ROOT/etc/profile.d/90-bmo-welcome.sh"
BOOT="$ROOT/boot/u-boot"
[ -d "$BOOT" ] || BOOT="$ROOT/boot"
install -d "$BOOT"
cp "$WORK/BMO-FIRSTBOOT-MODELO.txt" "$BOOT/BMO-FIRSTBOOT-MODELO.txt"
echo "Atualizacao concluida. Configuracao e senhas existentes preservadas."
echo "Backup: $BACKUP"
if [ "$ROOT" = / ]; then
 "$ROOT/usr/local/sbin/bmo-firstboot" --summary | tee "$BOOT/BMO-RESUMO.txt"
else
 echo "BMO_UPDATE_SANDBOX_OK"
fi
