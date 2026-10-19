# BMO R36S — Checkpoints

## Objetivo

Checkpoint é um **ponto seguro de engenharia registrado no Git**.

Ele responde quatro perguntas:

1. o que estava validado naquele ponto;
2. qual commit representa esse estado;
3. quais evidências existem;
4. para onde voltar se a próxima etapa der errado.

Checkpoint **não é sinônimo de release**.

## Convenção

IDs:

```text
CP-STRUCTURE-NNN   arquitetura/organização do projeto
CP-IMAGE-NNN       imagem/CI
CP-BOOT-NNN        boot/firstboot
CP-HW-NNN          hardware
CP-INSTALL-NNN     instalação
CP-APP-NNN         BMO App
CP-MAINT-NNN       update/rollback
CP-RELEASE-NNN     publicação
```

Status possíveis:

```text
SAFE        ponto seguro de retorno
VALIDATING  candidato em validação
BLOCKED     gate não atingido
SUPERSEDED  substituído por checkpoint posterior
```

## Checkpoint atual de organização

### CP-STRUCTURE-001 — Estrutura orientada à experiência pública

```text
STATUS=SAFE
COMMIT=ed658f30c1a3a599b37557188cd8856b5ef54b2b
BRANCH=feat/bmo-linux-base-v1
R36S_REQUIRED=NO
```

Objetivo:

- colocar a experiência do usuário como North Star;
- separar imagem, bootstrap, instalação, app e engenharia;
- eliminar a ambiguidade do README antigo como fluxo público definitivo;
- transformar o roadmap em gates de produto;
- registrar responsabilidades de diretório sem mover código funcional no meio da validação da imagem.

Evidências versionadas no commit:

```text
README.md
docs/PROJECT-STRUCTURE.md
docs/ROADMAP.md
docs/PROJECT-CONTINUITY.md
AGENTS.md
```

Validação:

- mudança documental/arquitetural;
- nenhum arquivo em `image/armbian/**` alterado;
- nenhum arquivo funcional de frontend/backend/launcher alterado;
- `main` intocada;
- workflow da BMO Linux Base só dispara para `image/armbian/**` ou o próprio YAML, então este checkpoint não invalida a imagem por alteração funcional.

Uso como retorno:

> Se uma futura reorganização de diretórios tornar o projeto confuso ou quebrar referências, este commit é o ponto de retorno da estrutura documental antes da refatoração física.

## Baseline técnico anterior

### CP-IMAGE-BTF-001 — Perfil mínimo com BTF desabilitado

```text
STATUS=SAFE-PARTIAL
COMMIT=8d967e34f07e013752e45b2478250b1e9b71e933
BRANCH=feat/bmo-linux-base-v1
R36S_REQUIRED=NO
```

O que está comprovado:

- falha de memória/BTF da Run #5 diagnosticada;
- `KERNEL_BTF=no` aplicado;
- preflight protege a configuração;
- preflight da execução seguinte passou.

O que **não** está comprovado nesse checkpoint:

- contrato completo da imagem;
- artifact final;
- boot físico;
- hardware.

Por isso ele é um baseline técnico, não o Gate 1 concluído.

## Gate atual — imagem base reproduzível

### CP-IMAGE-002 — PENDENTE

```text
STATUS=BLOCKED
R36S_REQUIRED=NO
```

Só pode ser criado quando uma mesma run válida comprovar:

- preflight = success;
- build = success;
- image contract = success;
- compressão = success;
- SHA256 gerado;
- artifact final publicado.

Estado operacional conhecido:

```text
Run #7
Run ID: 39184063121
HEAD técnico da execução: 8d967e34f07e013752e45b2478250b1e9b71e933
```

A interface observada pelo usuário já indicou falha do validator enquanto a API consultada ainda estava defasada. O próximo passo é obter o relatório completo e corrigir somente falhas comprovadas.

## Checkpoints planejados

### CP-BOOT-001

Criar quando cartão limpo comprovar:

- boot;
- ScreenFiles;
- firstboot;
- usuário;
- status/IP;
- reboot idempotente.

```text
R36S_REQUIRED=YES
```

### CP-HW-001

Criar quando hardware essencial estiver validado:

- gamepad;
- áudio;
- volume/brilho;
- OTG/HUB;
- Wi-Fi;
- TF2;
- DRM/KMS.

```text
R36S_REQUIRED=YES
```

### CP-INSTALL-001

Criar quando um R36S com a base saudável executar `bmo install` de forma reproduzível, sem segredo embutido e com fonte pública/HTTPS validada quando disponível.

```text
R36S_REQUIRED=YES
```

### CP-APP-001

Criar quando o BMO completo preservar frontend, controle, emuladores, streaming e retorno ao kiosk.

```text
R36S_REQUIRED=YES
```

### CP-MAINT-001

Criar quando update, verify e rollback forem comprovados em cenário real de falha e recuperação.

```text
R36S_REQUIRED=YES
```

### CP-RELEASE-001

Criar somente após auditoria pública, cartão limpo, documentação final, SHA256 e instalação por uma pessoa seguindo apenas o material público.

```text
R36S_REQUIRED=YES
```

## Regra de promoção

Nunca promover para `main` ou tratar uma versão como pública estável usando apenas um checkpoint parcial.

A release pública depende da cadeia de checkpoints necessária ao Gate 7.
