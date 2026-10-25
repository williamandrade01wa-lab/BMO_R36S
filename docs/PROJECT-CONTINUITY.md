# BMO R36S — Continuidade do Projeto

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

Prioridade atual: usuário autorizou compilar o primeiro Ready beta com BMO e todas as dependências pré-instaladas, abrindo o kiosk após configurar no primeiro boot.

Receita implementada: `install/build-beta-image.sh`, `install/beta/**`, `docs/BETA-BUILD.md`.
Usa Base #9 (artifact 12571667623), hashes conferidos na Potato e runtime PPSSPP pinado. Builder monta somente cópia .img, reserva root 12 GiB, instala tudo em chroot isolado do /run do host, integra firstboot automático, áudio, kiosk e assistente Windows.

Fixture de integração passou preservando fstab e symlinks existentes. Build completo ainda pendente nesta anotação.

1. Remontar a beta em cópia limpa após desligamento acidental da Potato. Usar código corrigido (firstboot bloqueado durante build, marcador interativo removido antes de apt, newlines do resumo corrigidos). r2 também interrompida por mau contato ao movimentar, confirmado pelo usuário. r3 iniciada: workdir ready-beta1-r3-20261024, unit bmo-ready-beta1-build-r3, invocation c91068a8140a4988bd20492dcbe6d865. Código 94c151db8be8ac6e393a998d2220526db13a65fe; log /home/hipo/bmo-images/beta-1.0.0/build-r3.log. Usuário manterá energia sem movimentação.
2. Acompanhar apt/instalação em 192.168.1.50 (IP fixo confirmado), validar que firstboot não executa no chroot e corrigir somente falhas comprovadas.
3. Verificar manifestos, dependências, units offline, sanitização, compressão e SHA256.
4. Entregar .img.xz candidata e manifesto para gravar em cartão extra de 16 GB ou maior.
5. Testar boot direto no BMO, rede/IP/SSH, gamepad, áudio, brilho, jogos/TF2, streaming e retorno ao BMO.

Não executar bmo install nessa beta: dependências já vêm instaladas. Pareamento Moonlight é pessoal e não vai na imagem.
**TF2 de jogos fora durante todo o primeiro boot.** Desligar antes de inserir. Sem formatar.
Main e cartão em produção preservados. `R36S_REQUIRED=YES` antes de promoção física.

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
