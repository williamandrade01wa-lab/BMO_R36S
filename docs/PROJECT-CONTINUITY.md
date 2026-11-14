# BMO R36S — Continuidade do Projeto

> Retomada 2026-11-14: no boot seguinte ao teste bem-sucedido de 5 GHz, o usuário viu tela preta com um X central e reiniciou o aparelho; depois relatou tela preta sem X. Neste intervalo, SSH em `192.168.1.28` primeiro encerrou antes do banner e depois expirou; API/UI não responderam. Nenhuma alteração remota foi feita nesta retomada. O cartão voltou ao PC como F: sem filesystem/volume utilizável; o disco USB 2 ainda é reconhecido com 57.671.680.000 bytes, mas o primeiro setor físico lido com UAC contém somente `FF` (MBR ausente). Uma segunda leitura de setores foi cancelada pelo usuário. **A causa ainda é desconhecida:** não distinguir defeito do cartão de erro do leitor sem nova amostra. O usuário decidiu gravar outro cartão. A raw privada disponível no PC é `outputs/BMO-R36S-Ready-v1.0.0-beta.2-WiFi5.img`, SHA256 `11cda8721d2e731da176e3b8616e55dfbb648a3b502994b3ce3958592a3fcbc4` verificado nesta retomada. Após gravação, confirmar preparação da BOOT, boot físico, IP, SSH, frequência e estado do candidate. Preservar o cartão atual para diagnóstico. `R36S_REQUIRED=YES`.

> Pausa a pedido do usuário em 2026-11-14. **5 GHz e SSH funcionam agora:** R36S em `192.168.1.28`, frequência **5240 MHz**, sinal 81%, taxa de associação NetworkManager **433,3 Mb/s** (não é throughput), GitHub HTTPS retornou 200 em 0,67 s. Perfil WPA salvo com autoconnect=yes; SSID ativo apareceu somente em 5 GHz no scan. Backend atualizado com backup e rollback, hash conferido, health 200; frontend **candidate** atualizado com status visível e HTTP 200, produção frontend permanece na versão anterior validada. Pendências para retomada: confirmar persistência após reboot, resolver prioridade de autoconexão (perfil 5 GHz e perfil antigo ambos prioridade 0), testar visualmente o status do novo teclado e então promover frontend candidate. Não realizar mais mudanças no aparelho até o usuário retomar. Não registrar SSID nem senha.

> Bloqueio Wi-Fi 2026-11-14: teclado completo funciona no candidate, mas CONECTAR retornou HTTP 500 por `802-11-wireless-security.key-mgmt: property is missing`; o toast de falha ficava oculto. O scan exibia banda nula pelo sufixo `MHz`. Implementado perfil WPA explícito com banda, parser de frequência e status dentro do teclado; testes locais passaram. Próximo passo: implantar frontend candidate e backend com backup reversível, conectar 5 GHz fisicamente e medir frequência antes de promover frontend.

> Teclado Wi-Fi 2026-11-14: usuário permaneceu em 2,4 GHz e pediu entrada completa diretamente no BMO. Implementadas páginas de maiúsculas, minúsculas e símbolos (inclui espaço) em `frontend/index.html` e candidate; teste local cobre os 95 caracteres ASCII imprimíveis e navegação entre seis ações. Próximo passo: implantar candidate, validar no R36S, associar rede 5 GHz e confirmar frequência por SSH. Não promover produção antes do teste físico.

> Falha Wi-Fi 2026-11-14: o usuário confirmou que o teclado virtual do BMO travou ao tentar sair com B. Numa segunda ocorrência, SSH mostrou serviços/HTTP ativos e CDP revelou `BMO_WIFI_KEYBOARD.visible=true` com `APPS.current=null`; nesse estado, o handler antigo de B não fechava o teclado. Fechamento da sobreposição por CDP recuperou o controle sem reset, confirmado pelo usuário. `frontend/index.html` e `index.bmo-next.html` agora priorizam B/SELECT e navegação do teclado independentemente de `APPS.current`. **B e SELECT passaram no teste físico no candidate**, e o mesmo SHA256 foi promovido a produção com backup `20261114-030812`; kiosk/UI/API ativos e HTTP 200. Wi-Fi continua em **2462 MHz (2,4 GHz)**; 5 GHz pendente.

> Aviso de idioma/tradução 2026-11-14: usuário relatou popup do Chromium na beta. SSH confirmou que o launcher já usa flags de desativação, mas a política `/etc/chromium/policies/managed/bmo-kiosk.json` faltava. A política versionada `TranslateEnabled=false` foi instalada via SSH com sudo interativo e o kiosk reiniciado; SSH confirmou conteúdo/hash e serviços ativos, e o usuário confirmou que **o aviso sumiu**. O contrato de `install/build-beta-image.sh` agora exige a política na imagem; montagem local Wi-Fi5 também a copia. Este item está resolvido na beta atual e coberto no próximo build.

> Contorno de rede 2026-11-14: o usuário relatou que o teclado Wi-Fi do BMO não lhe permite digitar maiúsculas e caracteres necessários à senha da rede 5 GHz. Melhoria adicionada ao Gate 5 de `docs/ROADMAP.md`; a causa exata no build instalado ainda precisa ser reproduzida. Foi preparado no PC `outputs/R36S-ACESSO-WIFI5.ps1` com lançador `.cmd`: menu para abrir SSH, conectar uma rede 5 GHz com nome digitado no PowerShell e senha digitada no terminal remoto via `sudo nmcli --ask`, ou consultar a frequência. O script usa a chave SSH autorizada, não grava senha e mantém o perfil anterior. A troca de rede pode derrubar SSH e mudar IP. Próximo passo: usuário executar opção 2, informar o IP após conexão; conferir frequência 5xxx MHz e persistência após reboot. `R36S_REQUIRED=YES`.

> Validação SSH/Wi-Fi 2026-11-14: com autorização explícita do usuário, chave pública de diagnóstico adicionada ao `authorized_keys` de `r36s` no R36S; chave privada local somente no PC, fora do Git, ACL limitada a usuário/admin/SYSTEM. Login SSH por chave **confirmado** (`r36s`, kernel `6.12.32-lts-rk3326`). USB `0bda:c811` presente; módulos `rtw88_8821cu`, `rtw88_8821c`, `rtw88_usb`, `rtw88_core` carregados; interface Wi-Fi conectada com IP `192.168.1.28/24`, driver `rtw_8821cu`; serviço SSH ativo. A conexão atual usa **2462 MHz (2,4 GHz)**. O scan mostra três APs em 5 GHz, mas o SSID da conexão atual apareceu somente em 2,4 GHz. Usuário foi acionado para selecionar uma rede 5 GHz na interface BMO, digitar senha no aparelho e informar o novo IP. Próximo passo: reconectar por SSH, confirmar frequência 5xxx MHz, IP e estabilidade. Não publicar SSID, MAC ou credenciais.

> Estado mais recente 2026-11-14: o usuário corrigiu o procedimento de teste e informou que a **imagem beta inicia com BMO** e o Wi-Fi **aparentemente funciona**. O R36S mostra IP `192.168.1.28`; do PC, a porta TCP 22 respondeu. Tentativa SSH sem senha alcançou o servidor, mas recebeu `Permission denied (publickey,password)`, então o login ainda não foi comprovado. A revisão automática rejeitou instalar uma chave persistente de diagnóstico sem autorização explícita; nenhuma chave foi instalada no R36S e a chave local criada para isso foi removida. Próximo passo: obter autorização explícita para esse método de acesso ou usar login interativo com senha digitada localmente; após login, verificar interface, frequência 5 GHz, IP, driver e SSH. As notas anteriores de tela preta são histórico de testes feitos antes de o usuário corrigir o procedimento. O Segundo Cérebro Obsidian foi iniciado em `G:\Meu Drive\Segundo Cérebro\Cérebro`; regra em `docs/GOLDEN-RULES.md`.

> Teste adicional 2026-11-14: o usuário ligou o R36S com o **cartão original**, TF1 e TF2 vazio, e relatou **tela preta também**. Portanto, a falha visível ocorre com ambos os cartões. Isto não demonstra por si só defeito de solda, tela ou SD. O usuário foi orientado a desligar até apagar LED e devolver o cartão original ao PC. Próximo passo: identificar letra da BOOT original, ler somente arquivos de boot/diagnóstico e conferir se há hook residual, configuração de painel ou alterações inesperadas. Preservar cartão original, sem ler credenciais. Depois comparar sua BOOT com a beta e decidir teste controlado de hardware/alimentação. Wi-Fi 5 GHz/SSH pendentes.

> Diagnóstico 2026-11-14, após tela preta na beta: o cartão extra voltou como F:. Não havia `BMO-STATUS.txt` nem `BMO-WIFI5-STATUS.txt` na BOOT. Cópia **somente leitura** da partição ext4 do disco USB 2 (57.671.680.000 bytes) não tinha logs/estado novos de firstboot ou Wi-Fi. Seus 12.599.689.216 bytes são idênticos, byte por byte, à região ext4 da raw beta. Os primeiros 16 MiB físicos do cartão também são idênticos à raw. Base run9 e beta têm mesmo formato/recursos ext4, rótulo `armbian`, mesmo bootloader inicial, `boot.ini`, `PanCho.ini`, `logo.env`, kernel, initrd e DTB principal. Logo, não há evidência de corrupção da gravação nem de rootfs montada para escrita no teste; a etapa exata da falha ainda é desconhecida. Próximo teste físico solicitado: ejetar F: beta, colocar o **cartão original** em TF1 sem TF2 e informar se o BMO aparece em até três minutos. Não alterar o original. Se iniciar, comparar suas configurações de BOOT/painel e investigar a beta; se também ficar preto, investigar hardware/alimentação/tela. Wi-Fi 5 GHz e SSH ainda **não validados** no aparelho. `R36S_REQUIRED=YES`.

> Teste físico 2026-11-14: após o assistente v0.2.1 concluir, o usuário ejetou o cartão beta e iniciou o R36S em TF1 sem TF2. Após cinco minutos, a tela permaneceu **preta com LED ativo**. Não atribuir ainda a causa a painel, kernel ou Wi-Fi. O usuário foi instruído a desligar pelo Power até apagar LED, devolver o cartão ao PC e avisar quando F: aparecer. Próximo passo obrigatório: ler `BMO-WIFI5-STATUS.txt` na BOOT e metadados/arquivos de diagnóstico, sem ler `BMO-FIRSTBOOT.txt` nem senhas. Se não houver relatório, investigar estágio anterior ao systemd e painel/ScreenFiles, preservando o cartão. O gzip revisado com assistente v0.2.1 está em hash final no PC.

> Primeiro boot autorizado em 2026-11-14: o usuário fechou/reabriu o assistente v0.2.1 e informou **conclusão sem erro**. No cartão extra, `BMO-FIRSTBOOT.txt` tem atualização recente (conteúdo/credenciais não lidos), `mipi-panel.dtbo` da raiz confere por SHA256 com `ScreenFiles/Panel 4/mipi-panel.dtbo`, e o script em F: confere com v0.2.1. O usuário foi orientado a fechar a GUI, ejetar com segurança, colocar o cartão em TF1 com TF2 fora e aguardar até cinco minutos. A raw em `outputs` também recebeu os três arquivos do assistente v0.2.1; FAT32/ext4 e verificação estática passaram. O gzip revisado está em recompressão; o gzip anterior foi preservado em `work/ready-wifi5/`. Próximo passo: receber estado da tela do R36S e depois ler `BMO-WIFI5-STATUS.txt` pela BOOT, sem expor senhas.

> Correção do assistente em 2026-11-14: ao preparar a BOOT recém-gravada, o assistente embutido na Ready falhou e informou rollback. A cópia da imagem é antiga e usa `New-Item -ItemType Directory -Force` sobre a raiz `F:\`, erro já corrigido na v0.2.1 do Git. A v0.2.1 passou em 30 autotestes. No cartão extra F: foram preservados backups dos três arquivos originais em `work/F-wizard-before-v021/` e substituídos `BMO-Preparar-Cartao.ps1`, `ABRIR-BMO.cmd` e `LEIA-ME.txt` pela v0.2.1; hashes de origem e destino conferem. O usuário precisa **fechar a janela antiga e relançar `F:\ABRIR-BMO.cmd`** para usar o código novo. Aguardar resultado. Não ler `BMO-FIRSTBOOT.txt` ou backups com senhas. A imagem raw/gzip em `outputs` ainda contém o assistente antigo e deve ser reempacotada com a v0.2.1 após validar a nova execução, antes de considerar a beta distribuível.

> Validação pós-Rufus 2026-11-14: o microSD extra continua como disco USB 2 de 57.671.680.000 bytes. Após a gravação, há BOOT FAT32 de 268.435.456 bytes no offset 16.777.216 e partição Linux de 12.599.689.216 bytes no offset 285.212.672, de acordo com a imagem. F: agora tem rótulo BOOT e contém `BMO-WIFI5-BETA.txt`, `ABRIR-BMO.cmd`, `BMO-FIRSTBOOT.txt` e ScreenFiles. SHA256 de `BMO-WIFI5-BETA.txt`, `boot.ini`, `ABRIR-BMO.cmd` e `logo.bmp` coincide exatamente com a imagem raw fonte. `chkdsk F:` em modo somente leitura relatou nenhum problema, embora tenha avisado que o volume estava em uso. O usuário foi instruído a executar `F:\ABRIR-BMO.cmd` para escolher painel, configurar Wi-Fi 5 GHz e habilitar SSH com senha nova; aguardar confirmação do assistente antes de retirar o cartão. Não ler ou publicar `BMO-FIRSTBOOT.txt` preenchido. `R36S_REQUIRED=YES` depois dessa preparação.

> Handoff 2026-11-14: o usuário inseriu um **microSD extra** no mesmo adaptador; ele apareceu como F:, disco USB 2 de 57.671.680.000 bytes, uma partição exFAT vazia. O cartão anterior tinha cerca de 62,5 GB e BOOT FAT32, portanto este é distinto. A raw validada da candidata foi movida para `outputs/BMO-R36S-Ready-v1.0.0-beta.2-WiFi5.img` (12.884.901.888 bytes, SHA256 `896c2d2a8c0ff4a5f2cd6ca0597b7a2c909cc4fb017e8c48f8b063d508f95ec4`) para seleção no Rufus. O usuário abriu o Rufus elevado; o controle de interface não pode operar essa janela por diferença de privilégio. O usuário está gravando a raw no cartão extra de 57,7 GB via Rufus e avisará quando aparecer `Pronto`. Próximo passo: após esse aviso, verificar disco/partições BOOT e hashes de arquivos, só então orientar a troca para o R36S. Não ler senhas de `BMO-FIRSTBOOT.txt` nem tocar no cartão antigo.

> Atualização 2026-11-14, branch `fix/rtl8811cu-ready-wifi5-beta`: candidata `BMO-R36S-Ready-v1.0.0-beta.2-WiFi5.img.gz` pronta no PC, 1.891.182.973 bytes, SHA256 `e0888fb7f28d3cd56f29612aa4506a7ad2bb40688cb7e692db351377fa819429`; raw SHA256 `896c2d2a8c0ff4a5f2cd6ca0597b7a2c909cc4fb017e8c48f8b063d508f95ec4`, confirmado por descompressão em fluxo. Build GCC 13.4 dos três módulos RTL8811CU concluído para `6.12.32-lts-rk3326`; CRCs do `rtw88_core` novo e instalado: 68/68 iguais, importações verificadas contra módulos existentes sem divergência. Os módulos, `depmod` e relatório de boot foram integrados **somente à cópia** da Ready v1.0.0-beta.1. `modprobe -n`, verificação estática, `fsck.vfat -n` e `e2fsck -fn` passaram. Nenhum teste físico da candidata ocorreu. Próximo passo exato: gravar em outro microSD de 16 GB ou maior, configurar a BOOT, testar boot, Wi-Fi 5 GHz e SSH no R36S e ler `BMO-WIFI5-STATUS.txt`. F: e Ready original preservados. `R36S_REQUIRED=YES` para a próxima etapa.

> Atualização 2026-11-13, branch `fix/rtl8811cu-ready-wifi5-beta`: o usuário solicitou uma imagem beta Ready com BMO instalado, Wi-Fi interno RTL8811CU em 5 GHz e SSH. O USB `0bda:c811` enumera no R36S, mas o kernel `6.12.32-lts-rk3326` não contém `rtw88_usb`, `rtw88_8821c` e `rtw88_8821cu`. A imagem Ready v1.0.0-beta.1 foi verificada por SHA256 e descompactada em cópia de trabalho. Build do kernel pinado `d5da60f7ee9fcafed61f1e93590eb85ca0ecd7c0` com config da Ready e GCC 13 está em andamento. O cartão F: não foi modificado após os testes; `boot.ini` original foi restaurado. O FAT32 passou no `chkdsk` somente leitura e em leituras repetidas, mas ext4 e intermitência não estão validados. Próximo passo: verificar módulos e símbolos do build, montar a candidata v1.0.0-beta.2-WiFi5, calcular hashes e testar em cartão extra. `R36S_REQUIRED=NO` até a imagem estar pronta; `R36S_REQUIRED=YES` para boot, 5 GHz e SSH. Detalhes em `docs/RTL8811CU-READY-WIFI5-PLAN.md` e registro recente do Worklog.

> Prioridade atual: montar PureLight v0.1.0-beta para teste privado do usuário, antes do Releases. CI/core no GitHub e finalização no PC, sem Potato. Incluir sons, assistente v0.2.1, Chromium sem tradução e nova logo. Ainda não declarar nova imagem pronta: acompanhar workflow, finalizar runtime PPSSPP, validar conteúdo/hash e entregar candidata; R36S_REQUIRED=YES.

> Atualização 2026-10-25: App v0.1.0-beta.1 integrado à main via PR #5 (merge c8e218953ce3d710d47042db16448fc664ad3997), com CI aprovada e update visual PC testado no aparelho. Alterações visuais devem partir de main; esta branch continua responsável pela imagem Light. Nova arte de assets/boot está aplicada no aparelho e incluída nos finalizadores das próximas imagens. Imagens já geradas mantêm seus hashes anteriores.

> **LEITURA OBRIGATÓRIA EM TODO NOVO CHAT / AGENTE / SESSÃO DE DESENVOLVIMENTO**
>
> Este arquivo é o snapshot operacional atual. Histórico detalhado fica em `docs/WORKLOG.md`.

## 1. Missão do projeto

Construir um sistema limpo, didático e recuperável para que uma pessoa consiga:

```text
baixar → gravar → configurar BOOT → ligar → bmo install → usar
```

O usuário final não deve precisar entender Git, branches, CI, Armbian internamente ou múltiplos scripts de instalação.

## 2. Ordem obrigatória de leitura

Antes de alterar qualquer arquivo ou disparar qualquer build:

1. `AGENTS.md`;
2. `docs/PROJECT-CONTINUITY.md`;
3. `docs/WORKLOG.md`;
4. `docs/ROADMAP.md`;
5. `docs/BMO-LINUX-BASE-DESIGN.md` quando o assunto envolver a imagem base;
6. `docs/PROJECT-STRUCTURE.md`;
7. `docs/CHECKPOINTS.md`.

Depois confirmar no GitHub:

- branch atual;
- HEAD atual;
- último GitHub Actions relevante;
- checkpoint atual;
- próximo passo exato.

## 3. Repositório e branch de trabalho

Repositório:

```text
williamandrade01wa-lab/BMO_R36S
```

Branch principal da BMO Linux Base:

```text
feat/bmo-linux-base-v1
```

`main` permanece protegida operacionalmente: não promover apenas porque CI passou.

HEAD técnico observado antes da reestruturação documental desta sessão:

```text
8d967e34f07e013752e45b2478250b1e9b71e933
ci: enforce BTF-disabled minimal profile
```

Sempre consultar novamente o HEAD; este valor é apenas referência histórica do ponto de partida da reestruturação.

## 4. Arquitetura de produto

```text
BMO Linux Base
  boot + kernel + DTB + drivers + rootfs
        ↓
Bootstrap
  firstboot + rede + SSH + comando bmo
        ↓
Instalação/manutenção
  bmo install + update + rollback
        ↓
BMO App
  frontend + backend + launchers + configs
```

Responsabilidades detalhadas: `docs/PROJECT-STRUCTURE.md`.

## 5. Experiência pública alvo

A versão pública estável deve exigir somente:

1. baixar a imagem correta;
2. conferir SHA256;
3. gravar microSD;
4. abrir a BOOT no Windows;
5. **copiar**, nunca mover, a ScreenFile correta para a raiz da BOOT;
6. editar `BMO-FIRSTBOOT.txt`;
7. ligar o R36S;
8. consultar `BMO-IP.txt` / `BMO-STATUS.txt` se necessário;
9. executar `bmo install`;
10. usar o BMO.

Não exigir no fluxo público:

- deploy key;
- token;
- clone Git manual;
- escolha de branch;
- montagem ext4 no Windows;
- execução manual de scripts internos.

## 6. Regras permanentes de segurança/arquitetura

- nenhuma chave SSH privada na imagem;
- nenhum token GitHub na imagem;
- nenhuma senha real no Git;
- Git público por HTTPS na versão final;
- SSH privado somente como override manual de desenvolvimento;
- BOOT legível pelo Windows;
- DHCP como padrão;
- `bmo` já presente na imagem base;
- `BMO-FIRSTBOOT.txt` é dado, nunca deve ser executado com `source`;
- sem XFCE na imagem final;
- preferir `userpatches/`, overlays e hooks ao invés de editar upstream;
- versão da BMO Linux Base separada da versão do BMO App;
- mudanças pequenas, reversíveis e testáveis;
- não mover código estável por estética.

## 7. Hardware e comportamento que não podem regredir

Antes de uma release estável, validar fisicamente:

- boot/U-Boot;
- kernel;
- DTB;
- ScreenFiles/painel;
- DRM/KMS necessário;
- D-pad;
- A/B/X/Y;
- L1/R1/L2/R2;
- SELECT/START/FN;
- L3/R3;
- analógicos;
- áudio;
- volume;
- brilho;
- USB OTG;
- HUB;
- Wi-Fi USB;
- SSH;
- TF1/TF2;
- Moonlight;
- RetroArch;
- PPSSPP;
- retorno ao BMO.

Mapeamento conhecido:

```text
B = 0
A = 1
X = 2
Y = 3
L1 = 4
R1 = 5
L2 = 6
R2 = 7
SELECT = 8
START = 9
FN = 10
L3 = 11
R3 = 12
D-pad = 13-16
analógico esquerdo = axes 0/1
analógico direito = axes 2/3
```

Regra funcional:

```text
Volume sozinho = volume
FN + Volume = brilho
```

Não substituir por SELECT+Volume sem decisão explícita.

## 8. Funcionalidades BMO que devem ser preservadas

- `BMO_PC_STREAM_V1`;
- `BMO_MAIN_MENU_SCROLL_V2`;
- `BMO_GAMES_FAST_NAV_V1`;
- `BMO_GAMES_VIRTUAL_WINDOW_V1`;
- `BMO_GAMES_LAZY_LOAD_V1`;
- `BMO_FAVORITES_XY_V1`;
- SYSTEM / CONTROL V2;
- PC STREAM / Moonlight;
- FN+SELECT para sair do streaming;
- retorno ao BMO;
- GBA ZIP;
- PSP;
- volume;
- brilho;
- gamepad;
- tty1/kiosk.

## 9. BMO Linux Base atual

Versão de trabalho:

```text
BMO Linux Base v0.2
Debian Trixie
minimal / sem desktop
```

Workflow:

```text
.github/workflows/build-bmo-linux-base.yml
```

Builder:

```text
image/armbian/build-bmo-linux-base.sh
```

CI atual em camadas:

```text
preflight barato
      ↓
build pesado
      ↓
validação agregada da imagem
      ↓
validation-report.txt
      ↓
compressão + SHA256 + artifact final se válido
```

Arquivos centrais:

```text
image/armbian/ci/image-contract.tsv
image/armbian/ci/preflight.sh
image/armbian/ci/validate-image.sh
docs/BMO-CI-ARCHITECTURE.md
```

## 10. Estado atual — Run #8 aprovada

Atualizado em 2026-10-24. O bloqueio dos templates na FAT foi resolvido e validado na CI integral.

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

O aviso de `sudo` no script U-Boot é `sudo eject $1` na linha 22, após os três dd e sync; gravações aparecem concluídas. Foi inspecionado o pacote público rc2-pancho. Boot físico ainda não comprovado.

## 11. Checkpoint atual

`CP-IMAGE-002` está SAFE para CI e contrato de conteúdo. Build, validator, compressão, SHA256 e artifact passaram na mesma run. Isso não declara BMO Ready nem boot/hardware validados.

No Gate 1 resta auditoria de dependências externas: upstream clona ScreenFiles/PanCho de branch móvel e baixa U-Boot por tag sem exigir checksum. Não chamar a imagem plenamente reproduzível até fixar isso.

## 12. PRÓXIMO PASSO EXATO

**Estado atual (2026-10-25): sons das carinhas RECUPERADOS e confirmados no cartão Ready em 192.168.1.65.** Os 12 WAV preservados em assets/sounds (source 7720902740afac95fb53d97c0637a0a8c88e5279) foram instalados em /opt/bmo-sounds com hashes 12/12 conferidos, root:root 0644 e backup. Playback Mux restaurado para HP. Usuário confirmou sons ao apertar botões; kernel 6.12.32 mantido. Kiosk/UI/control-api/sound-api ativos e zero failed. Ver docs/AUDIO.md e CP-AUDIO-001.

Próximo teste físico: reinício normal para confirmar persistência e áudio em jogo. alsa-restore salva mixer no shutdown normal; ainda não validado após reboot. Não trocar kernel/DTB nem forçar SPK para estes efeitos. Áudio de jogos/streaming e candidata Light ainda não testados. Imagens antigas exigem patch ou nova montagem para incluir WAV; instaladores/fonte atuais já os incluem.

Original em 192.168.1.28 permanece referência preservada. Baselines no PC: work/audio-comparison/ready-20261025 e original-20261025. DTB/DTBO idênticos e Jack=on/HP em ambos; diferença de kernel não impediu recuperar efeitos da Ready. Main preservada; CP-BETA-001 continua VALIDATING por demais testes. R36S_REQUIRED=YES.

Histórico Light/pendências anteriores:


Atualizado em 2026-10-25. Prioridade: corrigir preparação do cartão e validar BMO Light com instalação automática online e progresso, mantendo builds grandes no GitHub/PC.

1. Falha real do assistente identificada pelo JSONL: PowerShell New-Item -Force rejeita raiz existente H:\\ ao copiar ScreenFile. v0.2.1 evita criar diretórios já existentes, usa criação literal e passou 30 selftests. ZIP no PC; ainda não instalado no H porque usuário interrompeu controle da tela com Escape. Executar assistente extraído no PC, selecionar H, preparar cartão; coletar novo log se falhar. Não alterar ACL nem executar como administrador como solução padrão.
2. H já recebeu e teve hash de leitura conferido para logo.bmp novo e assistente v0.2.0. Logo 640x480 RGB BMP 24-bit sem compressão, formato original preservado. Configuração com senhas não foi lida nem versionada.
3. Light CI 40159128087 aprovada, fonte 91a8139690404fb544174b56e980bc12cc43ebf2. Finalização local v02 concluída e hashes verificados: BMO-R36S-Light-v0.1.0.img.xz 424096916 bytes, raw 2386558976. Ver CP-LIGHT-001. A candidata ainda embute assistente v0.2.0: usar ZIP v0.2.1 externo ou reinjetar correção antes da próxima entrega integrada. Finalizador/ext4_reader estão em work/light-source/install/light no PC e ainda precisam ser versionados após revisão.
4. Light leva fonte BMO, instalador e pequeno runtime PPSSPP pinado; baixa os pacotes grandes após conectar, expande SD antes e mostra progresso. Requer validação física: cartão extra 8 GB+, TF2 fora durante primeiro boot; verificar rede/IP, expansão, instalação e abertura BMO. Não promover main por CI/hash apenas.
5. Wi-Fi: preferência 2,4 GHz; 5 GHz depende do adaptador. BMO-WIFI.txt informa driver/bandas sem SSID/senhas. Três testes de bandas aprovados.
6. Ready beta anterior permanece separada (raw 12 GiB), não valida Light. Potato 192.168.1.50 preservada de builds/arquivos grandes. FTP privado do roteador: teste 8 MiB OK, 3,14/3,12 MiB/s, capacidade/limite >4GB desconhecidos. Nenhuma senha FTP foi solicitada no chat.
7. ai-memory avaliado: integração MCP local no PC é viável, Windows nativo experimental; relatório e exemplo desativado estão em outputs. Sem instalação, hooks, captura global ou alteração de configuração do Codex. Preferir resumos curados complementando documentação Git.

R36S_REQUIRED=YES antes de promover a imagem. Próximo teste imediato: assistente v0.2.1 no PC contra o cartão H.

## 13. ScreenFiles

Regra comprovada:

1. identificar o painel correto;
2. entrar em `ScreenFiles/Panel X/`;
3. **COPIAR** os arquivos para a raiz da BOOT;
4. manter os originais dentro da pasta.

Nunca documentar como mover/recortar.

## 14. Dados proibidos no Git

Nunca commitar:

- ROMs;
- saves/states;
- backups privados;
- chave SSH privada;
- token;
- senha GitHub;
- senha Wi-Fi real;
- `Moonlight.conf` real;
- qualquer credencial.

## 15. Regra de checkpoint

Cada checkpoint oficial deve registrar em `docs/CHECKPOINTS.md`:

- ID;
- objetivo;
- commit;
- evidência;
- status;
- `R36S_REQUIRED`;
- rollback/retorno seguro quando aplicável.

Checkpoint não é sinônimo de release.

## 16. Regra de Worklog

Toda etapa significativa precisa ser registrada em `docs/WORKLOG.md` antes de avançar para a próxima etapa significativa.

A entrada deve informar:

- data;
- fase;
- branch;
- commit inicial;
- objetivo;
- ações;
- arquivos;
- esperado;
- obtido;
- validação;
- `R36S_REQUIRED`;
- riscos;
- próximo passo.

## 17. Prompt mínimo para novo chat

```text
Estamos continuando o projeto BMO R36S.

Leia nesta ordem:
1. AGENTS.md
2. docs/PROJECT-CONTINUITY.md
3. docs/WORKLOG.md
4. docs/ROADMAP.md
5. docs/BMO-LINUX-BASE-DESIGN.md
6. docs/PROJECT-STRUCTURE.md
7. docs/CHECKPOINTS.md

Depois confira branch, HEAD, último GitHub Actions e checkpoint atual.
Não repita etapas concluídas e não corrija no escuro.
Continue exatamente do PRÓXIMO PASSO de PROJECT-CONTINUITY.md.
Sempre informe R36S_REQUIRED=YES ou NO.
```
Nota operacional de 2026-10-24: Potato recuperada após desligamento; saúde sem evidência de dano, zero serviços failed/erros EXT4. Build anterior interrompido e não promovido. Correções com 22 testes/89 checks aprovadas. IP USB fixo agora 192.168.1.50.
