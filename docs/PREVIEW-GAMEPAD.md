# Preview e Gamepad (Maestri, PC)

Ferramenta só do PC, não vai para o aparelho. Portais do canvas "BMO Preview" e "BMO Gamepad" usam `http://localhost:8360`.

Subir: `python -I scripts/preview-server.py 8360`

- `/` serve `frontend/index.bmo-next.html` com `gamepad-inject.js` injetado (o arquivo do app não é alterado).
- `/gamepad.html`: emulador. Envia `POST /gamepad` (`{"type":"press"|"release","btn":N}`) e `POST /gamepad/tap` (`{"btn":N}`).
- `GET /gamepad-state`: `{ts, buttons[17], axes[4]}`, lido pelo `gamepad-inject.js`.
- Somente 127.0.0.1. Não sobe o backend do BMO (8083 etc.): chamadas à API não funcionam no Preview.
- Mapa dos botões 0 a 16: B, A, X, Y, L1, R1, L2, R2, SELECT, START, FN, L3, R3, cima, baixo, esquerda, direita.
