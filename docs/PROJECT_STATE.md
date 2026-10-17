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

## Próxima etapa

Importar o código real do baseline para o repositório com estrutura organizada:

```text
frontend/
backend/
launchers/
systemd/
scripts/
docs/
```

A partir daí, mudanças devem preferencialmente ocorrer em branch/PR antes do deploy no candidate do R36S.
