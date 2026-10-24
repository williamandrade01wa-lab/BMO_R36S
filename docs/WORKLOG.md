# BMO R36S — Worklog

> Registro cronológico obrigatório das etapas significativas do projeto.
>
> Histórico anterior à reorganização documental de 2026-10-18 foi preservado **sem alteração** em [`docs/archive/WORKLOG-through-2026-10-18.md`](archive/WORKLOG-through-2026-10-18.md).

## Como usar

Antes de começar uma nova etapa:

1. leia `docs/PROJECT-CONTINUITY.md`;
2. leia a entrada mais recente deste arquivo;
3. consulte o histórico arquivado se a etapa depender de uma decisão anterior;
4. confira branch, HEAD, GitHub Actions e checkpoint atual.

Antes de avançar para outra etapa significativa, registre aqui o resultado da etapa atual.

## Modelo de entrada

```markdown
## YYYY-MM-DD — Título curto

- Fase:
- Branch:
- Commit inicial:
- Objetivo:
- R36S_REQUIRED=YES|NO

### Ações realizadas

- ...

### Arquivos alterados

- ...

### Resultado esperado

- ...

### Resultado obtido

- ...

### Validação

- ...

### Pendências / riscos

- ...

### Próximo passo exato

- ...
```

---

## Estado técnico imediatamente anterior à reorganização

Referência resumida do último bloco do Worklog arquivado:

```text
Run #5: falha comprovada por memória/BTF
causa: Not enough RAM available (6426Mib) for BTF build
correção: KERNEL_BTF=no
baseline técnico: 8d967e34f07e013752e45b2478250b1e9b71e933
Run #7: 39184063121
```

O preflight da execução seguinte confirmou a regra de BTF. O Gate 1 ainda não foi concluído porque a validação integral da imagem/artifact continua pendente.

---

## 2026-10-18 — Estrutura do projeto orientada à instalação pública simples

- Fase: arquitetura de projeto / productização / continuidade
- Branch: `feat/bmo-linux-base-v1`
- Commit inicial: `8d967e34f07e013752e45b2478250b1e9b71e933`
- Objetivo: reorganizar a fonte de verdade do projeto para que a meta principal seja uma experiência simples e didática de baixar, gravar, configurar e rodar o BMO, preservando pontos seguros no Git.
- `R36S_REQUIRED=NO`

### Ações realizadas

- relidos, na ordem obrigatória, `AGENTS.md`, `docs/PROJECT-CONTINUITY.md`, `docs/WORKLOG.md`, `docs/ROADMAP.md` e `docs/BMO-LINUX-BASE-DESIGN.md`;
- confirmado o HEAD técnico inicial `8d967e34f07e013752e45b2478250b1e9b71e933`;
- confirmada a Run #7 (`39184063121`) como execução técnica associada a esse HEAD;
- identificado que o README ainda apresentava como fluxo principal o caminho antigo baseado em Armbian XFCE, `firstrun_overrides.txt`, clone Git e instalador manual;
- definido como North Star o fluxo público `baixar -> gravar -> configurar BOOT -> ligar -> bmo install -> usar`;
- definida arquitetura de produto em quatro camadas: BMO Linux Base, Bootstrap, instalação/manutenção e BMO App;
- criada documentação oficial de responsabilidade dos diretórios sem mover código funcional durante a validação da imagem;
- roadmap reorganizado em gates independentes de produto;
- criado modelo formal de checkpoints por commit;
- preservado o Worklog histórico anterior em `docs/archive/WORKLOG-through-2026-10-18.md` usando o blob original, sem reescrever o histórico;
- preservada também a continuidade anterior como snapshot arquivado para auditoria;
- `main` permaneceu intocada.

### Arquivos alterados

Commit estrutural base `ed658f30c1a3a599b37557188cd8856b5ef54b2b`:

- `README.md`;
- `AGENTS.md`;
- `docs/PROJECT-STRUCTURE.md`;
- `docs/PROJECT-CONTINUITY.md`;
- `docs/ROADMAP.md`.

Fechamento do checkpoint:

- `docs/CHECKPOINTS.md`;
- `docs/WORKLOG.md`;
- `docs/archive/WORKLOG-through-2026-10-18.md`;
- `docs/archive/PROJECT-CONTINUITY-pre-structure.md`;
- `docs/ROADMAP.md` com evidência do Gate 0.

### Resultado esperado

Um novo usuário deve enxergar primeiro o produto que estamos construindo, não o histórico de engenharia.

Um novo desenvolvedor/agente deve conseguir distinguir claramente:

```text
imagem
bootstrap
instalação/manutenção
BMO App
CI/deploy/documentação
```

E cada grande avanço deve ter um commit seguro de retorno registrado.

### Resultado obtido

- estrutura documental limpa criada;
- fluxo público desejado colocado como regra central;
- fluxo antigo deixou de ser apresentado como instalação pública definitiva;
- nenhuma refatoração física arriscada de código foi feita nesta etapa;
- checkpoint `CP-STRUCTURE-001` criado apontando para:

```text
ed658f30c1a3a599b37557188cd8856b5ef54b2b
```

- Gate 0 — estrutura e continuidade — considerado concluído com evidência versionada;
- Gate 1 — imagem base reproduzível — continua aberto.

### Validação

- alterações estruturais/documentais não tocaram `image/armbian/**`;
- alterações não tocaram frontend, backend, launchers ou systemd funcional;
- workflow `Build BMO Linux Base` possui filtro de paths para `image/armbian/**` e o próprio YAML, portanto esta reorganização documental não dispara/reinicia o build da imagem;
- o histórico operacional anterior permanece disponível no Git e também no arquivo de archive atual;
- `main` não foi modificada.

### Pendências / riscos

- o código físico ainda possui áreas históricas/transitórias; não mover diretórios apenas para combinar visualmente com a arquitetura;
- o README agora descreve corretamente a experiência alvo, mas ainda não existe release pública pronta para download;
- Gate 1 continua bloqueado pela validação pós-build da imagem;
- a interface observada pelo usuário indicou falha no validator da Run #7 enquanto a API consultada estava defasada; é necessário obter o relatório completo antes de corrigir conteúdo funcional.

### Próximo passo exato

1. recuperar o resultado final da Run #7 (`39184063121`);
2. obter `validation-report.txt` ou log equivalente completo;
3. reunir todas as falhas contratuais da mesma imagem;
4. registrar esse diagnóstico neste Worklog;
5. corrigir somente defeitos comprovados;
6. revisar diff;
7. executar nova CI;
8. criar `CP-IMAGE-002` somente quando preflight, build, validator, compressão, SHA256 e artifact final passarem na mesma execução válida.

```text
R36S_REQUIRED=NO
```

## 2026-10-24 — Diagnóstico Run #7 e finalização da BOOT

- Fase: Gate 1 / correção comprovada pós-build
- Branch: `feat/bmo-linux-base-v1`
- Commit inicial: `6b65731f24497d901bf5e125edbe575f9f212ae4`
- Objetivo: destravar a imagem base e continuar rumo à imagem Ready que inicia diretamente no BMO, solicitada pelo usuário.
- `R36S_REQUIRED=NO`

### Ações realizadas

- Confirmado o HEAD pelo Git remoto e que a Run #7 é a última execução.
- Recuperados jobs e log completo do job `117842763898`, Run `39184063121`.
- Build e preflight passaram. Validator falhou exatamente em dois arquivos ausentes na FAT: `/BMO-FIRSTBOOT.txt` e `/README-FIRST-BOOT.txt`. As seis entradas root passaram.
- Confirmado no upstream Armbian pinado que hooks de bootloader/imagem executam depois da customização do rootfs; a verificação condicional de `/boot/u-boot` no chroot não garante o conteúdo final da FAT.
- Adicionado finalizador explícito da imagem final: exige arquivo regular não vazio, uma única partição FAT, copia os dois templates versionados, compara conteúdo e libera mount/loop.
- Builder chama o finalizador antes do SHA256; validator integral permanece sem relaxamento.
- Receita Ready antiga e fontes locais localizadas na Potato. Build antigo de 18/10 parou em pacotes por falta de espaço; não tratar esse arquivo como Ready validada.

### Arquivos alterados

- `image/armbian/ci/finalize-boot.sh`
- `image/armbian/build-bmo-linux-base.sh`
- `image/armbian/ci/preflight.sh`
- `docs/PROJECT-CONTINUITY.md`
- `docs/WORKLOG.md`

### Resultado esperado / obtido

- Esperado: os dois templates estarão na FAT final, preservando rootfs e demais arquivos de boot.
- Obtido em fixture real FAT32/ext4 de 96 MiB: duas execuções idempotentes, conteúdo correto, `boot.ini` preservado, hash da partição root inalterado.
- Imagem inválida sem FAT foi recusada e o loop foi liberado.
- Evidência local na Potato: `/home/hipo/bmo/boot-fixture.xFE58y`.
- Build completo da correção ainda pendente; Gate 1 permanece aberto.

### Validação

- Fixture com partições reais passou; sintaxe e preflight devem passar antes do push.
- Não alterados kernel, DTB, gamepad, frontend nem sistema em produção do R36S.
- `main` preservada.

### Pendências / riscos

- Imagem mínima não equivale a Ready; integração e boot físico do BMO continuam pendentes.
- Log upstream contém `sd_fusing.sh: sudo: not found`; auditar antes de declarar bootloader/boot físico validado.
- Receita Ready antiga contém premissas de Pure e contagens rígidas; não reutilizar sobre a nova Base sem adaptação validada.
- Não reutilizar imagem Ready antiga parcialmente modificada/falta de espaço.

### Próximo passo exato

1. Validar preflight e diff; commitar correção e este registro na branch de imagem.
2. Acompanhar a nova CI; registrar Run ID/Job ID/resultados.
3. Somente concluir Gate 1 após validator, compressão, SHA256 e artifact final.
4. Integrar receita Ready sobre uma cópia com espaço suficiente, sem segredos nem ROMs.
5. Validar em cartão separado o primeiro boot diretamente no BMO (`R36S_REQUIRED=YES`).