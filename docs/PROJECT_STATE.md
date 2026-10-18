# BMO R36S — Project State

## Baseline oficial

Checkpoint estável atual:

`bmo-checkpoint-pcstream-menu-v2-20261017-172748`

SHA256:

`fb2a2d944b87a562e0ebf682e8f1feacc014df28bfa035b09730c30c296004ab`

Cópias validadas:

- Local no R36S: `/home/r36s/BMO-Games/bmo-checkpoint-pcstream-menu-v2-20261017-172748.tar.gz`
- Remota na Le Potato: `/home/hipo/bmo-backups/r36s/bmo-checkpoint-pcstream-menu-v2-20261017-172748.tar.gz`

O SHA256 local e remoto foi confirmado como idêntico.

## Estado funcional protegido

O baseline atual inclui e deve preservar:

- PC STREAM integrado ao menu principal
- Moonlight/Sunshine funcional
- retorno ao BMO após encerramento do streaming
- FN+SELECT para encerrar streaming
- Menu principal com `BMO_MAIN_MENU_SCROLL_V2`
- Games Fast Nav
- Games Virtual Window
- Games Lazy Load
- Favorites X/Y
- suporte a GBA ZIP
- PSP standalone
- controles físicos de volume e brilho

## Ambientes

### R36S

Candidate:

`/opt/bmo-ui/index.bmo-next.html`

Produção:

`/opt/bmo-ui/index.html`

Backend principal:

`/usr/local/bin/bmo-control-api.py`

### Le Potato

Função planejada:

- clone do repositório GitHub
- validação
- deploy para candidate
- backup antes de deploy
- rollback
- armazenamento de checkpoints oficiais

## BMO Linux Base v0.1 — validação física

Primeira imagem mínima compilada pelo GitHub Actions e gravada em microSD de teste.

Resultado físico confirmado no R36S em 2026-10-18:

- boot concluído com sucesso;
- ScreenFiles corretas copiadas para a partição BOOT;
- painel/tela funcionando;
- kernel/DTB/U-Boot suficientes para inicializar o aparelho;
- console exibido corretamente;
- ambiente XFCE não presente;
- objetivo da v0.1 atingido.

A v0.1 serve como prova de que o stack específico do R36S pode ser mantido em uma imagem Trixie mínima, sem depender do desktop original.

### Build validada

Branch:

`feat/bmo-linux-base-v1`

Workflow:

`Build BMO Linux Base`

Run validada:

`#2`

Commit de build:

`a0deea3f5892f67a6fa64943715450e720647985`

## Próxima etapa — BMO Linux Base v0.2

Adicionar sobre a base mínima já validada, sem instalar ainda o BMO completo:

- `BMO-FIRSTBOOT.txt` com parser seguro e chaves permitidas;
- criação/configuração do usuário `r36s`;
- hostname, timezone e locale;
- Wi-Fi opcional com autoconnect;
- SSH disponível sem desktop;
- escrita de status/IP na partição BOOT;
- comando `bmo` presente desde a imagem base;
- `bmo status`, `bmo ip`, `bmo network`, `bmo logs`, `bmo doctor` e `bmo install`;
- nenhuma chave SSH, token GitHub ou segredo embutido;
- fonte Git pública/HTTPS como arquitetura padrão;
- autenticação SSH privada apenas como configuração manual durante desenvolvimento.

Depois da v0.2, validar hardware complementar e então conectar o bootstrap ao instalador completo do BMO.
