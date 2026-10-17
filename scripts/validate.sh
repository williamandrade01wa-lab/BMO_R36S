#!/usr/bin/env bash

set -euo pipefail

ROOT="$(
  cd "$(dirname "$0")/.." &&
  pwd
)"

cd "$ROOT"

echo "============================================================"
echo " BMO VALIDATE"
echo "============================================================"

echo
echo "[10%] Estrutura..."

required=(
  "frontend/index.bmo-next.html"
  "frontend/index.html"
  "backend/bmo-control-api.py"
  "launchers/bmo-game-launcher.py"
  "launchers/bmo-kiosk.sh"
  "launchers/bmo-moonlight-launch.sh"
  "launchers/bmo-moonlight-hotkeys.py"
)

for file in "${required[@]}"; do
  test -f "$file" || {
    echo "ERRO: arquivo ausente: $file" >&2
    exit 1
  }
done

echo "STRUCTURE_OK"

echo
echo "[25%] Python..."

while IFS= read -r -d '' file; do
  python3 - "$file" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text(encoding="utf-8")
compile(source, str(path), "exec")
print(f"PYTHON_OK : {path}")
PY
done < <(
  find backend launchers scripts/runtime \
    -type f \
    -name '*.py' \
    -print0
)

echo
echo "[40%] Shell..."

while IFS= read -r -d '' file; do
  bash -n "$file"
  echo "SHELL_OK  : $file"
done < <(
  find launchers scripts/runtime scripts \
    -type f \
    -name '*.sh' \
    -print0
)

echo
echo "[55%] Marcadores funcionais do candidate..."

candidate="frontend/index.bmo-next.html"

markers=(
  "BMO_PC_STREAM_V1"
  "BMO_MAIN_MENU_SCROLL_V2"
  "BMO_GAMES_FAST_NAV_V1"
  "BMO_GAMES_VIRTUAL_WINDOW_V1"
  "BMO_GAMES_LAZY_LOAD_V1"
  "BMO_FAVORITES_XY_V1"
)

for marker in "${markers[@]}"; do
  grep -Fq "$marker" "$candidate" || {
    echo "ERRO: marcador ausente: $marker" >&2
    exit 1
  }

  echo "MARKER_OK : $marker"
done

echo
echo "[70%] Arquivos proibidos rastreados..."

if git ls-files | grep -E '(^|/)(Moonlight\.conf|SAVEDATA/|CACHE/|content_history\.lpl$|favorites\.json$)|\.(gba|gb|gbc|sfc|smc|nes|iso|cso|pbp)$' >/tmp/bmo-forbidden-tracked.txt; then
  echo "ERRO: arquivos proibidos encontrados no Git:" >&2
  cat /tmp/bmo-forbidden-tracked.txt >&2
  exit 1
fi

echo "TRACKED_FILES_OK"

echo
echo "[85%] Diff..."

if git rev-parse --verify origin/main >/dev/null 2>&1; then
  base="$(git merge-base HEAD origin/main)"
  git diff --check "$base"...HEAD
else
  echo "WARN: origin/main indisponivel; diff --check ignorado."
fi

echo "DIFF_CHECK_OK"

echo
echo "[100%] Validacao concluida."

echo
echo "============================================================"
echo " BMO_VALIDATE_OK"
echo "============================================================"
