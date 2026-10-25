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

### CP-IMAGE-002 — CI e contrato da Base aprovados

```text
STATUS=SAFE
SCOPE=CI_AND_IMAGE_CONTENT_CONTRACT
BRANCH=feat/bmo-linux-base-v1
R36S_REQUIRED=NO
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

Evidências:
- [Run #8](https://github.com/williamandrade01wa-lab/BMO_R36S/actions/runs/40057180564)
- [Imagem + checksum](https://github.com/williamandrade01wa-lab/BMO_R36S/actions/runs/40057180564/artifacts/12547459290)
- [Relatório](https://github.com/williamandrade01wa-lab/BMO_R36S/actions/runs/40057180564/artifacts/12547750769)

Na mesma run passaram preflight, build, contrato, compressão, checksum e upload.
Os dois templates ausentes na Run #7 estão agora na FAT e passaram no validator.

Limites do checkpoint:
- boot físico, firstboot, painel, hardware e BMO Ready ainda não validados nesta imagem;
- contrato atual tem oito entradas de arquivos, não comprova toda a execução do sistema;
- upstream clona ScreenFiles/PanCho sem commit fixo e baixa U-Boot por tag sem checksum imposto; auditoria de pins externos permanece pendente no Gate 1;
- `sd_fusing.sh:22: sudo: not found` corresponde a `sudo eject $1`, após três gravações dd e sync. Pacote público rc2-pancho inspecionado, SHA256 observado `e189c0af783ee0a13e5f375c3f486b9e89a33f4c0721d078fab617f40edb05af`. Não é evidência de falha do dd nem substitui teste de boot.

Retorno seguro: usar o commit compilado e os hashes acima; não promover para main nem chamar de Ready/release pública somente por este checkpoint.

## Checkpoints planejados

### CP-BOOT-001 — Em validação física

```text
STATUS=VALIDATING
IMAGE_RUN=40057180564
IMAGE_COMMIT=701ed1d7a2946a143cbbd90527f141e0b05c3867
R36S_REQUIRED=YES
```

Em 2026-10-24, usuário confirmou que gravou a imagem e o R36S iniciou, aparentemente funcionando perfeitamente. Evidência: relato do usuário; ainda não foram coletados status/doctor/logs. SSH desligado.

Regra observada a documentar: TF2 de jogos deve ficar fora durante todo o primeiro boot. Após configurar, desligar completamente antes de reinserir TF2. Causa técnica ainda não diagnosticada.

Fechar este checkpoint somente quando cartão limpo comprovar:

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

## CP-BETA-001 — Ready beta integrada, aguardando teste no cartão extra

```text
STATUS=VALIDATING
SCOPE=OFFLINE_CONTENT_VERIFIED_PHYSICAL_BOOT_PENDING
BRANCH=feat/bmo-linux-base-v1
SOURCE_COMMIT=17d07a9350bc5db8a4bda4838eb3e34f97f24ca7
R36S_REQUIRED=YES
IMAGE=BMO-R36S-Ready-v1.0.0-beta.1.img.gz
GZIP_BYTES=2016381902
GZIP_SHA256=e21a446dccfde7e115a8e0cf79ae251d41aca02f3edfb4c274e4bc405b1794a7
RAW_BYTES=12884901888
RAW_SHA256=b7a9ab2567084f42da2c6a7628fbacd68c683ff120f64dca54fc252f15e35f7e
```

Em 2026-10-24, Base #9 foi integrada ao BMO/RetroArch/PPSSPP/Moonlight e dependências. Passaram pins específicos da beta, Apply v3, fases 40/50/60, systemd-analyze offline, bibliotecas PPSSPP, contrato beta e sanitização. Arquivo transferido ao PC e validado por gzip CRC e SHA256 raw completo. Entregáveis e base original preservados localmente; arquivos grandes temporários removidos da Potato por instrução explícita do usuário.

Este checkpoint não declara boot, hardware nem abertura física do kiosk desta beta. O relato de boot da Base #8 não se aplica automaticamente à Ready beta. Testar cartão extra de 16 GB+, configurar pelo assistente BOOT, TF2 fora no primeiro boot; depois desligar antes de recolocar TF2. Retorno seguro: cartão anterior preservado; não promover main.
