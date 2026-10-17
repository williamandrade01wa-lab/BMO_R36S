# AGENTS.md

## Objetivo

Este repositório mantém o código e a configuração versionável do BMO para R36S.

## Fluxo obrigatório

Sempre seguir:

`recuperar -> validar -> editar -> revisar diff -> candidate -> teste físico -> backup -> produção`

Não alterar produção diretamente quando houver candidate disponível.

## Caminhos do R36S

- Produção frontend: `/opt/bmo-ui/index.html`
- Candidate frontend: `/opt/bmo-ui/index.bmo-next.html`
- Backend principal: `/usr/local/bin/bmo-control-api.py`

## Não regredir

Preservar explicitamente:

- PC STREAM / Moonlight
- retorno ao BMO após streaming
- saída do streaming com FN+SELECT
- Favorites X/Y
- Games Fast Nav
- Games Virtual Window
- Games Lazy Load
- suporte GBA ZIP
- PSP standalone
- volume pelos botões físicos
- brilho com FN+Volume
- navegação pelo gamepad
- tty1 e fluxo de kiosk existentes

## Gamepad

Evitar alterações em `R36S_GAMEPAD.poll()` sem necessidade comprovada.

Mapeamentos relevantes conhecidos:

- B = 0
- A = 1
- X = 2
- Y = 3
- L1 = 4
- R1 = 5
- L2 = 6
- R2 = 7
- SELECT = 8
- START = 9
- FN = 10
- L3 = 11
- R3 = 12
- D-pad = 13-16
- analógico esquerdo = axes 0/1
- analógico direito = axes 2/3

## Segurança de sistema

Não executar sem necessidade explícita:

- `fstrim`
- `blkdiscard`
- `apt autoremove`
- alterações de partição

Não desmascarar `fstrim.timer` ou `upower.service` sem decisão explícita.

Evitar reboot quando restart isolado do serviço for suficiente.

## Shell / SSH

Não usar `set -e` solto na sessão SSH interativa.

Para blocos transacionais, preferir subshell:

```bash
(
set -euo pipefail
# ...
)
```

Tarefas longas devem preferencialmente sobreviver à queda de SSH usando `systemd-run`, `tmux` ou `screen`.

## Backups

Fazer backup antes de mudança importante. Para checkpoints oficiais, manter cópia local e remota na Le Potato e validar SHA256.

## Dados proibidos no Git

Nunca commitar:

- ROMs
- saves/states
- backups `.tar.gz`
- chaves SSH
- tokens/senhas
- `Moonlight.conf` real
- qualquer segredo ou credencial

## Filosofia de mudança

Preferir alterações pequenas, isoladas e reversíveis. Não reescrever componentes estáveis quando uma correção localizada resolve o problema. Sempre revisar o diff antes de deploy.
