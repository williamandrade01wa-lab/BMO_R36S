# BMO R36S — Worklog

> Registro cronológico obrigatório das etapas significativas do projeto.
>
> Antes de começar uma nova etapa, leia a entrada mais recente e `docs/PROJECT-CONTINUITY.md`.
>
> Antes de avançar para outra etapa significativa, registre aqui o resultado da etapa atual.

## Modelo de entrada

Copiar este bloco ao registrar uma nova etapa:

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

## 2026-10-18 — Continuidade entre chats e estado da Run #3

- Fase: infraestrutura/documentação da BMO Linux Base v0.2
- Branch: `feat/bmo-linux-base-v1`
- Commit inicial observado: `5bdaa491ca95719d5adb2fd0dd6dc791984e13d3`
- Objetivo: tornar o estado do projeto recuperável a partir do próprio Git e registrar o ponto exato de retomada do CI.
- `R36S_REQUIRED=NO`

### Ações realizadas

- confirmada a branch dedicada `feat/bmo-linux-base-v1`;
- confirmado o HEAD inicial `5bdaa491ca95719d5adb2fd0dd6dc791984e13d3`;
- revisado `docs/ROADMAP.md`;
- revisado `docs/BMO-LINUX-BASE-DESIGN.md`;
- revisado `AGENTS.md`;
- revisado `README.md`;
- revisado `.github/workflows/build-bmo-linux-base.yml`;
- revisado `image/armbian/build-bmo-linux-base.sh`;
- confirmado que a GitHub Actions Run #3 compilou a imagem e falhou na validação pós-build;
- criado `docs/PROJECT-CONTINUITY.md` com arquitetura, decisões, segurança, hardware, fluxo Git, fases e ponto de retomada.

### Arquivos alterados

- `docs/PROJECT-CONTINUITY.md` criado no commit `e029b13c8368826d2eb8da1271aafa544dd5292e`;
- este `docs/WORKLOG.md` criado nesta etapa.

### Resultado esperado

Um chat/agente novo deve conseguir:

1. abrir a branch correta;
2. entender a arquitetura;
3. conhecer decisões que não devem ser revertidas;
4. saber o estado exato da CI;
5. continuar sem depender da memória do chat anterior.

### Resultado obtido

Estado de CI confirmado:

```text
GitHub Actions Run #3
Run ID: 39166839314
Job ID: 117791440181

Checkout BMO                  SUCCESS
Free runner disk space        SUCCESS
Install host prerequisites    SUCCESS
Build minimal image           SUCCESS
Validate image contents       FAILURE
Compress image and checksum   SKIPPED
Upload image artifact         SKIPPED
```

A compilação principal passou. O bloqueio está na etapa `Validate image contents`.

### Validação

O workflow atual verifica a existência de:

```text
BOOT/BMO-FIRSTBOOT.txt
BOOT/README-FIRST-BOOT.txt
ROOT/usr/local/bin/bmo
ROOT/usr/local/sbin/bmo-firstboot
ROOT/etc/bmo/source.conf
ROOT/etc/NetworkManager/conf.d/20-bmo.conf
ROOT/etc/netplan/90-bmo-networkmanager.yaml
ROOT/etc/udev/rules.d/99-bmo-usb-power.rules
```

Ainda não foi confirmada neste ponto a linha exata do log que encerrou a etapa de validação.

### Pendências / riscos

- não corrigir a validação no escuro;
- não iniciar um novo build apenas por tentativa;
- não marcar a Fase 2 como concluída até CI gerar artifact válido e SHA256;
- nenhuma alteração deve introduzir chave/token/segredo na imagem.

### Próximo passo exato

1. abrir o log do job `117791440181`;
2. localizar o comando/`test` exato que falhou em `Validate image contents`;
3. registrar o diagnóstico em uma nova entrada deste Worklog;
4. aplicar somente a correção mínima necessária;
5. depois disparar nova execução do CI.

```text
R36S_REQUIRED=NO
```

---

## 2026-10-18 — Instrumentação diagnóstica do validator da Run #3

- Fase: BMO Linux Base v0.2 — diagnóstico da validação pós-build
- Branch: `feat/bmo-linux-base-v1`
- Commit inicial: `71e4d64d64820c80cca907063c79439b5c491890`
- Objetivo: tornar explícita a assertion que falha em `Validate image contents` sem alterar o conteúdo, builder ou arquitetura da imagem.
- `R36S_REQUIRED=NO`

### Ações realizadas

- revisado novamente o log disponível da Run ID `39166839314`, Job ID `117791440181`;
- confirmado `Build minimal image = SUCCESS` e `Validate image contents = FAILURE`;
- confirmado que o step atual executa vários `test -n`, `test -f` e `test -x` silenciosos sob `set -euo pipefail`;
- confirmado que o log disponível não permite distinguir qual assertion retornou status 1;
- descartada como causa comprovada a hipótese inicial sobre `/boot/u-boot`, porque no layout upstream R36S esse caminho corresponde ao filesystem FAT montado como BOOT durante a customização;
- mantidos os mesmos requisitos de partição, arquivos e executáveis do validator;
- substituídos testes silenciosos por mensagens explícitas de sucesso/falha;
- adicionada impressão de `lsblk`, partições detectadas e conteúdo da BOOT para diagnóstico;
- nenhuma alteração feita em `image/armbian/**`, firstboot, rede, overlay ou builder.

### Arquivos alterados

- `.github/workflows/build-bmo-linux-base.yml` — somente instrumentação do step `Validate image contents`;
- `docs/WORKLOG.md` — registro deste diagnóstico e da alteração de observabilidade.

### Resultado esperado

A próxima execução do CI deve informar exatamente o primeiro requisito que falhar, por exemplo:

```text
FAIL_MISSING_FILE: /tmp/.../BMO-FIRSTBOOT.txt
```

ou:

```text
FAIL_NOT_EXECUTABLE: /tmp/.../usr/local/sbin/bmo-firstboot
```

sem mudar os critérios funcionais já exigidos pela validação.

### Resultado obtido

- causa funcional da falha da imagem ainda não foi inferida nem corrigida;
- o bloqueio de observabilidade foi identificado: o validator anterior não nomeava a assertion falha;
- preparado validator diagnóstico preservando os mesmos requisitos;
- nenhuma correção por tentativa foi aplicada à imagem.

### Validação

- conferido que os mesmos dois requisitos de partição continuam sendo exigidos: BOOT FAT e ROOT ext4;
- conferido que os mesmos oito requisitos de arquivo/executável continuam sendo exigidos;
- conferido que a mudança não adiciona segredo, credencial ou dependência privada;
- `main` permanece intocada;
- execução CI desta instrumentação: pendente após o commit desta etapa.

### Pendências / riscos

- a causa exata do conteúdo inválido continua desconhecida até a nova execução produzir a mensagem explícita;
- não alterar `image/armbian/**` antes desse diagnóstico;
- não marcar a Fase 2 como concluída até validator, compressão, SHA256 e artifact passarem.

### Próximo passo exato

1. executar/observar a GitHub Actions disparada por este commit;
2. capturar Run ID e Job ID;
3. ler a mensagem explícita do primeiro requisito que falhar em `Validate image contents`;
4. registrar o resultado neste Worklog;
5. somente então aplicar a correção mínima da causa real.

```text
R36S_REQUIRED=NO
```

---

## 2026-10-18 — Hardening da CI em camadas após Run #4

- Fase: CI hardening / validação em camadas da BMO Linux Base v0.2
- Branch: `feat/bmo-linux-base-v1`
- Commit inicial: `65ac1816c7910805129c4866459185026287d411`
- Objetivo: reduzir ciclos caros de build, impedir drift entre expectativa e imagem e obter diagnóstico completo em uma única execução.
- `R36S_REQUIRED=NO`

### Ações realizadas

- confirmada nova falha da Run #4, Run ID `39176142980`, Job ID `117819101367`;
- revisados workflow, builder, customizer, overlay e pins de upstream;
- identificado risco estrutural: critérios de imagem estavam embutidos no YAML e separados dos arquivos-fonte que originam a imagem;
- identificado risco operacional: uma validação pós-build que encerra no primeiro defeito força nova compilação para descobrir defeitos seguintes;
- definido contrato único de requisitos críticos da imagem;
- definida camada de preflight barata e agregada antes do build;
- definida validação pós-build agregada, sem `set -e`, para reportar todos os defeitos contratuais encontrados na mesma imagem;
- definido artifact de diagnóstico independente do artifact final da imagem;
- definido cancelamento de runs obsoletas da mesma branch;
- mantida a imagem funcionalmente inalterada até existir prova da causa funcional da Run #4.

### Arquivos alterados

- `docs/WORKLOG.md` — registro desta etapa de diagnóstico e desenho;
- alterações de CI preparadas e validadas estaticamente, mas ainda não promovidas no início deste registro.

### Resultado esperado

- falhas de estrutura, sintaxe, pins ou segurança devem impedir o build pesado;
- uma imagem construída deve revelar todos os problemas contratuais críticos em uma única validação;
- critérios de conteúdo devem existir em um contrato único, evitando listas divergentes no workflow;
- runs antigas da mesma branch devem ser canceladas quando substituídas por commit novo.

### Resultado obtido

Arquitetura candidata preparada com quatro barreiras:

```text
contrato/estrutura
        ↓
sintaxe + pins + segurança
        ↓
build pesado
        ↓
validação agregada + artifact de diagnóstico
```

A causa funcional específica de conteúdo da Run #4 não é considerada provada apenas pela estrutura atual dos logs e, portanto, nenhum conteúdo da imagem foi alterado nesta etapa.

### Validação

Validação estática local dos candidatos:

```text
bash -n preflight.sh             OK
bash -n validate-image.sh        OK
image-contract.tsv              OK — 8 entradas / destinos únicos
workflow YAML                   OK
assinaturas de segredo          OK
CANDIDATE_STATIC_VALIDATION_OK
```

### Pendências / riscos

- a arquitetura melhora observabilidade e custo, mas não substitui boot/hardware físico no R36S;
- não alterar conteúdo da imagem com base em hipótese;
- a primeira run da arquitetura nova deve ser usada para obter um relatório agregado e corrigir de uma vez somente os defeitos comprovados;
- `docs/ROADMAP.md` permanece inalterado até validação real da etapa.

### Próximo passo exato

1. aplicar a arquitetura de CI em camadas sem alterar conteúdo funcional da imagem;
2. revisar o diff e confirmar que a mudança ficou restrita à engenharia de CI/documentação;
3. commitar na `feat/bmo-linux-base-v1`;
4. confirmar o job de preflight;
5. somente se o preflight passar, executar o build pesado;
6. usar o relatório agregado pós-build para identificar todas as falhas comprovadas;
7. registrar Run ID, Job IDs e resultados no Worklog antes da correção funcional.

```text
R36S_REQUIRED=NO
```
