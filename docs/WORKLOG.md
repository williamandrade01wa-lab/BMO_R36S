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

## 2026-10-24 — Primeiro boot simples, resumo de rede/IP/SSH e atualização offline

- Fase: UX do firstboot / Gate 2
- Branch: `feat/bmo-linux-base-v1`
- Commit inicial: `f59368cb0512158aaba39c9ad55faa0db00f5740`
- Objetivo: pessoa leiga configurar e ver conexão/IP sem enviar saídas de vários comandos.
- `R36S_REQUIRED=NO` para testes isolados; `R36S_REQUIRED=YES` para validação visual final.

### Ações realizadas

- Template reduzido a quatro campos em português: REDE_WIFI, SENHA_WIFI, SENHA_USUARIO, ACESSO_REMOTO.
- Nome de Wi-Fi preenchido ativa Wi-Fi automaticamente se WIFI_ENABLED não foi informado. Cabo continua DHCP por padrão; SSH permanece desligado por padrão.
- Parser aceita aliases e sim/nao, preservando chaves avançadas antigas. Duplicidade alias/chave antiga é recusada.
- Suporte a UTF-8 BOM e CRLF do Windows; valores permanecem literais, sem executar Shell.
- Senhas dos dois formatos sanitizadas, inclusive BOM antes da primeira chave.
- Console mostra conclusão/atenção, conexão local ou ausência de IP, IPs e SSH ligado/desligado/falha; não declara internet testada.
- BOOT recebe BMO-RESUMO.txt e os arquivos técnicos existentes continuam.
- Adicionado --summary somente leitura; perfil interativo reapresenta status com IP atual após login/reboot. Aviso antes do reboot de resize com pausa de oito segundos.
- Ativação de conexão tem espera explícita de 20s; SSH só é exibido ligado se o serviço estiver ativo.
- Evitado vazamento de senha em CalledProcessError do nmcli: mensagem pública não reproduz a linha de comando com PSK.
- Instalador offline permite atualizar o cartão da Run #8 sem regravar: cria backup, preserva configuração atual e senhas, não aplica firstboot nem reinicia rede; modelo simples fica separado.
- Nenhuma configuração da nova instalação do usuário foi alterada remotamente; SSH nela continua desligado.

### Arquivos alterados

- `image/armbian/userpatches/overlay/usr/local/sbin/bmo-firstboot`
- `image/armbian/userpatches/overlay/usr/share/bmo/BMO-FIRSTBOOT.txt`
- `image/armbian/userpatches/overlay/usr/share/bmo/README-FIRST-BOOT.txt`
- `image/armbian/userpatches/overlay/etc/profile.d/90-bmo-welcome.sh`
- `image/armbian/userpatches/customize-image.sh`
- `image/armbian/userpatches/rk3326/R36S/armbian-firstlogin`
- `image/armbian/ci/image-contract.tsv`
- `image/armbian/ci/preflight.sh`
- `image/armbian/ci/tests/test_firstboot_ux.py`
- `scripts/offline/bmo-update-firstboot-ux.sh`
- README, design da Base, roteiro de testes, continuidade e este Worklog.

### Resultado esperado / obtido

- Fonte preparada para imagem futura e atualização offline entregue para testar no cartão já instalado.
- Sem prometer atualização automática da imagem da Run #8, sem afirmar validação física desta nova tela.
- Sessão de login reapresenta status atual; BMO-RESUMO.txt é o resumo persistido no firstboot/atualização offline.

### Validação

- 19 testes isolados passaram: formato simples/legado, BOM/CRLF, literais, aliases duplicados, sanitização, sem IP, IP local, SSH falhando/desligado, segredos em erros e --summary sem mutação.
- Preflight em checkout isolado na Potato: 89 verificações, zero falhas.
- bash -n / sh -n e git diff --check aprovados.
- Atualizador offline testado duas vezes em raiz temporária: backup preservado, hashes de configuração e shadow inalterados, alvo inválido recusado.
- Testes não executaram configuração real de rede/usuários no host.
- Evidência: `/home/hipo/bmo/firstboot-ux-preflight.log` e fixtures `/home/hipo/bmo/welcome-update-test.*`.

### Pendências / próximo passo exato

1. Publicar a alteração na branch e registrar a CI disparada.
2. Usuário copiar atualizador para BOOT e executar uma única vez; conferir visualmente o resumo e IP.
3. Validar imagem nova quando CI concluir; manter CP-BOOT-001 em VALIDATING até evidências de reboot/rede/hardware.
4. Continuar integração Ready após este primeiro boot mais simples, preservando regra TF2 fora e cartão original.

## 2026-10-24 — CI da nova UX iniciada

- Fase: validação integral da imagem com primeiro boot simples
- Branch: `feat/bmo-linux-base-v1`
- Commit compilado: `946353e66bfb48ef4d739aea532d87ebf43460e4`
- Objetivo: validar empacotamento do novo resumo/perfil na imagem.
- `R36S_REQUIRED=NO` para CI; `R36S_REQUIRED=YES` para tela real.

### Ações / resultado / validação

- Publicados código, 19 testes, documentação e atualizador offline.
- Run #9: `40118103143`.
- Preflight job `120943560799`: success.
- Build job `120943591400`: in_progress na consulta.
- Atualizador offline validado em raiz isolada, não aplicado remotamente ao R36S do usuário.

### Arquivos alterados

- Continuidade e este registro; nenhum código funcional adicional nesta anotação.

### Pendências / próximo passo

- Usuário testar atualização offline para ver o IP/SSH sem regravar o cartão.
- Consultar resultado final da Run #9; não declarar nova imagem pronta enquanto build/contrato/artifact pendentes.
- Depois validar tela/reboot e continuar Ready.

## 2026-10-24 — Modo preguiça: assistente de preparação do cartão no Windows

- Fase: UX da preparação / Gate 2
- Branch: `feat/bmo-linux-base-v1`
- Commit inicial: `c04ef2e25e4d3f3b32ba99d5f9062b3c0ee6e61f`
- Objetivo: preparar cartão com perguntas/opções sem editar TXT nem copiar ScreenFiles manualmente.
- `R36S_REQUIRED=NO` para testes locais; `R36S_REQUIRED=YES` para boot final.

### Ações realizadas

- Criado assistente offline Windows Forms com conversa, opções e botão Voltar.
- Seleção de BOOT validada por ScreenFiles/boot.ini; listagem real dos painéis do cartão.
- Perguntas condicionais de rede: Wi-Fi com senha/aberto, cabo automático ou sem rede.
- Senha do aparelho com confirmação e SSH opcional; senhas mascaradas e ausentes do histórico/resumo.
- Geração de chaves legadas compatíveis com parsers antigo e novo; sem aspas; valores literais e UTF-8 sem BOM/LF no TXT.
- Recusados quebras de linha, sentinelas de senha e espaços nas extremidades que o parser antigo removeria.
- Cópia de ScreenFiles preserva fonte, verifica SHA256, cria backup e restaura arquivos em falha; paths/reparse points/destinos fora da BOOT recusados.
- Nada gravado antes do resumo final; sem formatação, sem alterações no TF2.
- Aviso de usar antes do primeiro boot e de que editar TXT não reaplica um cartão já configurado.
- Launcher .cmd para dois cliques e ZIP com três arquivos.
- Criada CI leve Windows restrita a scripts/windows; não dispara/reinicia o build pesado da imagem.

### Arquivos alterados

- `scripts/windows/BMO-Preparar-Cartao.ps1`
- `scripts/windows/ABRIR-BMO.cmd`
- `scripts/windows/LEIA-ME.txt`
- `.github/workflows/test-windows-card-wizard.yml`
- `README.md`, `docs/PROJECT-CONTINUITY.md`, `docs/WORKLOG.md`.

### Resultado esperado / obtido

- Interface funcional de preparação com painel escolhido pelo usuário, revisão e gravação com backup.
- Pacote BMO-Modo-Preguica.zip gerado e conferido (launcher, PS1, instruções).
- Testes somente em diretórios temporários; nenhum cartão real ou sistema Linux modificado.
- Assistente não detecta qual painel físico o aparelho usa; não marca boot/hardware como validados.
- Artefatos das imagens #8/#9 não são alterados por esta ferramenta.

### Validação

- 23 verificações locais passaram: descoberta, caracteres literais/Unicode, LF/UTF-8, cópia, preservação de fonte, backup, rollback, modos de rede e recusas de entradas inválidas.
- Fluxo gráfico completo exercitado em fixture: senha mascarada, nenhuma senha no transcript, nenhuma gravação antes da confirmação e TXT criado após confirmar.
- Janela renderizada/inspecionada visualmente; campos, instruções e botões visíveis.
- Compatibilidade: quatro modos de rede lidos corretamente por dois parsers reais do Git (Run #8 e UX nova), oito combinações aprovadas.
- ZIP: CRC e exatamente três arquivos conferidos.
- Corrigido durante teste uso de Move-Item em destino com colchetes; escrita final usa File.Copy com backup/rollback.

### Pendências / próximo passo exato

1. Registrar resultado da CI Windows.
2. Usuário testar em BOOT real do cartão extra, selecionar ScreenFiles conhecidas e revisar configurações.
3. Testar boot sem TF2 e mensagem com IP/SSH.
4. Manter validação física/Ready pendentes até evidência.

## 2026-10-24 — CI Windows do assistente aprovada

- Fase: validação Windows / preparação do cartão
- Branch: `feat/bmo-linux-base-v1`
- Commit testado: `f4469114b6a0d74c50d2fbfb007bddf20dac301d`
- Objetivo: conferir testes de cópia/configuração/rollback no runner Windows.
- `R36S_REQUIRED=NO`

### Ações / resultado / validação

- Run `40141713783`, workflow Test Windows Card Wizard.
- Job `121014650099`: success; todos os passos concluídos.
- Testes de preparação e recuperação executados em diretórios temporários, sem cartão real.
- Pacote final local BMO-Modo-Preguica.zip conferido com CRC e arquivos esperados.
- Na consulta de runs, a imagem #9 `40118103143` também consta success; avaliação detalhada de logs/artifacts da #9 ainda não realizada nesta etapa.

### Arquivos alterados

- Continuidade e Worklog, somente registro documental.

### Pendências / próximo passo

- Teste do assistente em BOOT real do microSD extra e validação de boot com TF2 fora.
- Conferir nova mensagem/IP/SSH da imagem #9 ou atualização offline.
- Nenhum gate físico foi concluído automaticamente pela CI Windows.

## 2026-10-24 — Preparação do primeiro BMO Ready Beta com componentes pré-instalados

- Fase: integração Ready / build offline em cópia da imagem
- Branch: `feat/bmo-linux-base-v1`
- HEAD inicial: `5ee270cf24826f19118155651f9c17b7d95ecaec`
- Objetivo autorizado: beta que já contenha BMO e dependências antes do primeiro boot e abra diretamente no kiosk.
- `R36S_REQUIRED=NO` para montagem/validação offline; `R36S_REQUIRED=YES` para promoção após teste físico.

### Diagnóstico / ações realizadas

- Run #9 `40118103143` aprovada em preflight/build/contrato/compressão/upload.
- Artifact Base #12571667623 baixado para a Potato; ZIP SHA256 `b496baa785145fb4a2b222e08121d669b3e0f8ff8f7658039a8272eb77981e88` conferido.
- Integridade ZIP e checksum interno .img.xz conferidos na Potato; Base original preservada.
- Runtime PPSSPP local SHA256 `1af91efd8374a2c164e5f2ffa37b3d65980b825a207cbb09c688b2997088c5ad` conferido contra manifest.
- Checkout separado de beta criado na Potato; sem mudanças nos cartões ou sistemas em uso.
- Confirmado bloqueio da receita antiga: checks de sandbox sobre raiz vazia não servem para uma imagem populada.
- Identificadas dependências adicionais do kiosk (xdpyinfo/xauth/unclutter/dbus/Xorg) e áudio PulseAudio, requerido pela configuração RetroArch auditada.
- Planejado firstboot automático por systemd antes do kiosk, sem exigir login manual. Configuração de rede/senhas continua na BOOT.
- Nenhuma imagem Beta final foi declarada pronta nesta etapa.

### Arquivos alterados

- Apenas este registro inicial; adaptação da receita será registrada após testes.

### Resultado esperado / validação / riscos

- Reutilizar Base #9 validada e receitas auditadas, reservando espaço antes do apt.
- Imagem deve conter fontes/versões/hashes manifestados, assistente Windows, sem ROMs/segredos.
- Build nativo na Potato sobre arquivo de imagem; não instalar pacotes do beta no host.
- Boot/hardware ainda exigirão cartão extra e TF2 fora no primeiro boot.

### Próximo passo

- Adaptar montagem e serviços, testar em alvo isolado, iniciar build persistente, validar conteúdo/serviços/binários antes de comprimir.

## 2026-10-24 — Receita BMO Ready beta e integração offline testadas

- Fase: implementação do candidato Ready 1.0.0-beta.1
- Branch: `feat/bmo-linux-base-v1`
- Objetivo: BMO e dependências instalados antes do boot, firstboot automático e abertura do kiosk.
- `R36S_REQUIRED=NO` para fixture/build; `R36S_REQUIRED=YES` para validar o candidato.

### Ações / resultado

- Builder nativo de imagem criado com Base #9 pinada por hash, workdir novo, partição root da cópia ampliada a 12 GiB antes do apt.
- Mantida FAT, bootloader, kernel, fstab/UUIDs. Runtime PPSSPP pinado e verificado.
- Fase 40 reaproveitada em staging vazio e aplicada ao alvo; fase 50 habilita units sem contagem global.
- Primeiro boot por systemd antes dos dez serviços BMO; remove dependência do login interativo/root autologin.
- Áudio PulseAudio via user manager/linger e socket esperado pelo runtime.
- TF2 opcional detectado separadamente do root, apenas exFAT/FAT com EASYROMS; sem formatação ou edição de partições.
- Pacotes/runtime completos e Windows wizard previstos na imagem antes de ligar.
- Builder bloqueia sockets systemd/D-Bus do host, verifica manifests/binários/units, sanitiza e comprime em um thread.
- Montagem integral ainda não executada nesta anotação.

### Validação

- bash -n passou nos scripts novos.
- Fixture real de filesystem temporário: fstab preservado, unit/symlink existente preservado, kiosk e firstboot habilitados, áudio/drop-ins presentes; BMO_BETA_INTEGRATION_FIXTURE_OK.
- Validações source SHA da fase 40 passaram.
- Nenhum cartão físico ou serviço em produção foi alterado pelos testes.
- Avisos da fixture sobre targets ausentes são esperados na raiz mínima; a imagem real será verificada com systemd-analyze.

### Arquivos

- install/build-beta-image.sh e install/beta/**.
- docs/BETA-BUILD.md, continuidade e Worklog.

### Pendências / próximo passo

- Publicar receita e executar build persistente na Potato a partir do commit.
- Corrigir somente falhas comprovadas de pacotes/integração.
- Validar/comprimir, conferir SHA256 e entregar candidato para o microSD extra.
- Registrar resultado antes do teste físico.

## 2026-10-24 — Recuperação após desligamento, IP fixo e correções antes de remontar a beta

- Fase: montagem Ready beta / diagnóstico comprovado
- Branch: `feat/bmo-linux-base-v1`
- Primeiro código de build: `85abb0669f89f5201977b1d2ce8dd08c7769b317`
- `R36S_REQUIRED=NO` para correções/testes de montagem.

### Diagnóstico / ações

- Usuário informou desligamento acidental da Potato. Ela reiniciou; build ficou inactive durante unpack de pacotes. Unit transient não retoma após desligamento da máquina.
- Saúde atual: 51 °C, 1,3 GB RAM disponível, swap zero, 40 GB livres, zero units failed, root rw, contador EXT4 errors_count=0; sem evidência de dano ao host nos dados coletados.
- IP real confirmado por hostkey: 192.168.1.62. Conforme pedido do usuário, configurado USB Ethernet com IP fixo 192.168.1.50/24, gateway 192.168.1.1, DNS 8.8.8.8/9.9.9.9.
- ARP probe sem conflito observado; backup /root/network-backups/ip50-20261025T010531Z; rollback temporizado armado e cancelado após SSH/gateway/DNS aprovados no novo IP.
- Log do build comprovou uma chamada de firstboot no chroot: fase 60 usa bash -lc para configurar Moonlight, e o marcador Armbian da imagem disparou firstlogin. Host permaneceu lepotato/networkd; a falha ocorreu no alvo isolado.
- Builder passa a remover o marcador interativo antes do apt e instalar firstboot com guarda de build; firstboot não altera usuário/rede enquanto o marcador .bmo-ready-build-root existir.
- Corrigidas strings com backslash+n literal na UX de resumo/status; agora são quebras de linha reais.
- Adicionados testes de roundtrip de BMO-STATUS/BMO-IP, linhas reais no stdout e bloqueio de apply durante build.
- Atualizada fonte embutida no atualizador offline.
- Builder limpa relatórios BOOT e estado do firstboot antes de empacotar, evitando IP/estado observado no ambiente de build.
- O working image interrompido não será promovido; a remontagem usa cópia limpa da Base #9 preservada.

### Arquivos

- install/build-beta-image.sh.
- image/armbian/userpatches/overlay/usr/local/sbin/bmo-firstboot.
- image/armbian/ci/tests/test_firstboot_ux.py.
- scripts/offline/bmo-update-firstboot-ux.sh.
- Continuidade e Worklog.

### Validação

- 22 testes passaram em ambiente isolado, incluindo os três novos regressivos.
- Preflight no checkout de teste: 89 verificações, zero falhas.
- bash -n e git diff --check aprovados.
- Sem alteração no kernel, DTB, frontend ou runtime auditado.
- Commit usa [skip ci] para evitar recompilar kernel sem necessidade; a montagem nativa da beta é retomada a partir do commit corrigido.

### Próximo passo

1. Publicar correção, clone limpo e novo workdir ready-beta1-r2-20261024.
2. Executar serviço persistente bmo-ready-beta1-build-r2 na Potato agora em .50.
3. Validar pacote/units/dependências/sanitização e comprimir antes de entregar.

## 2026-10-24 — Remontagem limpa r2 iniciada após recuperação

- Fase: montagem integral da Ready beta
- Branch: `feat/bmo-linux-base-v1`
- Commit executado: `94c151db8be8ac6e393a998d2220526db13a65fe`
- `R36S_REQUIRED=NO` para montagem.

### Execução / evidência

- Checkout limpo: /home/hipo/bmo/BMO_R36S-beta-build-r2-20261024.
- Unit: bmo-ready-beta1-build-r2.service.
- Invocation ID: adfa18ac05b5486b8a64ae3165fe4d7b.
- Log: /home/hipo/bmo-images/beta-1.0.0/build-r2.log.
- Work: /home/hipo/bmo-builds/ready-beta1-r2-20261024.
- Inputs Base raw e PPSSPP verificados novamente com sucesso após o desligamento.
- Na consulta: active/running, preparando cópia da imagem.
- IP fixo 192.168.1.50 validado; rollback cancelado após conexão/gateway/DNS aprovados.

### Arquivos alterados

- Apenas este registro documental.

### Próximo passo

- Acompanhar a execução, validar conteúdo/units e sanitização; depois comprimir e entregar SHA256.
- Não tratar a candidata como pronta até o fim do processo e verificação do arquivo.

## 2026-10-24 — Segunda interrupção por contato de energia confirmado pelo usuário

- Fase: diagnóstico e retomada Ready beta; branch feat/bmo-linux-base-v1.
- Código: 94c151db8be8ac6e393a998d2220526db13a65fe; R36S_REQUIRED=NO.
- r2 interrompida durante unpack de mesa-libgallium. Host reiniciou; serviço transient inactive. Usuário confirmou movimentação e mau contato, e manterá equipamento sem mexer.
- Diagnóstico: 50 °C, 1,3 GB RAM disponível, swap zero, 38 GB livres, zero unidades failed, contador EXT4 errors_count=0. Gateway responde 3/3, USB mantém 192.168.1.50. Sem registro de panic/OOM ou erro de I/O nos dados disponíveis; causa elétrica não inferida apenas do log.
- Esperado/obtido: host acessível e sem evidência de dano; imagem final ainda inexistente. Imagens de trabalho interrompidas não são candidatas.
- Arquivos alterados: Worklog e continuidade operacional.
- Próximo passo: nova montagem limpa r3 a partir da Base raw verificada, mesmo código corrigido, novo workdir; acompanhar até validação e compressão.
- Risco: novo mau contato interrompe o trabalho. Não promover como pronta antes das verificações finais.

## 2026-10-24 — Montagem limpa r3 em execução

- Fase: montagem Ready beta; branch feat/bmo-linux-base-v1; código 94c151db8be8ac6e393a998d2220526db13a65fe.
- Unit bmo-ready-beta1-build-r3.service; invocation c91068a8140a4988bd20492dcbe6d865.
- Workdir /home/hipo/bmo-builds/ready-beta1-r3-20261024; log /home/hipo/bmo-images/beta-1.0.0/build-r3.log.
- Base raw e runtime PPSSPP passaram SHA256 novamente. Cópia limpa concluída; instalação de dependências em andamento no alvo isolado. Host não reiniciou nesta tentativa até a consulta.
- Resultado esperado: candidato completo com verificações offline, sanitização, xz e checksum. Resultado obtido: em execução, sem imagem final pronta.
- Arquivos alterados: apenas documentação. R36S_REQUIRED=NO para build; YES para validação física posterior.
- Pendência/risco: manter conector de energia imóvel; não usar imagens de trabalho interrompidas.
- Próximo passo: acompanhar instalação, corrigir falhas comprovadas, verificar e entregar o arquivo final.

## 2026-10-24 — r3 parou corretamente em manifesto histórico divergente

- Fase: integração Ready beta; branch feat/bmo-linux-base-v1; código inicial 94c151db8be8ac6e393a998d2220526db13a65fe. R36S_REQUIRED=NO para validação offline.
- Objetivo: manter integridade do conteúdo atual sem reverter funcionalidades posteriores ao freeze de 17/10.
- Resultado: pacotes/RetroArch/Moonlight/PulseAudio concluídos; instalador bloqueou frontend atual 946f7596... versus manifesto histórico ba55304d.... Sem novo reinício.
- Auditoria: manifests históricos também divergem em game launcher e Moonlight launcher. Compare desde 613fb076 confirma fallback de ROMs locais/detecção de mount sem UUID fixo e host Moonlight configurável, alterações já versionadas. Backend, outros onze runtime arquivos e configs de emulador passam os pins existentes. Frontend production/candidate idênticos, com marcadores das funções preservadas.
- Arquivos: novos install/beta/ready-beta.env e runtime-bin.sha256 pinam exatamente o conteúdo do commit 94c151d; --beta-pins no instalador é opt-in e exige marcador da imagem em apply. Manifestos históricos intactos; sem editar frontend/launchers.
- Builder usa pins beta e permite --resume-work somente em diretório/imagem regular existente de 12 GiB, com marcador do build, arquitetura/base válidas, e2fsck e dpkg audit. Reexecuta instalação/verificação; mantém backups originais de resolv/policy entre retomadas. Destino / continua bloqueado.
- Validação: treze hashes runtime beta OK, quatro configs emulator OK, dry-run completo BMO_READY_INSTALL_DRY_RUN_OK, bash -n e diff --check OK. Revisão de diff identificou e corrigiu mkdir existente e preservação dos backups na retomada.
- Esperado: retomar somente r3, parada limpa por checksum; não reutilizar r1/r2 interrompidas por energia.
- Próximo passo: publicar pins/correção, clone limpo, retomar r3 via serviço separado, validar conteúdo/units/sanitização, comprimir e conferir checksum antes de entregar. Gate físico continua pendente.

## 2026-10-24 — Integração Ready beta concluída e candidata em compressão

- Fase: build offline Ready 1.0.0-beta.1; branch feat/bmo-linux-base-v1; código 17d07a9350bc5db8a4bda4838eb3e34f97f24ca7. R36S_REQUIRED=NO para build, YES para boot físico.
- r4: bmo-ready-beta1-build-r4.service, invocation 2c02ac000c4e499d9d6d412f30234c61, log /home/hipo/bmo-images/beta-1.0.0/build-r4.log. Retomada somente de r3 parada limpa.
- Base/runtime SHA aprovados, e2fsck/arquitetura/marcador/dpkg audit aprovados antes da retomada. Pacotes idempotentes conferidos.
- Log confirmou FRONTEND_IDENTICAL=YES, BMO_READY_INSTALL_APPLY_V3_OK, fases 40/50/60 OK, BMO_BETA_SYSTEM_INTEGRATION_OK, BMO_BETA_OFFLINE_CONTRACT_OK e BMO_READY_PHASE70_SANITIZE_OK.
- systemd-analyze offline, comandos de execução e dependências PPSSPP aprovados. Zero ROMs, limpeza de credenciais/estado/relatórios de build executada.
- Resultado esperado/obtido: conteúdo integrado e verificado; em xz -T1 -3, arquivo final ainda não pronto nesta anotação.
- Host 54 °C, 34 GB livres; sem novo reinício observado. Imagens de tentativas interrompidas por energia não usadas.
- Arquivos alterados: continuidade e Worklog documental.
- Próximo passo: aguardar BMO_READY_BETA_IMAGE_OK, conferir xz/checksum/manifest, copiar e verificar localmente, entregar candidata sem promover gate físico.

## 2026-10-24 — Empacotamento paralelo da candidata já validada

- Fase: compressão da Ready beta; branch feat/bmo-linux-base-v1; conteúdo gerado pelo commit 17d07a9350bc5db8a4bda4838eb3e34f97f24ca7. R36S_REQUIRED=NO.
- Compressão -T1 mostrou apenas 864,9 MiB lidos em 5:31. Alterada somente a execução de empacotamento para xz -T4 -3 --memlimit-compress=512MiB --check=crc64, mantendo o raw validado, desmontado e de 12 GiB.
- Serviço r4 parado durante xz; xz apagou sua saída parcial ao receber TERM, preservando o raw. Nova unit bmo-ready-beta1-package.service, invocation fe6b3275269241c6b07201e9b77e70af, log /home/hipo/bmo-images/beta-1.0.0/package.log.
- Script operacional /home/hipo/bmo-builds/package-beta1-checked.sh exige raw existente/tamanho e saída final ausente; executa compressão, xz -t, SHA256 e manifesto com parâmetros reais. Pré-condição manual: contrato offline e sanitização OK no log r4.
- Resultado observado: processo ativo, 196 MB RSS, 61 °C; conteúdo da imagem não alterado. Receita de build no Git mantém default conservador -T1; esta substituição operacional consta no manifesto final.
- Arquivos alterados no Git: somente documentação. Resultado esperado: artefato final íntegro com checksum, ainda pendente.
- Próximo passo: acompanhar empacotamento, verificar e copiar para entregáveis locais. Futuras betas podem migrar montagem ao GitHub Actions ARM64; imagem base já é gerada na CI.

## 2026-10-24 — Usuário priorizou Git/PC e economia de armazenamento da Potato

- Fase: migração do empacotamento; branch feat/bmo-linux-base-v1; R36S_REQUIRED=NO.
- Instrução explícita: economizar armazenamento da Potato e focar Git ou PC local por enquanto. Registrada em AGENTS.md, commit 3e5f814338e2433b583ae310898b1a6ada61c550.
- Compressão na Potato parada. Candidata validada raw preservada enquanto transfere por gzip em fluxo, sem novo arquivo grande remoto. PC tem aproximadamente 39,9 GB livres.
- Transferência calcula SHA256 do raw na origem; destino verifica CRC gzip e raw SHA256, comprime em xz localmente, descomprime e compara SHA256 novamente antes da entrega.
- Scripts locais work/export-beta1-stream.py e work/finish-beta-local.py; script remoto pequeno somente para leitura/exportação. Pacotes já copiados ao PC.
- Identificados temporários próprios descartáveis: /home/hipo/bmo-builds/ready-beta1-20261024 (3,4G) e ready-beta1-r2-20261024 (2,4G), tentativas interrompidas por energia; não são candidatas.
- Próximo passo: limpar somente esses temporários após verificar caminhos reais e ausência de montagens; preservar r3 até roundtrip local confirmado. Depois remover dados grandes redundantes de build/inputs do agente, sem tocar backups pessoais/ambiente operacional.
- Resultado esperado: concluir arquivo no PC e recuperar espaço na Potato. Migração ainda em andamento nesta anotação; sem gate físico fechado.

## 2026-10-24 — Primeira limpeza de temporários próprios concluída

- Fase: economia de armazenamento conforme instrução do usuário; branch feat/bmo-linux-base-v1; R36S_REQUIRED=NO.
- Verificados realpath, diretórios sem symlink e ausência de montagens nos caminhos exatos /home/hipo/bmo-builds/ready-beta1-20261024 e /home/hipo/bmo-builds/ready-beta1-r2-20261024.
- Removidas somente essas duas tentativas interrompidas e descartáveis: 3,4G + 2,4G. df passou de 24G usados/34G livres (41%) para 18G usados/40G livres (31%).
- Raw r3 preservado até validação local; transferência gzip em fluxo continua, mais de 1 GB recebido. Logs r4 e packages.tsv já copiados ao PC.
- Arquivos alterados: documentação; sem remover backups pessoais, PPSSPP auditado ou dados operacionais.
- Resultado esperado/obtido: aproximadamente 5,8 GiB recuperados, sem tocar na candidata atual.
- Próximo passo: confirmar raw SHA256/CRC no PC, gerar/verificar xz local, limpar origem somente após validação e entregar candidata com gate físico pendente.

## 2026-10-24 — Primeira Ready beta entregue ao PC e Potato liberada

- Fase: candidato Ready 1.0.0-beta.1; branch feat/bmo-linux-base-v1; código 17d07a9350bc5db8a4bda4838eb3e34f97f24ca7. R36S_REQUIRED=NO para integridade/offline; YES para primeiro teste físico desta beta.
- Resultado: BMO_READY_BETA_IMAGE_OK local. Arquivo outputs/BMO-R36S-Ready-v1.0.0-beta.1.img.gz, 2016381902 bytes; raw descompactado 12884901888 bytes (12 GiB). O tamanho raw é a capacidade reservada pela receita, não ocupação de programas. Requer cartão extra de pelo menos 16 GB.
- SHA256 gzip: e21a446dccfde7e115a8e0cf79ae251d41aca02f3edfb4c274e4bc405b1794a7.
- SHA256 raw: b7a9ab2567084f42da2c6a7628fbacd68c683ff120f64dca54fc252f15e35f7e.
- Exportação gzip em fluxo concluiu com 12 GiB e hash da origem; no PC leitura completa verificou CRC gzip e raw SHA256 idêntico. Recompressão xz local interrompida para evitar trabalho redundante; parcial xz removida. Arquivo gzip completo movido ao diretório de entregáveis, SHA256 calculado e manifesto emitido.
- Conteúdo offline já aprovado no r4: BMO frontend/candidate idênticos, backend/runtime/emuladores, serviços, PPSSPP libs, fases 40/50/60, contrato beta e sanitização. Sem ROMs/segredos/pareamento. Firstboot/boot direto no BMO desta beta ainda não testados fisicamente.
- outputs inclui checksum, manifesto, packages.tsv e LEIA-ME com descompressão e TF2 fora no primeiro boot.
- Base #9 original compactada preservada no PC em work/base-run9-original.img.xz, 430645444 bytes, SHA256 e32988972ecd085078f430d6988e7bca10b1e551c317773a22235e49c51cc3ee conferido após cópia.
- Após integridade confirmada, removidos somente diretórios próprios r3 (3,7G) e bmo-beta-inputs (2,4G), com realpath/ausência de symlinks/montagens verificados; inventário de inputs continha somente quatro arquivos gerados nesta tarefa. Somados a r1/r2, aproximadamente 12 GiB recuperados. df final: 12169957376 usados e 48708218880 disponíveis (20%; 46G livres), versus 24G usados/34G livres antes da limpeza. Zero unidades failed na última checagem.
- Backups pessoais, runtime PPSSPP original e ambiente operacional preservados. Potato permanece em 192.168.1.50. Não voltar a armazenar imagens/builds pesados nela; preferir GitHub Actions/PC conforme AGENTS.
- Arquivos alterados: documentação/checkpoint; entregáveis locais. Main e cartão de produção não alterados.
- Próximo passo: usuário grava .img descompactado em cartão extra 16 GB+, prepara BOOT pelo ABRIR-BMO.cmd, remove TF2 e testa primeiro boot, IP/SSH e BMO. Registrar evidência física antes de promoção. Futura otimização: reduzir tamanho reservado medindo ocupação; migrar receita beta para CI, sem refazer esta candidata automaticamente.

## 2026-10-24 — Pivot autorizado para imagem Light com instalação automática online

- Fase: medição de armazenamento e arquitetura Light; branch feat/bmo-linux-base-v1; HEAD inicial 7417fe93cd1148bbd78e26657cbc7a1cd044e4cc. R36S_REQUIRED=NO para engenharia, YES para validar novo fluxo físico.
- Usuário prefere imagem pequena em vez de todos os pacotes pré-instalados. Confirmou instalação automática depois de conectar à rede no primeiro boot, com progresso. Expansão do SD antes de instalar dependências.
- Medição local somente leitura da Ready beta: root total12599689216, usado4095193088, livre8504496128 bytes; 666 pacotes e Installed-Size total3006157824 bytes. Interface/scripts<1MiB, runtime PPSSPP~59MiB. Hash/arquivo da beta já entregue preservados.
- Fontes extras326MiB e assetsRetroArch113MiB são dependências rígidas do pacote RetroArch Debian; --no-install-recommends sozinho não as elimina. Headers~76MiB, desenvolvimento~231MiB (grupos sobrepostos); firmware521MiB, dos quais qcom~324MiB, requer seleção por hardware. Não apagar bibliotecas/firmware por tamanho.
- Root arquivos alocados3356061696 bytes e overhead/metadados739131392; FAT256MiB contém~1,29MiB. Tamanho raw12GiB era reserva, não necessidade.
- FTP 192.168.1.1:21 /usb1_1_1 responde; anônimo recusado conforme segurança desejada. Usuário executou helper local com senha não persistida: 8MiB upload/download OK, SHA2562847b9da5f9f7f91b6869ec5f586b8f26a354a01c3c71125f8c459d09bd74d32, 3,14/3,12MiB/s, limpezaOK. Capacidade e arquivos>4GB não medidos.
- Arquivos: AGENTS e Worklog; scripts de auditoria/helper no PC. Copiado runtime PPSSPP27MiB do backup existente para PC, sem build/novos arquivos grandes na Potato.
- Esperado: Light baseada na Base9 validada, payload pequeno pinado, firstboot configura/rede/expansão, instalador baixa apenas dependências, mostra etapas e abre BMO; sem Git privado/token na instalação normal.
- Próximo passo: implementar/validar instalador e receita Light em GitHub Actions ARM64; preservar runtime PPSSPP auditado, medir imagem final e entregar só após integridade/contrato aprovados. A Ready beta1 já gravando continua um teste separado; não promover gate físico automaticamente.

## 2026-10-24 — Implementação inicial da receita Light e gates no GitHub

- Fase: Light com instalação online automática; branch feat/bmo-linux-base-v1; código anterior a23501c5dc54abe0502e2cda456bf80c99247580; R36S_REQUIRED=NO para CI, YES para boot físico.
- Implementados install/light: instalador marcado/ARM64, payload/hash/runtime, rede/expansão/espaço, sete etapas visíveis, APT sem recomendados, staging auditado, áudio/TF2/units e início do kiosk só após checagens. Serviço repete falhas em60s; marcador de sucesso no final. CLI local bmo install evita clone privado.
- Receita usa Base9 pinada, simula purge explícito de ferramentas de desenvolvimento antes de permitir remoção e preserva boot/kernel/rede/firmware. Payload fonte pequeno local; PPSSPP binário privado será injetado na BOOT no PC, não Git.
- Finalizador encolhe só arquivo regular desmontado, e2fsck/resize2fs/zerofree com128MiB margem, preserva prefixo/offsets e corta fim. Fixture verifica UUID e arquivo sobreviventes, rejeição de runtime ausente/payload corrompido.
- Workflow ARM64 somente para perfil Light, reaproveita artifactBase9, sem recompilar kernel nem usar Potato. Não gravar core intermediário sem runtime.
- Medição Base9 no PC: gzip430645444, raw2386558976, root usado1784623104bytes. PPSSPP27.790.924bytes/SHA auditado conferido no PC.
- Arquivos: install/light/**, .github/workflows/build-bmo-light.yml, docs/LIGHT-INSTALL.md. Fontes de frontend/launchers/kernel inalteradas.
- Resultado esperado: CI comprova sintaxe, guardas/fixture, purge permitido, payload e core pequeno; resultado obtido nesta anotação: código preparado para a primeira execução, testes/size final ainda pendentes.
- Próximo passo: executar CI, corrigir somente falhas comprovadas, incluir runtime no PC, verificar imagem final e registrar tamanho antes de entregar.

## 2026-10-25 — Primeira CI Light: gates passaram, espera de detach corrigida

- Branch feat/bmo-linux-base-v1; fonte f4e6175f0d6e15b5477930640d9a0bf79e559c24; run40156553455/job121059075612. R36S_REQUIRED=NO para CI.
- Sintaxe e fixture de segurança/redução passaram; Base9/artifact/hash aprovados. Purge simulada e aplicada removeu somente lista permitida (240MB), sem cascata extra.
- Payload, units e sanitização do core passaram. Falha somente ao iniciar redução: loop detach é lazy e a guarda viu imagem ainda anexada imediatamente após detach.
- Adicionada espera limitada/udevadm antes de reabrir; guarda continua recusando imagem anexada. Nenhuma redução/artefato final foi declarado aprovado na run falha.
- Teste FAT local em cópia da partição: inclusão/leitura do runtime27MiB com SHA original aprovadas. Runtime fora do Git.
- Próximo passo: nova CI Light e revisão profissional do assistente conforme pedido novo (nome público, orientação2,4/5GHz, log sem senhas e diagnóstico de permissão).

## 2026-10-25 — Assistente profissional v0.2, logs e diagnóstico Wi-Fi

- Branch feat/bmo-linux-base-v1; R36S_REQUIRED=NO para assistente/CI, YES para hardware/rede no R36S.
- Usuário relatou falha depois de Preparar cartao; screenshot mostrou apenas mensagem genérica de rollback. Causa original perdida pelo catch antigo; não afirmar diagnóstico confirmado.
- Novo nome público Assistente de Preparacao BMO. Orientação2,4GHz e5GHz por compatibilidade real, não nomeSSID.
- Escrita testa acesso só após confirmação; registra etapa/operação/path/attributes/exceção/HRESULT/stack, redige segredos conhecidos e não serializa config. Botão Abrir log, captura de falhas de inicialização, pasta localPC preferida/fallback. Erro de escrita mantém causa original, recuperação preserva atributos, config substituída por Copy-Item -Force e SHA256 conferido.
- Permissão de leituraH foi concedida pelo sandbox, masWindows continuou negando acesso; nenhuma senha/config foi lida, nenhuma mudança de ACL/admin proposta. Na imagem original de teste, config/boot.ini têm atributoFATArchive, não ReadOnly; caso real continua aguardando log.
- Testes locais27passaram, incluindo readonlyconfig, rollback e redaction; fluxoUI completo e screenshot revisados sem senhas/earlywrite. Pacote outputs/BMO-Assistente-de-Preparacao-v0.2.0.zip entregue para reprodução no cartão.
- Light adiciona bmo-wifi-diagnose: interface/driver/USB-ID/bandas suportadas/habilitadas em BMO-WIFI.txt, semSSID/MAC/senhas. Três testes passaram, incluindo canal desabilitado e nenhum palpite porSSID.
- SegundaCILight40156807193 também parou na guarda de imagem anexada apósdetach; esperar5s não resolveu. Novo finalizador recebe explicitamente apenas o loop pertencente ao builder, conferebackingfile e ausência de mounts, reduz offline e detacha. Fixture passou a cobrir também esse handover. Guarda de imagens anexadas por terceiros permanece.
- Arquivos: scripts/windows/**, install/light/**, workflowLight, AGENTS/continuidade/Worklog.
- Próximo passo: novaCILight+CIWindows, recolher log real se falhar de novo; completar core+runtime noPC e verificar antes de entregar. Não recompilar kernel nem montar imagens naPotato.

## 2026-10-25 — CI Windows verde e isolamento das montagens Light

- Branch feat/bmo-linux-base-v1; fonte3f41782e8b59273b49c466578233186b70968409. CIWindows40157690739 success.
- CILight40157690715 passou testes de segurança/duas reduções de fixture/purge/payload/sanitização, mas e2fsck do core recusou /dev/loop0p2 como em uso, mesmo sem mounts visíveis apósumount. Nenhum e2fsck -f ou relaxamento deguardas foi usado.
- Builder agora entra em namespace privado de montagens para impedir propagação de mounts do chroot ao runner. Hipótese de referências externas será testada, não tratada como causa confirmada. Falhas de e2fsck passam a registrar findmnt/lsblk/fuser para diagnóstico.
- Usuário autorizou substituir assistente e logo diretamente noH; grantread/write foi concedido, porémCLI/Node continuam comEPERM. Explorador consegue listar; operação local viaComputerUse fazbackup somente dos3scripts e logo, sem abrirTXT comsenhas.
- Próximo passo: CILight com namespace, concluirbackup/troca noH, revisar ai-memory por solicitação do usuário.

## 2026-10-25 — Namespace passou; cálculo de margem final corrigido

- Branchfeat/bmo-linux-base-v1; run40158293123. R36S_REQUIRED=NO.
- Namespace privado permitiu e2fsck do core, com342356/513024blocos usados. Fixtures e demaisgates continuaram passando.
- resize2fs-M manteve513024blocos na imagem real; havia170668blocos livres (~667MiB). A receita somava128MiB ao tamanho mínimo estimado e tentava crescer além da partição original.
- Cálculo corrigido: max(mínimo aceito pelo resize2fs, blocos usados+margem), arredondado. Espaço livre já existente conta para a margem; não se promete que toda imagem encolhe abaixo do mínimo aceito. Sem forçar operações de fsck/partição.
- Próximo passo: repetirCI, conferir gzip/manifesto e finalizar runtime noPC.

## 2026-10-25 — Light core aprovada; empacotamento xz para entrega

- Branchfeat/bmo-linux-base-v1; run40158544128/sourceca899649e45cadf649eee8588793bd3fd230e068 success. R36S_REQUIRED=NO paraCI, YES para novo primeiroboot.
- Todos gates passaram: fixtures, Basehash, purgepermitida240MB, payload/units/redePython, sanitização, e2fsck, margem/redução e integridade gzip. Core é intermediário semPPSSPPruntime.
- Artifact12585338848 tem562266673bytes. Conector de download rejeitou por excederlimite536870912; sem downloadparcial tratado como válido.
- Alterado somente empacotamento da próxima execução para xz-T2-3 CRC64/limite512MiB. Deve reduzir arquivo e permitir baixar pelo conector; receita continua noGitHub.
- Próximo passo: baixar corexz, incluirruntimepinado noPC, conferir imagem e registrar tamanhoconcreto. Trocaassistente/logoH está emverificação, backup4originais noPC.

## 2026-10-25 — Assistente e logo substituídos no H com readback verificado

- Fase: manutenção BOOT; branchfeat/bmo-linux-base-v1; R36S_REQUIRED=NO para cópia, YES para validar exibição/boot no aparelho.
- Usuário confirmou Ambos: assistente e imagem de boot. Windows negava CLI/NodeH mesmo apósgrant; operação viaExplorador comComputerUse, sem alterarpermissões/segurança nem abrirTXTcomsenhas.
- Backup local dos4originais em work/H-backup-20261025. NovoBMP da imagem fornecida pelo usuário mantém composição, adaptado ao formatooriginal:640x480,24bits,BI_RGBsemcompressão,921654bytes.
- Copiados ABRIR-BMO.cmd, BMO-Preparar-Cartao.ps1, LEIA-ME.txt e logo.bmp. Depois copiados de voltaHpara work/H-verify-v02; SHA256dos4iguais aos preparados.
- LogoSHA256f1ccc5457edf1573e5e896a815c5c67583ceea960a6f9cdd21c7a6e2a947c797. AssistentePS1b7aca348b3855f976fe023b7f1ead8c25a4fb603a08aef4237ba75f2b4d6e839.
- CLIHnão foi usada para contornar ACL; Explorer normal consegueoperar comautorização explícita. Configuração pessoal/BMO-FIRSTBOOT e partições preservadas.
- Avaliado ai-memory por pedido do usuário: integraçãoMCPviávelnoPC, Windowsnativoexperimental. Relatório e exemploMCPdesabilitado em outputs; nenhumservidor/hook/captura global instalado por essa revisão.
- Lightcore run40159128087/source91a8139690404fb544174b56e980bc12cc43ebf2 success. Artifact12585920303 ZIP402024835bytes/SHA c912b03f51c236ccc1b0ca27151d66bbd549deb1c15d966356fb04566e11f374 conferido noPC; extraçãoCRCpassou. Finalização de runtime/logo em cópia local, fonte79arquivosverificada.
- Primeira cópia local de montagemv01 falhou ao truncarlogoexistente na bibliotecaFAT; não promovida. Atualizado para remover/criar somente os arquivosFAT da cópia e refazer do core íntegro. Nova cópiav02 em compressão após root/runtime/logoSHA aprovados. Aguardar roundtrip final.
- Próximo passo: finalizarchecksum/manifest Light e entregar candidata; recolher novo log de erro se preparação real falhar; testar boot/progresso/expansão/autoinstalação noR36S.


## 2026-10-25 — Assistente v0.2.1: falha na raiz da unidade e Light finalizada no PC

- Fase/branch: preparação do cartão / feat/bmo-linux-base-v1. HEAD inicial ee27134219eccc6274cd1a5471c0fb4b8d10dc02; main preservada.
- Objetivo: diagnosticar a nova falha real após Preparar cartão, corrigir sem alterar permissões e registrar a finalização Light.
- Evidência: log v0.2.0 indica Copiar ScreenFile, destino H:\\rg351mp-kernel.dtb, ArgumentException 80070057, CreateDirectoryArgumentError na linha 190. Reproduzido no Windows PowerShell: New-Item -ItemType Directory -Force na raiz de unidade existente retorna caminho inválido. Não é diagnóstico de falta de permissão do cartão.
- Ação/arquivos: scripts/windows/BMO-Preparar-Cartao.ps1 usa Ensure-BmoDirectory, retorna quando a pasta já existe e cria diretórios novos com API literal. scripts/windows/LEIA-ME.txt atualizado para v0.2.1. Mantidos backup, rollback, hashes e logs com redação de senhas.
- Validação: 30 selftests aprovados, incluindo raiz existente, diretório aninhado com colchetes e idempotência; testes anteriores de cópia, configuração, rollback e segredos continuam passando. Tentativa adicional de teste com unidade subst bloqueada pelo sandbox; não declarar end-to-end em H validado.
- Resultado: ZIP v0.2.1 gerado no PC, SHA256 708bb4ff0cdafb433ddcc8acc41d02e9bed32117666fc7caccbe499581126ed2. Usuário interrompeu Computer Use com Escape; nenhuma nova interação com a tela. v0.2.1 ainda NÃO copiada ao H. Pode rodar extraída no PC e selecionar H.
- Light: CI 40159128087 / fonte 91a8139690404fb544174b56e980bc12cc43ebf2 aprovada. Finalizador local v02 concluiu BMO_LIGHT_FINAL_IMAGE_OK, 79 arquivos de payload verificados, runtime pinado e logo lidos de volta na FAT; root preservada; XZ descomprimida com SHA raw completo conferido. Resultado 424096916 bytes XZ / 2386558976 raw. SHA XZ f890fb74311145f943a9a43bf6527892dff899a871ee003fce388382068e87a2, raw a7f87a6b52d43f0e72f1d4020e097f4d25263add43b0f699ef52b243633d2193. Root usada 1402290176 bytes. Construção/compressão no GitHub/PC, sem novo uso pesado da Potato.
- Limite: candidata Light contém assistente v0.2.0; usar v0.2.1 externo ou reinjetar correção antes de nova entrega integrada. Não tratar candidata como release pronta. Instalador online/expansão/BMO ainda requerem teste físico.
- R36S_REQUIRED=YES para Light; NO para regressão isolada do assistente Windows.
- Próximo passo exato: usuário executar v0.2.1 do PC e preparar H; se falhar coletar novo JSONL. Atualizar assistente na próxima imagem candidata e testar Light no cartão extra com TF2 fora.


## 2026-10-25 — Boot físico da Ready, SSH .65, política Chromium e diagnóstico de áudio

- Fase/branch: validação física / feat/bmo-linux-base-v1; HEAD inicial 763332fdbc1420ff3ffb1faddb5d37e9910d701b. Main preservada.
- Objetivo: confirmar assistente/primeiro boot, acessar SSH e retirar aviso de tradução, investigar ausência de som relatada pelo usuário.
- Evidência: usuário confirmou assistente v0.2.1 e primeiro boot funcionando. SSH 192.168.1.65 responde como r36s@bmo-r36s; chave cadastrada pelo usuário em terminal local, sem senha no chat. Kernel 6.12.32-lts-rk3326, Chromium 156.0.8078.47, root 12G/3,3G usada/8,1G livre; marker firstboot.done presente. Sem marker Light: este teste físico corresponde à Ready anterior, não valida Light. BMO UI HTTP200, kiosk/UI/control-api ativos, zero unidades failed.
- Chromium: flags Translate/TranslateUI já existiam, mas não evitaram aviso. Preparado patch root com backup; usuário executou via SSH interativo/sudo e confirmou aviso removido. Política /etc/chromium/policies/managed/bmo-kiosk.json, TranslateEnabled=false, root:root 0644, SHA256 e33cf2f9e4127d9dbbe44a1eae1ac1fa5706a430317dab5e31a04d1fcd26d6ec. Só kiosk reiniciado; leitura SSH e serviços/HTTP conferidos após aplicação.
- Arquivos: política em install/system/chromium, cópia fase40/plano bmo-install/instalador legado; manifest system-config atualizado. Light builder agora inclui install/system no payload, necessário também à regra udev já usada pela fase40. Imagens já geradas não são alteradas pelo commit.
- Validação de fonte: bash -n dos quatro scripts alterados passou no R36S sem executá-los; JSON booleano e SHA conferidos. Política aplicada/testada no aparelho e confirmada pelo usuário. Compilação/instalação integral das futuras imagens ainda pendente.
- Áudio: PulseAudio ativo, codec rk817_int reconhecido, não mudo. Playback Mux inicialmente HP; teste alterando para SPK e paplay sem som. Segundo teste em 50% (Master 207/255 ~-17,89dB), também sem som. Teste direto pasuspender/aplay plughw:0,0 completou sem erro e sem som segundo usuário. Headphones Jack=on mesmo sem fone; usuário confirma alto-falante funcionava no sistema anterior, não possui fone P2 para teste. DT ativo tem hp-det-gpio=<0xa9 0x16 0>, Speaker->SPKO, kernel 6.12.32. Sem evidência suficiente para inverter GPIO/trocar DTB; nenhuma alteração de DTB/kernel/registradores efetuada. Ausência de /opt/bmo-sounds também observada, problema separado do teste físico ALSA.
- R36S_REQUIRED=YES. Boot/rede e remoção do aviso confirmados; áudio permanece BLOQUEIO DE VALIDAÇÃO, não declarar BMO completo/release estável.
- Próximo passo exato: coletar estado DAPM do codec durante reprodução com diagnóstico root somente leitura; comparar configuração de áudio/DTB com sistema anterior ou upstream correto e só então aplicar correção localizada com rollback. Persistir configuração de áudio apenas após ouvir som.

- Atualização antes da troca de cartão: usuário ofereceu testar o sistema original e comparar por SSH. Baseline Ready salvo integralmente no PC em work/audio-comparison/ready-20261025: kernel/OS, DT decompilado (67809 bytes), ALSA/mixer, Pulse/cards, estado ALSA, logs kernel filtrados, SHA dos dois arquivos de boot e serviços/política. Oito coletas retornaram 0; manifest SHA local gerado. Sem copiar TXT de Wi-Fi/senhas. Próximo passo substitui DAPM imediato: desligar completamente, testar alto-falante no cartão original, obter IP e usuário SSH, coletar o mesmo baseline antes de qualquer alteração. Preservar cartões separados.


## 2026-10-25 — Comparação do cartão original e preservação dos 12 sons BMO

- Fase/branch: áudio / feat/bmo-linux-base-v1; HEAD inicial 059a164d195af7af2a34fbf9616be767cab6567e. Objetivo: comparar original funcional por SSH e, por pedido explícito do usuário, documentar e salvar os sons no projeto.
- SSH: original em 192.168.1.28, r36s; chave cadastrada pelo próprio usuário via terminal local. Coleta seguinte apenas leitura e testes de reprodução; sem mudar mixer/volume/kernel/DTB/serviços do original.
- Evidência: usuário confirmou especificamente que apertar botões muda a carinha e faz som no original. Baseline original salvo no PC. Kernel 6.12.74 contra Ready 6.12.32; DTB e DTBO com SHA idêntico nos cartões, DTS só muda endereços de initrd. Ambos mostram Headphones Jack=on e HP inicial. Isso enfraquece a hipótese anterior de jack/polaridade; não inverter GPIO nem persistir SPK com base nisso. Testes remotos paplay e success API não ouvidos nem no original; resposta API ok não é confirmação de áudio. Kernel diferente ainda não é causa demonstrada.
- Defeito de conteúdo comprovado: Ready não possui /opt/bmo-sounds. Original tem 12 WAV, 2183032 bytes (2,08 MiB), copiados sem conversão e com hashes do aparelho iguais aos locais. Sem ROMs/saves/credenciais.
- Arquivos: assets/sounds/*.wav, SHA256SUMS, manifest.json e README; docs/AUDIO.md e PROJECT-STRUCTURE.md; install/bmo-install.sh e install/install.sh verificam hashes/copiam sons; install/light/build-light-image.sh inclui assets/sounds no payload pequeno local. Arquivos de som não dependem de download externo nem de novos pacotes Linux.
- Validação: 12 WAV PCM 16 bits válidos; SHA256 de cada um conferido na origem/PC; blobs Git conferidos por SHA1 canônico; ZIP local testado e comparado por hash; bash -n dos três scripts passou sem executar instaladores no original. Cópia local entregável BMO-Sounds-Originais-2026-10-25.zip.
- Resultado: sons preservados no projeto e inclusão prevista nos próximos builds. Imagens antigas não foram modificadas por esse commit; não declarar som da Ready/Light corrigido. R36S_REQUIRED=YES.
- Próximo passo exato: usuário desligar e retornar ao cartão Ready, informar IP; aplicar somente os WAV faltantes com backup/validação, voltar ao perfil HP observado no original e testar as carinhas pelos botões. Se persistir, investigar player/API/driver com controles equivalentes antes de trocar kernel ou DTB. Card original permanece referência preservada.


## 2026-10-25 — Sons das carinhas recuperados e confirmados na Ready

- Fase/branch: validação física de áudio / feat/bmo-linux-base-v1; HEAD inicial 7720902740afac95fb53d97c0637a0a8c88e5279. Objetivo: aplicar os WAV preservados ao cartão novo em 192.168.1.65 e testar o mesmo gesto físico usado no original.
- Ação: 12 WAV e SHA256SUMS enviados à pasta de preparação no home de r36s; todos os hashes e bash -n do patch conferidos antes de instalar. Usuário executou atalho local com sudo interativo; nenhuma senha no chat/relatório. Backup criado em /var/backups/bmo/sounds-20261025-015336-3405. Instalação em /opt/bmo-sounds com root:root 0644; perfil do mixer voltou a HP, como no original; volume preservado. Não alterados kernel, DTB, frontend ou serviços.
- Obtido/validação: usuário respondeu “Sim, os sons voltaram” ao testar carinhas pelos botões. Conferência SSH posterior: 12/12 SHA256 iguais, HP selecionado, sound-api/kiosk/UI/control-api ativos e zero failed. Kernel continua 6.12.32-lts-rk3326: não precisou atualização para os efeitos BMO. Não atribuir a ausência anterior a defeito de jack com base no indicador on.
- Persistência: alsa-restore.service ativo tem ExecStop=alsactl store para desligamento normal. Ainda não foi feito reboot após esta recuperação.
- Arquivos: docs/AUDIO.md, CHECKPOINTS.md e PROJECT-CONTINUITY.md atualizados; sons/instaladores já versionados no commit inicial. Cópia local do relatório de comparação atualizada.
- Resultado: checkpoint parcial dos efeitos BMO aprovado fisicamente. Sem validar jogos/streaming ou a imagem Light. R36S_REQUIRED=YES para reboot e áudio nos demais componentes.
- Próximo passo exato: reiniciar normalmente em teste combinado com usuário, confirmar sons persistem e testar áudio em um jogo; manter cartão original como retorno. Nova montagem Light deve incluir os WAV do source atual antes da entrega.
