import os, sys, subprocess

src = r"D:\Plex - FILMES"
log_path = r"C:\Users\Willi\mover_plex_status.log"

def log(msg):
    with open(log_path, "a", encoding="utf-8") as f:
        f.write(msg + "\n")

log("Iniciando varredura...")
files_to_copy = []
for root, dirs, files in os.walk(src):
    rel = os.path.relpath(root, src)
    dest_dir = f"/srv/barracuda/midia/Filmes/{rel}".replace("\\", "/") if rel != "." else "/srv/barracuda/midia/Filmes"
    subprocess.run(["ssh", "potato", f"mkdir -p '{dest_dir}'"], capture_output=True)
    for f in files:
        files_to_copy.append((os.path.join(root, f), f"{dest_dir}/{f}"))

log(f"Total de {len(files_to_copy)} arquivos encontrados. Iniciando SCP...")
for i, (s_file, d_file) in enumerate(files_to_copy):
    log(f"[{i+1}/{len(files_to_copy)}] Copiando {os.path.basename(s_file)}...")
    cmd = ["scp", "-q", s_file, f"potato:'{d_file}'"]
    subprocess.run(cmd)

log("Concluído com sucesso!")
