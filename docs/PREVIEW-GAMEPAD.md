# Preview e Gamepad (Maestri, PC)

Ferramenta só do PC, não vai para o aparelho. Portais do canvas "BMO Preview" e "BMO Gamepad" usam `http://localhost:8360`.

Subir: `python -I scripts/preview-server.py 8360`

- `/` serve `frontend/index.bmo-next.html` com `gamepad-inject.js` injetado (o arquivo do app não é alterado).
- `/gamepad.html`: emulador. Envia `POST /gamepad` (`{"type":"press"|"release","btn":N}`) e `POST /gamepad/tap` (`{"btn":N}`).
- `GET /gamepad-state`: `{ts, buttons[17], axes[4]}`, lido pelo `gamepad-inject.js`.
- Somente 127.0.0.1. Não sobe o backend do BMO (8083 etc.): chamadas à API não funcionam no Preview.
- Mapa dos botões 0 a 16: B, A, X, Y, L1, R1, L2, R2, SELECT, START, FN, L3, R3, cima, baixo, esquerda, direita.

## Por que o toque podia se perder (corrigido em 2026-11-14)

- O portal do Maestri sem foco deixa o `requestAnimationFrame` em ~1 fps (timers não sofrem). O `poll()` do app roda por `requestAnimationFrame`, então toques curtos passavam entre duas leituras. O `gamepad-inject.js` agora troca o `requestAnimationFrame` por um timer de 16 ms (medido: 59,6 fps) e segura cada botão até o app ler o estado em duas leituras distintas (solta à força depois de 4 s). Para o rAF nativo, use `?raf=native` na URL.
- O servidor injeta `/gamepad-inject.js?v=<data do arquivo>` e responde `Cache-Control: no-store`, porque o webview do portal reaproveitava o script antigo.
- URLs do relay são relativas (qualquer porta). Teclado do PC: setas, Z/X/A/S/Q/E/F, Enter (START), Backspace (SELECT); ignorado enquanto você digita em um campo.

## Teste rápido pelo CLI do Maestri

```
curl -X POST -H "Content-Type: application/json" -d '{"btn":8}' http://127.0.0.1:8360/gamepad/tap    # SELECT
maestri portal evaluate "BMO Preview" "String(MAIN_MENU.visible)"
maestri portal click "BMO Gamepad" '[data-btn="14"]'                                                   # D-pad baixo
```
Resultado medido: 12 de 12 toques espaçados e 3 de 3 em rajada (0,35 s); B e SELECT fecham o teclado Wi-Fi com `APPS.current=null`.

## Áudio no Preview (2026-11-14)

- O servidor também entrega `/assets/*` a partir de `<repo>/assets` (sons e arte de boot), com bloqueio de `..`. Antes, `/assets/sounds/*.wav` dava 404 e o Preview ficava mudo (o app cai no modo `browser-fallback`, Web Audio, procurando `/assets/sounds/`).
- O navegador só libera o áudio depois de um gesto do usuário: clique no Preview e rode `unlockBmoBrowserAudio()`. Conferir: `BMO_SOUND_DIAG` (`audioCtxState: running`, `resolvedBase: /assets/sounds/`, `lastError: null`).
- Medido: as 14 carinhas tocaram o som (`playedCount` +1 cada, sem erro); `glitch` usa o som `error` por mapeamento do app; `error` e `success` tocam direto por `playBrowserBmoSound`.
