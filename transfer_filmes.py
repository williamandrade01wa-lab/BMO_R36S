import os, sys, subprocess, time

src_dir = r"D:\Plex - FILMES"
log_path = r"C:\Users\Willi\transfer_filmes.log"

def log(msg):
    with open(log_path, "a", encoding="utf-8") as f:
        f.write(f"[{time.strftime('%H:%M:%S')}] {msg}\n")

log("Iniciando transferencia de Filmes...")

folders = [f for f in os.listdir(src_dir) if os.path.isdir(os.path.join(src_dir, f))]
log(f"Encontradas {len(folders)} pastas para mover.")

for idx, folder in enumerate(folders, 1):
    local_path = os.path.join(src_dir, folder)
    remote_path = f"/srv/barracuda/midia/Filmes/{folder}"
    log(f"[{idx}/{len(folders)}] Processando: {folder}")
    subprocess.run(["ssh", "potato", f"mkdir -p '{remote_path}'"], capture_output=True)
    
    files = os.listdir(local_path)
    for file in files:
        s_file = os.path.join(local_path, file)
        d_file = f"{remote_path}/{file}"
        log(f"  Copiando {file}...")
        cmd = ["scp", "-q", s_file, f"potato:'{d_file}'"]
        subprocess.run(cmd)

log("Transferencia de Filmes concluida!")
