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
## 2026-10-24 — Correção publicada e Run #8 iniciada

- Fase: Gate 1 / compilação integral e preparação de Ready
- Branch: `feat/bmo-linux-base-v1`
- Commit da correção: `701ed1d7a2946a143cbbd90527f141e0b05c3867`
- Objetivo: validar a FAT final corrigida antes de integrar BMO Ready.
- `R36S_REQUIRED=NO` para CI; `R36S_REQUIRED=YES` para boot.

### Ações realizadas / validação

- Preflight local: 82 verificações, zero falhas; diff revisado.
- Commit publicado por atualização fast-forward com HEAD esperado.
- Run #8: `40057180564`.
- Preflight job `120762624034`: success.
- Build job `120762650098`: in_progress na última consulta (instalando pré-requisitos).
- Usuário confirmou outro microSD disponível para teste físico separado.
- R36S inspecionado somente em leitura por SSH via Potato: kernel `6.12.74-lts-rk3326`, BOOT FAT em `/boot/u-boot`, root ext4, BMO kiosk/UI/control/Xorg e APIs ativos.
- A API 8086 escuta somente em `127.0.0.1`; falha ao acessá-la pela Potato não comprova serviço parado.
- Receita Ready antiga auditada: fase 40 presume zero symlinks em /etc/systemd/system e ausência de /etc/fstab. Esses checks de sandbox não servem para uma imagem Linux populada. Builder também conta todos os links/binários em vez de validar apenas os artefatos BMO. Adaptar preservando fstab/boot e validando somente os arquivos da receita.
- Build antigo local interrompido em apt/dpkg por falta de espaço; não foi retomado nem promovido.

### Arquivos alterados

- `docs/WORKLOG.md`, `docs/PROJECT-CONTINUITY.md` (registro da execução e retomada).

### Resultado esperado / obtido

- Esperado: CI integral válida e depois Ready com boot físico direto no BMO.
- Obtido: correção testada/publicada, preflight remoto aprovado; build integral ainda em andamento.
- Não há nova imagem Ready validada ou artifact final confirmado nesta consulta.

### Pendências / riscos

- Gate 1 continua aberto até o resultado integral.
- Boot da base usa kernel pinado 6.12.32, enquanto o aparelho de referência está em 6.12.74; exigir teste de painel/DTB/gamepad/rede.
- Preservar cartão atual; gravar candidato somente no cartão extra após conferir artifact/SHA256.

### Próximo passo exato

1. Consultar jobs da Run #8 `40057180564` e obter validator/artifact.
2. Registrar resultado antes de avançar.
3. Se Gate 1 passar, adaptar receita Ready às imagens populadas, dimensionar espaço e habilitar firstboot/kiosk sem depender de login manual.
4. Validar offline, gerar candidato e testar no microSD extra.

## 2026-10-24 — Avaliação final da Run #8 / CP-IMAGE-002

- Fase: CI/contrato da Base e revisão de riscos
- Branch: `feat/bmo-linux-base-v1`
- HEAD documental inicial: `da20d54334de52d6bbae42489cd641b17cdb7e17`
- Commit compilado: `701ed1d7a2946a143cbbd90527f141e0b05c3867`
- Objetivo: conferir resultado integral, artefatos, checksum e limites antes do próximo gate.
- `R36S_REQUIRED=NO`

### Ações / validação

- Consultados jobs, artefatos e log completo do job de build.
- Preflight, build, validator, compressão e upload concluídos com success.
- Validator: 16 verificações, zero falhas; oito entradas do contrato aprovadas, inclusive os dois templates na FAT.
- Confirmados artefatos não expirados. Checksums extraídos dos logs da CI, sem alegar download/verificação local da imagem nesta etapa.
- Script `sd_fusing.sh` do pacote público rc2-pancho baixado e inspecionado sem execução: linha 22 é `sudo eject $1`. As linhas 16–18 são dd; upstream remove sudo apenas desses dd. Log mostra três gravações concluídas. Aviso de eject não comprova falha de gravação.
- SHA256 observado do pacote público: `e189c0af783ee0a13e5f375c3f486b9e89a33f4c0721d078fab617f40edb05af`; tag pode ser substituída, portanto hash observado não substitui inspeção binária do artifact.
- Identificado no upstream pinado clone móvel do PanCho/ScreenFiles e download de U-Boot sem checksum imposto. Item de pins externos mantido aberto no roadmap.

### Evidência

```text
Run #8: 40057180564
Commit compilado: 701ed1d7a2946a143cbbd90527f141e0b05c3867
Preflight job: 120762624034 — success
Build job: 120762650098 — success
IMAGE_VALIDATION_CHECKS=16
IMAGE_VALIDATION_FAILURES=0
Artifact imagem: 12547459290
Artifact relatório: 12547750769
Imagem: bmo-linux-base-r36s-trixie-v0.2.img.xz
SHA256 .img.xz: b365b4a976fb81a9dc85fd0536a24a4b980c327414c2d281f2f110afd7f38006
SHA256 .img sem compressão: c1fbc6373d845c704db6b355a0e1f80876eb58ee3a2a84277d1425a238a14056
Artifact ZIP: 420481297 bytes
SHA256 ZIP: be3cb6139373ab327db1c96e9b6943866eb15f7863c83228ffb7202aae2a8314
Artifact expira: 2026-10-31T04:21:41Z
```

### Arquivos alterados

- `docs/WORKLOG.md`
- `docs/PROJECT-CONTINUITY.md`
- `docs/CHECKPOINTS.md`
- `docs/ROADMAP.md`

### Resultado esperado / obtido

- Pipeline integral aprovado, correção da FAT comprovada e checkpoint CP-IMAGE-002 registrado para CI/contrato.
- Não criada/promovida release Ready. Nenhum código funcional alterado nesta avaliação; main e aparelhos preservados.

### Pendências / riscos / próximo passo

1. Baixar e verificar artifact/SHA256 antes da expiração; preservar cópia na Potato e local quando disponível.
2. Fechar auditoria/pins de dependências externas; Gate 1 ainda tem esse item aberto.
3. Boot/firstboot/painel/rede em cartão extra: `R36S_REQUIRED=YES`.
4. Adaptar receita Ready, dimensionar espaço e validar boot automático no BMO; CI verde não equivale a teste físico.

## 2026-10-24 — Primeiro boot físico relatado e orientação TF2

- Fase: Gate 2 / CP-BOOT-001 VALIDATING
- Branch: `feat/bmo-linux-base-v1`
- Commit inicial documental: `0a0b12de0e3432d076036dce34d47fda605322a4`
- Imagem: Run #8, `701ed1d7a2946a143cbbd90527f141e0b05c3867`
- Objetivo: registrar primeiro relato físico e instrução do usuário, preparando validação detalhada.
- `R36S_REQUIRED=YES`

### Ações realizadas

- Usuário informou: instalado, aparentemente funcionou perfeitamente.
- Usuário solicitou registrar que TF2 de Games precisa ficar fora durante o primeiro boot.
- Usuário confirmou SSH ainda desligado; nenhum diagnóstico remoto da nova instalação foi alegado.
- Adicionada orientação no README principal e template README-FIRST-BOOT.txt da BOOT.
- Criado roteiro de testes locais de status/firstboot, armazenamento, rede, hardware, reboot e TF2.
- Marcado somente boot inicial no roadmap; demais testes continuam pendentes.
- CP-BOOT-001 permanece VALIDATING, sem declarar funcionamento completo.
- Commit documental usa [skip ci] para não disparar rebuild pesado por mudança de texto.

### Arquivos alterados

- `README.md`
- `image/armbian/userpatches/overlay/usr/share/bmo/README-FIRST-BOOT.txt`
- `docs/BASE-FIRSTBOOT-TESTS.md`
- `docs/PROJECT-CONTINUITY.md`
- `docs/CHECKPOINTS.md`
- `docs/ROADMAP.md`
- `docs/WORKLOG.md`

### Resultado esperado / obtido / validação

- Orientação de usar somente TF1 no primeiro boot documentada; desligar completamente antes de reinserir TF2.
- Não formatar nem alterar TF2. Causa técnica da necessidade ainda não diagnosticada.
- Fonte da evidência física: relato do usuário; saídas de doctor/status ainda não recebidas.
- Revisão documental: copiar ScreenFiles preservado, sem credenciais e sem instruções de escrita no TF2.
- Alteração no template aparecerá em builds futuros; artifact da Run #8 e cartão já gravado não são modificados por este commit.
- Nenhum serviço/rede/boot do aparelho foi alterado.

### Pendências / próximo passo

1. Receber `bmo status`, `bmo firstboot status`, `bmo doctor`, serviços falhando do terminal local.
2. Validar root/BOOT, rede, gamepad, áudio, brilho e reboot conforme roteiro.
3. Validar TF2 após desligamento; registrar diferenças antes de diagnóstico causal.
4. Só fechar checkpoint com evidências; depois preparar integração Ready.
