#!/usr/bin/env python3
"""Finish a CI Light core on a PC; never opens a physical disk or card."""
import argparse,gzip,hashlib,json,lzma,pathlib,shutil,struct,tempfile,time,sys
from ext4_reader import Ext
RUNTIME_SHA="1af91efd8374a2c164e5f2ffa37b3d65980b825a207cbb09c688b2997088c5ad"
def digest(path):
 with pathlib.Path(path).open("rb") as f:return hashlib.file_digest(f,"sha256").hexdigest()
def exists(e,p):
 try:e.resolve(p);return True
 except KeyError:return False
def verify_root(raw):
 e=Ext(raw)
 assert exists(e,"/etc/bmo/light-image.env")
 assert not exists(e,"/var/lib/bmo/firstboot.done")
 assert not exists(e,"/var/lib/bmo/light/install.done")
 source="/usr/share/bmo/light/source"
 manifest=e.data(e.inode(e.resolve(source+"/SHA256SUMS"))).decode("utf8")
 count=0
 for line in manifest.splitlines():
  sha,rel=line.split("  ",1);assert len(sha)==64 and rel.startswith("./") and ".." not in pathlib.PurePosixPath(rel).parts
  b=e.data(e.inode(e.resolve(source+"/"+rel[2:])))
  assert hashlib.sha256(b).hexdigest()==sha,rel
  count+=1
 for p in ["/root/.ssh","/home/r36s/.ssh"]:assert not exists(e,p),p
 names=e.dirs(e.resolve("/etc/ssh"))
 assert not any(n.startswith("ssh_host_") and "_key" in n for n in names)
 con=e.dirs(e.resolve("/etc/NetworkManager/system-connections"))
 assert not [n for n in con if n not in [".",".."]]
 installed=e.data(e.inode(e.resolve("/usr/local/sbin/bmo-light-install")))
 assert installed==e.data(e.inode(e.resolve(source+"/install/light/bmo-light-install")))
 env=e.data(e.inode(e.resolve("/etc/bmo/light-image.env"))).decode()
 s=e.sb
 total=struct.unpack_from("<I",s,4)[0]+(struct.unpack_from("<I",s,336)[0]<<32)
 free=struct.unpack_from("<I",s,12)[0]+(struct.unpack_from("<I",s,344)[0]<<32)
 result={"root_used_bytes":(total-free)*e.bs,"root_free_bytes":free*e.bs,"source":env.strip(),"payload_files_verified":count}
 # Validate the exact app content required by this beta, not only manifest presence.
 get=lambda path:e.data(e.inode(e.resolve(path)))
 lines=get(source+"/assets/sounds/SHA256SUMS").decode().splitlines()
 assert len(lines)==12
 for line in lines:
  sha,name=line.split(None,1)
  assert "/" not in name and name.endswith(".wav")
  assert hashlib.sha256(get(source+"/assets/sounds/"+name)).hexdigest()==sha
 policy=json.loads(get(source+"/install/system/chromium/bmo-kiosk.json"))
 assert policy["TranslateEnabled"] is False
 frontend_sha=hashlib.sha256(get(source+"/frontend/index.html")).hexdigest()
 assert frontend_sha=="946f7596ee4f82781a092ff9af598da877a685279c790e691a859a973cda348f"
 env_map=dict(line.split("=",1) for line in env.splitlines() if "=" in line)
 assert env_map["BMO_LIGHT_VERSION"]=="0.1.0-beta"
 assert env_map["BMO_APP_VERSION"]=="0.1.0-beta.1"
 result.update(source_commit=env_map["BMO_LIGHT_SOURCE"],version=env_map["BMO_LIGHT_VERSION"],app_version=env_map["BMO_APP_VERSION"],sound_files_verified=12,chromium_translate_enabled=False,frontend_sha256=frontend_sha)
 e.f.close();return result
def main():
 a=argparse.ArgumentParser()
 a.add_argument("--core",required=True);a.add_argument("--core-sha256",required=True)
 a.add_argument("--runtime",required=True);a.add_argument("--logo",required=True)
 a.add_argument("--name",default="BMO-R36S-PureLight-v0.1.0-beta")
 a.add_argument("--expected-source",required=True)
 a.add_argument("--output-dir",required=True);a.add_argument("--work-dir",required=True)
 o=a.parse_args();core=pathlib.Path(o.core).resolve();runtime=pathlib.Path(o.runtime).resolve()
 assert core.is_file() and runtime.is_file()
 assert digest(core)==o.core_sha256
 assert digest(runtime)==RUNTIME_SHA
 out=pathlib.Path(o.output_dir).resolve();out.mkdir(parents=True,exist_ok=True)
 work=pathlib.Path(o.work_dir).resolve();work.mkdir(parents=True,exist_ok=False)
 name=o.name
 assert name and all(c.isalnum() or c in "._-" for c in name) and ".." not in name
 target=out/(name+".img.xz")
 assert not target.exists()
 raw=work/(name+".img")
 opener=lzma.open if core.suffix==".xz" else gzip.open
 print("UNPACK_CORE",flush=True)
 with opener(core,"rb") as src,raw.open("wb") as dst:shutil.copyfileobj(src,dst,8*1024*1024)
 result=verify_root(raw)
 assert result["source_commit"]==o.expected_source
 root_validation=dict(result)
 print("ROOT_PAYLOAD_VERIFIED",json.dumps(result),flush=True)
 with raw.open("rb") as f:m=f.read(512)
 assert m[510:512]==b"\x55\xaa" and m[450] in [0x0b,0x0c] and m[466]==0x83
 start,sectors=struct.unpack_from("<II",m,454);rootstart,rootsectors=struct.unpack_from("<II",m,470)
 assert raw.stat().st_size==(rootstart+rootsectors)*512
 from pyfatfs.PyFatFS import PyFatFS
 print("INJECT_PINNED_RUNTIME",flush=True)
 with PyFatFS(str(raw),offset=start*512,preserve_case=True) as fat:
  fat.makedirs("/BMO-RUN",recreate=True)
  if fat.exists("/BMO-RUN/PPSSPP.TGZ"):fat.remove("/BMO-RUN/PPSSPP.TGZ")
  with runtime.open("rb") as src,fat.openbin("/BMO-RUN/PPSSPP.TGZ","w") as dst:shutil.copyfileobj(src,dst,1024*1024)
  if o.logo:
   b=pathlib.Path(o.logo).read_bytes()
   assert b[:2]==b"BM" and struct.unpack_from("<iiHHI",b,18)==(640,480,1,24,0)
   if fat.exists("/logo.bmp"):fat.remove("/logo.bmp")
   with fat.openbin("/logo.bmp","w") as dst:dst.write(b)
  readme=("BMO PureLight v0.1.0-beta - CANDIDATA PARA TESTE\n\n1. Use SD extra de 8 GB ou maior. Abra ABRIR-BMO.cmd na BOOT.\n"
   "2. Escolha a tela e configure Wi-Fi, senha e SSH. Para Wi-Fi, prefira 2,4 GHz se nao souber a capacidade do adaptador.\n"
   "3. TF2 de jogos FORA durante todo primeiro boot.\n"
   "4. Ligue com rede e energia estaveis. O sistema expande o SD e pode reiniciar uma vez.\n"
   "5. A instalacao e automatica, com progresso na tela e BMO-INSTALACAO.txt.\n"
   "6. Sem rede, confira BMO-RESUMO.txt e BMO-WIFI.txt. O sistema tenta novamente.\n"
   "7. Ao concluir, abre o BMO. Desligue completamente antes de inserir TF2.\n\n"
   "Sem ROMs ou pareamento pessoal. SSH e opcional e fica desligado se nao for habilitado.\n"
   "Se o assistente falhar, use Abrir log. Nunca compartilhe o TXT preenchido ou seus backups.\n")
  if fat.exists("/README-LIGHT.txt"):fat.remove("/README-LIGHT.txt")
  with fat.openbin("/README-LIGHT.txt","w") as dst:dst.write(readme.encode())
 with PyFatFS(str(raw),offset=start*512,read_only=True) as fat:
  h=hashlib.sha256()
  with fat.openbin("/BMO-RUN/PPSSPP.TGZ","r") as src:
   while b:=src.read(1024*1024):h.update(b)
  assert h.hexdigest()==RUNTIME_SHA
  if o.logo:
   with fat.openbin("/logo.bmp","r") as src:assert hashlib.sha256(src.read()).hexdigest()==digest(o.logo)
  with fat.openbin("/BMO-Preparar-Cartao.ps1","r") as src:wizard=src.read()
  wizard_text=wizard.decode("utf-8-sig")
  assert "version='0.2.1'" in wizard_text and "Ensure-BmoDirectory" in wizard_text
  assert fat.exists("/ABRIR-BMO.cmd") and fat.exists("/ScreenFiles")
  result.update(wizard_version="0.2.1",wizard_sha256=hashlib.sha256(wizard).hexdigest(),boot_logo_sha256=digest(o.logo))
 result.update(raw_sha256=digest(raw),raw_bytes=raw.stat().st_size,runtime_sha256=RUNTIME_SHA)
 # FAT edits must not change the ext4 application payload or machine identity.
 assert verify_root(raw)==root_validation
 partial=out/(name+".img.xz.partial")
 print("COMPRESS_LOCAL",flush=True);n=0;t=time.monotonic()
 with raw.open("rb") as src,lzma.open(partial,"wb",preset=3,check=lzma.CHECK_CRC64) as dst:
  while b:=src.read(8*1024*1024):
   dst.write(b);n+=len(b)
   if time.monotonic()-t>25:print("COMPRESSED_INPUT_BYTES",n,flush=True);t=time.monotonic()
 partial.rename(target)
 h=hashlib.sha256();n=0
 with lzma.open(target,"rb") as src:
  while b:=src.read(8*1024*1024):h.update(b);n+=len(b)
 assert h.hexdigest()==result["raw_sha256"] and n==result["raw_bytes"]
 result.update(image_sha256=digest(target),image_bytes=target.stat().st_size,physical_validation="PENDING",published_to_releases=False,product="BMO PureLight",finalizer_sha256=digest(__file__))
 (out/(target.name+".sha256")).write_text(result["image_sha256"]+"  "+target.name+"\n",encoding="utf8")
 (out/(name+".manifest.json")).write_text(json.dumps(result,indent=2),encoding="utf8")
 (work/"result.json").write_text(json.dumps(result),encoding="utf8")
 raw.unlink()
 print("BMO_LIGHT_FINAL_IMAGE_OK",json.dumps(result),flush=True)
if __name__=="__main__":main()
