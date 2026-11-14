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


## CP-LIGHT-001 — Conteúdo e integridade offline, validação física pendente

```text
STATUS=VALIDATING
SCOPE=OFFLINE_CONTENT_HASH_VERIFIED_PHYSICAL_BOOT_PENDING
BRANCH=feat/bmo-linux-base-v1
CORE_SOURCE_COMMIT=91a8139690404fb544174b56e980bc12cc43ebf2
CI_RUN=40159128087
R36S_REQUIRED=YES
IMAGE=BMO-R36S-Light-v0.1.0.img.xz
XZ_BYTES=424096916
XZ_SHA256=f890fb74311145f943a9a43bf6527892dff899a871ee003fce388382068e87a2
RAW_BYTES=2386558976
RAW_SHA256=a7f87a6b52d43f0e72f1d4020e097f4d25263add43b0f699ef52b243633d2193
```

Finalizador local v02 validou 79 arquivos na ext4, injetou runtime PPSSPP pinado e logo no FAT com leitura de volta, preservou hash root e verificou SHA raw após descompressão XZ integral. Uso root 1402290176 bytes. Pacotes BMO grandes continuam para instalação online após expansão do SD. Sem teste físico concluído.

Limite conhecido: esta candidata contém assistente v0.2.0, que falha no Windows PowerShell ao criar a raiz existente da unidade. Preparar cartão com assistente v0.2.1 externo ou reinjetar correção antes de nova entrega integrada. Não anunciar como release pronta. Retorno seguro: cartão anterior e Ready beta preservados; main intocada.


### Atualização física CP-BETA-001 — 2026-10-25

Assistente v0.2.1 e primeiro boot da Ready confirmados pelo usuário. SSH em <R36S_IP> validado com chave; firstboot.done, kiosk/UI/control-api ativos, UI HTTP200, zero failed. Tradução Chromium eliminada com política e confirmação visual do usuário. Root 12G e ausência de marker Light identificam teste da Ready, sem validar candidata Light.

STATUS=VALIDATING; R36S_REQUIRED=YES. Bloqueio atual: sem áudio em paplay e ALSA direto; Jack informa fone presente sem plugue. Selecionar SPK/50% não resolveu. Não houve troca DTB/kernel nem teste com fone. Próximo: estado DAPM e comparação com áudio do sistema anterior. Não declarar BMO completo ou release estável.


## CP-AUDIO-001 — Efeitos das carinhas na Ready confirmados

```text
STATUS=SAFE_PARTIAL
SCOPE=BMO_FACE_EFFECTS_PHYSICAL_CONFIRMATION_ONLY
SOURCE_COMMIT=7720902740afac95fb53d97c0637a0a8c88e5279
BRANCH=feat/bmo-linux-base-v1
VALIDATED_ON=2026-10-25
HOST=bmo-r36s <R36S_IP>
KERNEL=6.12.32-lts-rk3326
SOUND_FILES=12
SOUND_BYTES=2183032
R36S_REQUIRED=YES
```

Após instalar os WAV preservados e restaurar Playback Mux=HP, usuário confirmou os efeitos ao apertar botões que mudam carinhas. Conferência SSH: 12 hashes iguais a assets/sounds/SHA256SUMS, root:root 0644, quatro serviços principais/áudio ativos, zero failed. Backup: /var/backups/bmo/sounds-20261025-015336-3405. Sem troca de kernel/DTB.

Gate parcial: ainda testar persistência após reinício, áudio em jogos/streaming e Light. CP-BETA-001 continua VALIDATING, main preservada. Retorno: cartão original intacto e backup do patch; não declarar BMO completo nem release estável.
