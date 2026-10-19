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

## 10. Estado do bloqueio atual

Falha anterior comprovada da Run #5:

```text
Not enough RAM available (6426Mib) for BTF build.
```

Correção aplicada:

```text
KERNEL_BTF=no
```

O preflight passou a exigir explicitamente essa configuração.

Run válida seguinte:

```text
Run #7
Run ID: 39184063121
HEAD: 8d967e34f07e013752e45b2478250b1e9b71e933
```

Na última consulta via API durante a sessão, o endpoint ainda reportava a run como `in_progress`, enquanto a interface observada pelo usuário já indicava falha no validator. Portanto:

- BTF não deve ser reaberto sem nova evidência;
- a próxima causa funcional deve vir do `validation-report.txt`/log da Run #7;
- não corrigir conteúdo da imagem por hipótese.

## 11. Checkpoint atual

O projeto está entre:

```text
Gate 0 — estrutura/continuidade
        ↓
Gate 1 — imagem base reproduzível
```

A reestruturação documental desta sessão cria o checkpoint de organização do projeto.

O **Gate 1 ainda não está concluído** até existir, na mesma run válida:

- preflight success;
- build success;
- image contract success;
- imagem comprimida;
- SHA256;
- artifact final.

Critérios completos: `docs/CHECKPOINTS.md`.

## 12. PRÓXIMO PASSO EXATO

Após registrar esta reestruturação e o checkpoint no Git:

1. recuperar o resultado final da Run #7;
2. obter o `validation-report.txt` completo ou log equivalente;
3. listar todas as falhas contratuais da mesma imagem;
4. registrar o diagnóstico em `docs/WORKLOG.md`;
5. corrigir somente falhas comprovadas;
6. revisar diff;
7. executar nova CI;
8. somente declarar Gate 1 concluído quando validator, compressão, SHA256 e artifact final passarem.

```text
R36S_REQUIRED=NO
```

Depois do Gate 1:

```text
Gate 2 — boot/firstboot     R36S_REQUIRED=YES
Gate 3 — rede/hardware      R36S_REQUIRED=YES
Gate 4 — bmo install        R36S_REQUIRED=YES
Gate 5 — BMO completo       R36S_REQUIRED=YES
Gate 6 — update/rollback    R36S_REQUIRED=YES
Gate 7 — publicação         R36S_REQUIRED=YES + auditoria
```

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
