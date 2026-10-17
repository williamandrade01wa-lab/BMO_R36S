# BMO R36S

Projeto do BMO para R36S.

Este repositório é a fonte oficial do código do projeto. O fluxo de trabalho é:

1. Desenvolvimento e revisão no GitHub/Codex.
2. Le Potato como servidor de deploy, validação, backup e rollback.
3. R36S como ambiente de candidate, teste físico e produção.

## Ambientes

- **Produção no R36S:** `/opt/bmo-ui/index.html`
- **Candidate no R36S:** `/opt/bmo-ui/index.bmo-next.html`
- **Le Potato:** servidor de deploy e cópia do repositório

## Fluxo de promoção

`editar -> validar -> candidate -> teste físico -> backup -> produção`

Nunca promover alterações diretamente para produção sem teste físico no R36S.

## Estrutura planejada

```text
frontend/
backend/
launchers/
systemd/
scripts/
docs/
```

## Segurança

Este repositório não deve conter ROMs, saves, states, backups `.tar.gz`, chaves SSH, credenciais ou o conteúdo privado de `Moonlight.conf`.

As regras operacionais detalhadas para agentes e Codex ficam em [`AGENTS.md`](AGENTS.md).
