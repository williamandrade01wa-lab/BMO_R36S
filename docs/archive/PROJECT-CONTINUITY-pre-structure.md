# BMO R36S — Continuidade do Projeto

> **LEITURA OBRIGATÓRIA EM TODO NOVO CHAT / AGENTE / SESSÃO DE DESENVOLVIMENTO**
>
> Este arquivo é a fonte de continuidade entre conversas. O projeto não pode depender da memória de um chat específico.

## 1. Regra principal de continuidade

Antes de alterar qualquer arquivo ou disparar qualquer build, um novo chat/agente deve:

1. identificar a branch ativa do trabalho;
2. ler `AGENTS.md`;
3. ler este arquivo inteiro;
4. ler `docs/WORKLOG.md`;
5. ler `docs/ROADMAP.md`;
6. ler `docs/BMO-LINUX-BASE-DESIGN.md` quando o assunto for a imagem base;
7. consultar o estado atual da branch e dos GitHub Actions;
8. somente então continuar do ponto registrado como **PRÓXIMO PASSO**.

Não assumir que uma informação antiga de chat ainda é válida quando o Git puder confirmá-la.

## 2. Regra obrigatória: cada etapa precisa ser escrita

**Toda etapa significativa do projeto deve ser registrada no Git antes de avançar para a próxima.**

O registro operacional fica em:

- `docs/WORKLOG.md`

O estado consolidado e as decisões permanentes ficam neste arquivo.

### O que conta como etapa significativa

Exemplos:

- diagnóstico de uma falha de build;
- alteração de workflow;
- alteração no builder da imagem;
- mudança de arquitetura;
- criação/alteração de firstboot;
- teste de rede;
- teste físico no R36S;
- mudança em boot/DTB/ScreenFiles;
- alteração de gamepad, áudio, brilho, USB ou Wi-Fi;
- mudança em `bmo install`, updater ou rollback;
- criação de uma nova imagem candidata;
- promoção de uma versão.

Não é necessário registrar cada comando isolado. É obrigatório registrar cada **resultado de trabalho** antes de começar o próximo resultado de trabalho.

### Campos mínimos do registro

Cada entrada em `docs/WORKLOG.md` deve informar:

- data;
- fase;
- branch;
- commit inicial, quando relevante;
- objetivo;
- ações realizadas;
- arquivos alterados;
- resultado esperado;
- resultado obtido;
- validação executada;
- `R36S_REQUIRED=YES` ou `R36S_REQUIRED=NO`;
- risco ou pendência conhecida;
- próximo passo exato.

Quando uma decisão arquitetural mudar, atualizar também este arquivo e, se necessário, `docs/BMO-LINUX-BASE-DESIGN.md` e `docs/ROADMAP.md`.

## 3. Repositório e linhas de desenvolvimento

Repositório de desenvolvimento:

```text
williamandrade01wa-lab/BMO_R36S
```

### Branch principal de desenvolvimento da imagem

```text
feat/bmo-linux-base-v1
```

Estado confirmado antes da criação deste handoff:

```text
HEAD: 5bdaa491ca95719d5adb2fd0dd6dc791984e13d3
commit: feat: add BMO Linux Base v0.2 firstboot and network config
```

Este HEAD mudará conforme os commits seguintes. Sempre consultar o HEAD atual no início da sessão.

### Branch anterior do instalador/updater

```text
feat/installer-updater-v1
```

Ela contém o trabalho anterior do instalador/updater e continua sendo referência. Não misturar alterações de imagem nela sem motivo explícito.

### `main`

Não promover ou fazer merge em `main` apenas porque um build passou no CI. A imagem e as funções críticas precisam de validação física antes da promoção estável.

## 4. Objetivo atual

Construir uma **BMO Linux Base** mínima para R36S, pensada desde o início como produto público.

Arquitetura alvo:

```text
BOOT / U-Boot / DTB do R36S
          ↓
Linux mínimo
          ↓
console + rede + SSH + hardware
          ↓
comando bmo já disponível
          ↓
bmo install
          ↓
Git público / HTTPS
          ↓
BMO completo
```

A imagem final não deve depender de XFCE ou de desktop tradicional.

## 5. Princípios que NÃO devem ser revertidos sem decisão explícita

- imagem pública por arquitetura desde o primeiro dia;
- nenhuma chave SSH privada na imagem;
- nenhum token GitHub na imagem;
- nenhuma senha real no Git;
- clone/update público via HTTPS na versão final;
- SSH privado apenas como override manual de desenvolvimento;
- BOOT legível pelo Windows;
- DHCP como padrão;
- `bmo` presente já na imagem base;
- `BMO-FIRSTBOOT.txt` tratado como arquivo de dados, nunca executado como Shell;
- sem XFCE na imagem final;
- preservar suporte específico do R36S;
- preferir `userpatches/`, overlays e hooks em vez de alterar diretamente o framework upstream;
- versão da imagem separada da versão do BMO App;
- mudanças pequenas, reversíveis e testáveis.

## 6. Imagem de referência conhecida

Imagem original usada como referência funcional:

```text
armbian-r36s-trixie-xfce.img.xz
SHA256: 5f9f35375c88fd945e780577cd92d1a30a58675a7eb043fd4547bcc77895a2e6
```

Origem:

```text
oh jhas/armbian-r36s
release/tag: trixie-r1
```

A cópia anteriormente chamada de “Pure” foi confirmada como byte-a-byte da imagem upstream validada.

A imagem de referência usa Debian/Armbian Trixie para R36S, kernel da linha RK3326 e é útil para recuperar detalhes de hardware até a nova base estar validada.

## 7. Hardware que deve permanecer funcionando

Não considerar a BMO Linux Base pronta antes de validar fisicamente:

- boot/U-Boot;
- kernel;
- DTB;
- ScreenFiles / painel;
- vídeo / DRM / KMS necessário;
- D-pad;
- botões A/B/X/Y;
- L1/R1/L2/R2;
- SELECT/START/FN;
- L3/R3;
- analógicos;
- volume;
- brilho;
- áudio;
- USB OTG;
- HUB USB;
- adaptador Wi-Fi USB;
- SSH;
- TF1;
- TF2;
- Moonlight;
- RetroArch;
- PPSSPP;
- retorno ao BMO após jogos/streaming.

### Mapeamento físico conhecido

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

Volume conhecido no userspace anterior:

```text
event2 / keys 114 e 115
```

Regra funcional:

```text
Volume sozinho = volume
FN + Volume = brilho
```

Nunca substituir isso por SELECT+Volume sem decisão explícita.

Evitar alterar `R36S_GAMEPAD.poll()` casualmente.

## 8. Funcionalidades BMO que não podem regredir

Preservar:

- `BMO_PC_STREAM_V1`;
- `BMO_MAIN_MENU_SCROLL_V2`;
- `BMO_GAMES_FAST_NAV_V1`;
- `BMO_GAMES_VIRTUAL_WINDOW_V1`;
- `BMO_GAMES_LAZY_LOAD_V1`;
- `BMO_FAVORITES_XY_V1`;
- SYSTEM / CONTROL V2;
- PC STREAM / Moonlight;
- retorno ao BMO;
- FN+SELECT para sair do streaming;
- Favorites X/Y;
- Fast Nav;
- Virtual Window;
- Lazy Load;
- GBA ZIP;
- PSP;
- volume;
- brilho;
- gamepad;
- tty1 / kiosk.

## 9. ScreenFiles — regra comprovada

A partição BOOT possui variantes `ScreenFiles/Panel X/`.

A regra comprovada fisicamente é:

1. identificar o painel correto;
2. entrar em `ScreenFiles/Panel X/`;
3. **COPIAR** os arquivos de dentro da pasta para a raiz da BOOT;
4. manter os originais dentro de `ScreenFiles/Panel X/`.

**NUNCA orientar a mover/recortar os arquivos.**

Mover causou erro. A documentação deve sempre dizer **Copiar + Colar**, nunca **Recortar + Colar**.

## 10. Novo primeiro boot BMO

A nova imagem não deve depender do antigo `firstrun_overrides.txt` como interface principal.

Interface planejada:

```text
BMO-FIRSTBOOT.txt
```

Exemplo de chaves:

```text
WIFI_SSID=CHANGE_ME_WIFI_SSID
WIFI_PASSWORD=CHANGE_ME_WIFI_PASSWORD
USER_NAME=r36s
USER_PASSWORD=CHANGE_ME_R36S_PASSWORD
ROOT_PASSWORD=CHANGE_ME_ROOT_PASSWORD
HOSTNAME=bmo-r36s
TIMEZONE=America/Sao_Paulo
LOCALE=pt_BR.UTF-8
BMO_AUTO_INSTALL=no
BMO_CHANNEL=stable
```

### Regra de segurança do parser

Nunca executar:

```bash
source BMO-FIRSTBOOT.txt
```

O parser deve:

- aceitar somente chaves conhecidas;
- aceitar linhas `CHAVE=VALOR`;
- tratar valores literalmente;
- ignorar comentários `#`;
- não expandir `$`;
- não expandir backticks;
- não expandir `$()`;
- nunca registrar senhas em log;
- ser idempotente.

Arquivos de retorno na BOOT:

```text
BMO-IP.txt
BMO-STATUS.txt
logs/firstboot.log
logs/network.log
logs/install.log
```

Esses arquivos não podem conter segredos.

## 11. Rede

Estratégia:

- NetworkManager CLI;
- DHCP padrão;
- Wi-Fi USB;
- `autoconnect=yes`;
- reconexão após reboot;
- IP/status na BOOT;
- diagnóstico pelo comando `bmo`.

Descoberta física já confirmada:

- o adaptador Wi-Fi funciona quando ligado diretamente na porta OTG do R36S;
- portanto OTG host + adaptador Wi-Fi funcionam na imagem de referência;
- houve problema de autoconexão/credencial no primeiro boot da imagem antiga, então a nova implementação deve ser validada explicitamente.

Regra udev conhecida do BMO anterior:

```text
HUB USB: 0a05:7211
Wi-Fi Realtek: 0bda:0179
```

O BMO anterior mantinha esses dispositivos com `power/control=on` para evitar autosuspend. Revalidar antes de fixar como regra definitiva da imagem pública.

## 12. Git: público por padrão, privado só no desenvolvimento

Imagem final:

```text
BMO_REPO_TRANSPORT=https
BMO_REPO_URL=https://github.com/OWNER/BMO_R36S.git
BMO_BRANCH=main
BMO_CHANNEL=stable
```

Nenhuma autenticação necessária para leitura pública.

Durante desenvolvimento privado, somente depois do boot, configurar manualmente SSH e alterar localmente a fonte, por exemplo:

```text
BMO_REPO_TRANSPORT=ssh
BMO_REPO_URL=git@github.com:williamandrade01wa-lab/BMO_R36S.git
BMO_BRANCH=feat/...
```

Nunca colocar a chave SSH privada na imagem ou no repositório.

## 13. Comando `bmo`

Antes do BMO completo estar instalado, a base deve fornecer:

```text
bmo status
bmo ip
bmo network
bmo source
bmo install
bmo logs
bmo doctor
bmo version
```

Depois da instalação completa, o mesmo comando deve também oferecer:

```text
bmo verify
bmo check-update
bmo update
bmo promote
bmo rollback
bmo config
```

Preferência arquitetural:

```text
/usr/local/bin/bmo            # dispatcher estável
/usr/local/sbin/bmo-bootstrap # funções da base
/usr/local/sbin/bmo-maintenance # manutenção após instalação completa
```

Não trocar o comando do usuário de forma frágil entre os estágios.

## 14. Instalador/updater anterior — referência

O trabalho anterior em `feat/installer-updater-v1` possui um instalador funcional de referência e deve ser preservado enquanto a nova base evolui.

O `install/install.sh` anterior:

- valida root/aarch64/Debian;
- instala pacotes;
- cria/verifica usuário `r36s`;
- prepara ROM/save dirs;
- instala runtimes conhecidos;
- aplica arquivos BMO;
- preserva boot/kernel/DTB/fstab/Xorg;
- instala gerenciamento/sudoers;
- cria config em `/etc/bmo`;
- prepara repositório local;
- habilita serviços;
- executa verificação;
- termina com:

```text
BMO_INSTALL_COMPLETE_OK
```

Limitação conhecida do updater antigo: ele exige transporte SSH do GitHub. A versão pública futura deve ser transport-aware e aceitar HTTPS público sem chave, mantendo SSH apenas como modo de desenvolvimento.

## 15. Dependências de terceiros

Estratégia pública:

- evitar republicar binários de terceiros no Git quando puderem ser obtidos de upstream oficial;
- pin de versão;
- SHA256;
- download/instalação via `bmo install`;
- manter créditos e licenças aplicáveis.

Moonlight conhecido:

```text
moonlight-qt 6.2.0 arm64
SHA256 .deb: 269e8eee33ae2adeb3fcb4ddc2a5ff768e27b3c4ab893f3b95d5284437e1f014
```

PPSSPP conhecido:

```text
PPSSPP 1.20.4
aarch64 AppImage SHA256: 18c1d515fd99b0b10ca5fa8cbab192f6d4c9d8a10381e16f5de8fb8f9d39bbe1
source SHA256: 4de21db3105d9d81a465a8a7e78c68ee3c0e0bf6597d1c1d530f7555f3ad8b31
commit upstream: fa50bb1976065c4f8b1b47af227d367fe9771555
```

Os runtimes congelados presentes no repositório privado são referência de desenvolvimento, não a estratégia pública final.

## 16. Publicação futura

Não simplesmente transformar o repositório privado histórico em público.

Estratégia preferida:

```text
repositório privado de engenharia
        ↓
estável validado
        ↓
public-release-audit
        ↓
export limpo do estado aprovado
        ↓
novo repositório público
```

Motivos:

- não carregar histórico privado desnecessário;
- evitar IPs antigos/metadados experimentais;
- remover blobs de terceiros que não devam ser redistribuídos;
- revisar licença/proveniência antes da publicação.

## 17. Build da BMO Linux Base

Branch atual:

```text
feat/bmo-linux-base-v1
```

Workflow:

```text
.github/workflows/build-bmo-linux-base.yml
```

Builder:

```text
image/armbian/build-bmo-linux-base.sh
```

Versão de trabalho atual:

```text
BMO Linux Base v0.2
Debian Trixie
minimal / sem desktop
```

O builder:

1. lê `image/armbian/UPSTREAM.env`;
2. baixa a árvore R36S upstream fixada;
3. valida SHA do upstream;
4. baixa Armbian Build fixado;
5. valida SHA do Armbian Build;
6. injeta config/userpatches do R36S;
7. fixa o kernel RK3326 conhecido;
8. aplica `image/armbian/userpatches/` do BMO;
9. executa `compile.sh`;
10. localiza a `.img` gerada;
11. copia para `image/armbian/output/`;
12. gera SHA256.

## 18. ESTADO EXATO DA VALIDAÇÃO CI — ponto de retomada

Última validação analisada neste chat:

```text
GitHub Actions Run #3
Run ID: 39166839314
Job ID: 117791440181
```

Resultado por etapa:

```text
Checkout BMO                  SUCCESS
Free runner disk space        SUCCESS
Install host prerequisites    SUCCESS
Build minimal image           SUCCESS
Validate image contents       FAILURE
Compress image and checksum   SKIPPED
Upload image artifact         SKIPPED
```

Conclusão importante:

> **A compilação da imagem terminou com sucesso. O bloqueio atual está na validação pós-build, não no compile principal.**

O workflow de validação atualmente monta a imagem por loop device, identifica BOOT FAT e ROOT ext4, e exige:

```text
BOOT/BMO-FIRSTBOOT.txt
BOOT/README-FIRST-BOOT.txt
ROOT/usr/local/bin/bmo                   executável
ROOT/usr/local/sbin/bmo-firstboot        executável
ROOT/etc/bmo/source.conf
ROOT/etc/NetworkManager/conf.d/20-bmo.conf
ROOT/etc/netplan/90-bmo-networkmanager.yaml
ROOT/etc/udev/rules.d/99-bmo-usb-power.rules
```

### Bloqueio atual

Ainda é necessário extrair/confirmar no log da Run #3 **qual `test` ou qual etapa de montagem/partição falhou**.

Não corrigir no escuro.

Não disparar um novo build só para “ver se passa” antes de identificar a falha exata da Run #3.

## 19. PRÓXIMO PASSO EXATO

A nova sessão deve continuar daqui:

### Etapa A — fechar diagnóstico da Run #3

1. abrir logs do job `117791440181`;
2. localizar a linha exata que encerrou `Validate image contents`;
3. identificar se a falha foi:
   - detecção da partição BOOT;
   - detecção da ROOT;
   - mount;
   - arquivo ausente;
   - permissão/executável ausente;
   - caminho divergente;
4. registrar o diagnóstico em `docs/WORKLOG.md`;
5. só então editar o mínimo necessário.

```text
R36S_REQUIRED=NO
```

### Etapa B — correção mínima da validação/build

1. corrigir a causa real;
2. revisar o diff;
3. confirmar que não foi criada dependência privada/segredo;
4. commit na `feat/bmo-linux-base-v1`;
5. registrar a etapa no `docs/WORKLOG.md`.

```text
R36S_REQUIRED=NO
```

### Etapa C — nova execução de CI

1. disparar/aguardar nova run;
2. confirmar `Build minimal image = success`;
3. confirmar `Validate image contents = success`;
4. confirmar compressão;
5. confirmar SHA256;
6. confirmar upload do artifact;
7. registrar Run ID, Job ID e resultado no `docs/WORKLOG.md`.

```text
R36S_REQUIRED=NO
```

### Etapa D — inspeção do artifact

Antes de gravar SD:

1. baixar artifact gerado;
2. validar SHA256;
3. confirmar nome/versão da imagem;
4. documentar exatamente o que será testado;
5. registrar no `docs/WORKLOG.md`.

```text
R36S_REQUIRED=NO
```

### Etapa E — teste físico da imagem base

Somente depois do CI/artifact válido:

1. gravar microSD de teste;
2. preservar o cartão conhecido como referência/rollback;
3. preparar ScreenFiles corretamente por **cópia**;
4. editar `BMO-FIRSTBOOT.txt` sem expor senha no Git/chat;
5. bootar;
6. observar tela/boot;
7. validar usuário;
8. validar NetworkManager;
9. validar Wi-Fi;
10. validar autoconnect após reboot;
11. validar SSH;
12. validar `BMO-IP.txt`;
13. validar `BMO-STATUS.txt`;
14. validar `bmo status`;
15. validar `bmo network`;
16. validar `bmo doctor`;
17. registrar cada bloco de resultado no `docs/WORKLOG.md`.

```text
R36S_REQUIRED=YES
```

Não instalar ainda o BMO completo se o bootstrap/hardware base não estiver estável.

### Etapa F — validação física de hardware base

Depois do boot básico:

- tela/painel;
- gamepad;
- áudio;
- volume;
- brilho;
- OTG;
- HUB;
- Wi-Fi pelo HUB;
- TF2;
- módulos/drivers;
- DRM/KMS;
- reboot limpo.

Registrar cada grupo validado no `docs/WORKLOG.md`.

```text
R36S_REQUIRED=YES
```

### Etapa G — `bmo install`

Somente depois da base mínima estar saudável:

1. validar fonte Git;
2. em desenvolvimento privado, configurar SSH manualmente;
3. testar `bmo source`;
4. testar `bmo install`;
5. validar idempotência/reexecução;
6. validar ausência de segredo dentro da imagem;
7. registrar resultados.

```text
R36S_REQUIRED=YES
```

### Etapa H — BMO completo

Validar:

- kiosk;
- gamepad;
- volume/brilho;
- SYSTEM / CONTROL;
- GBA;
- SNES;
- PSP;
- Moonlight;
- retorno ao BMO;
- updater;
- rollback.

Somente marcar itens do roadmap como concluídos depois do teste correspondente.

```text
R36S_REQUIRED=YES
```

## 20. Fases macro do projeto

### Fase 1 — referência/hardware

- capturar e documentar hardware conhecido;
- manter cartão/imagem de referência;
- registrar boot/DTB/ScreenFiles;
- registrar drivers/módulos relevantes.

### Fase 2 — build mínimo

- Armbian/R36S upstream fixado;
- Debian Trixie;
- `BUILD_MINIMAL=yes`;
- `BUILD_DESKTOP=no`;
- userpatches BMO;
- CI reproduzível;
- artifact + SHA256.

### Fase 3 — firstboot

- parser seguro;
- usuário/senha;
- timezone/locale/hostname;
- NetworkManager;
- Wi-Fi autoconnect;
- status/logs sanitizados;
- idempotência.

### Fase 4 — bootstrap Git/BMO

- `bmo source`;
- `bmo install`;
- HTTPS público por padrão;
- SSH privado manual apenas no desenvolvimento.

### Fase 5 — BMO completo

- frontend/backend;
- launchers;
- emuladores;
- Moonlight;
- hardware/hotkeys;
- updater/rollback.

### Fase 6 — publicação

- build reproduzível;
- licença/proveniência;
- créditos;
- auditoria de segredos;
- remoção de blobs temporários de terceiros do export público;
- SHA256;
- teste em cartão limpo;
- instalação pública por HTTPS;
- documentação final.

## 21. Segurança operacional

Nunca commitar:

- chave SSH privada;
- token;
- senha GitHub;
- senha Wi-Fi real;
- `Moonlight.conf` real;
- ROMs;
- saves/states;
- backups privados;
- arquivos contendo credenciais.

Não executar operações destrutivas no aparelho sem necessidade explícita.

Evitar:

- `fstrim`;
- `blkdiscard`;
- `apt autoremove`;
- reparticionamento;
- reboot desnecessário.

Backup antes de mudanças importantes.

## 22. Convenção `R36S_REQUIRED`

Toda etapa futura deve declarar claramente:

```text
R36S_REQUIRED=NO
```

quando puder ser feita apenas no GitHub/CI/PC/Le Potato.

E:

```text
R36S_REQUIRED=YES
```

quando exigir aparelho físico.

Isso evita pedir acesso físico sem necessidade.

## 23. Forma de trabalhar com OpenBot Author

OpenBot Author ainda está consolidando Git/GitHub. Ao orientar ações manuais:

1. explicar **o que estamos fazendo**;
2. explicar **o que isso significa no Git**;
3. fornecer o **comando/passo pronto**;
4. dizer **o que deve aparecer se deu certo**.

Explicar termos quando usados:

- branch;
- commit;
- push;
- pull;
- fetch;
- merge;
- Pull Request / PR;
- `main`;
- `origin`;
- `HEAD`;
- `checkout` / `switch`;
- remote;
- SHA;
- fast-forward.

Preferir a opção mais segura e reversível.

## 24. Prompt mínimo para abrir um novo chat

Um novo chat pode começar com:

```text
Estamos continuando o projeto BMO R36S.

A fonte de continuidade está no próprio GitHub, branch feat/bmo-linux-base-v1.
Leia primeiro, nesta ordem:
1. AGENTS.md
2. docs/PROJECT-CONTINUITY.md
3. docs/WORKLOG.md
4. docs/ROADMAP.md
5. docs/BMO-LINUX-BASE-DESIGN.md

Depois confira o HEAD atual e o último GitHub Actions da BMO Linux Base.
Não repita etapas já concluídas e não corrija no escuro.

Regra obrigatória: cada etapa significativa concluída precisa ser registrada em docs/WORKLOG.md antes de avançarmos para a próxima; decisões permanentes também devem atualizar docs/PROJECT-CONTINUITY.md/ROADMAP quando aplicável.

Continue exatamente do PRÓXIMO PASSO registrado em docs/PROJECT-CONTINUITY.md.
Sempre informe R36S_REQUIRED=YES ou NO.
```

## 25. Quando este arquivo deve ser atualizado

Atualizar `docs/PROJECT-CONTINUITY.md` quando ocorrer qualquer um destes eventos:

- mudança de arquitetura;
- mudança de branch principal de trabalho;
- nova imagem base considerada candidata;
- novo bloqueio principal;
- bloqueio atual resolvido;
- mudança no próximo passo;
- decisão sobre publicação/licença;
- alteração relevante de hardware/ScreenFiles/kernel/DTB;
- mudança no modelo Git público/privado;
- promoção para `main`.

A meta é que um chat completamente novo consiga continuar o projeto apenas lendo o Git.

## 26. ESTADO ATUAL — CI em camadas (supersede o ponto operacional das seções 18–19)

As seções 18 e 19 permanecem como histórico do bloqueio anterior. Para retomada operacional, esta seção é a fonte mais recente.

### Mudança arquitetural aplicada

Commit funcional da arquitetura de CI:

```text
f7e1b9d66ed876616ceccd57e822fe3772320651
ci: add layered validation for BMO Linux Base
```

A pipeline da BMO Linux Base passa a seguir:

```text
preflight barato
      ↓
build pesado somente se preflight OK
      ↓
validação agregada da imagem
      ↓
artifact de diagnóstico sempre
      ↓
compressão + SHA256 + artifact final somente se validação OK
```

Arquivos centrais:

```text
image/armbian/ci/image-contract.tsv
image/armbian/ci/preflight.sh
image/armbian/ci/validate-image.sh
docs/BMO-CI-ARCHITECTURE.md
.github/workflows/build-bmo-linux-base.yml
```

### Regras novas de CI

1. falhas baratas de estrutura/sintaxe/pins/segurança devem ocorrer antes do build pesado;
2. `build` depende explicitamente de `preflight`;
3. requisitos críticos da imagem ficam centralizados em `image-contract.tsv`;
4. a validação pós-build acumula todas as falhas contratuais possíveis em uma única execução;
5. `validation-report.txt` é publicado como artifact diagnóstico mesmo quando a validação falha;
6. compressão, SHA256 e artifact final só acontecem após validação bem-sucedida;
7. runs da mesma branch usam `cancel-in-progress: true` para não compilar estado obsoleto;
8. não voltar a embutir listas paralelas de arquivos obrigatórios no YAML;
9. mudanças futuras de destino precisam atualizar gerador e contrato na mesma revisão;
10. esta CI não substitui validação física do R36S.

### Escopo preservado

O hardening de CI não alterou nesta etapa:

- builder funcional;
- kernel;
- DTB;
- ScreenFiles;
- overlay da imagem;
- firstboot;
- rede;
- Wi-Fi;
- conteúdo funcional da imagem.

A causa funcional da falha da Run #4 não deve ser corrigida por hipótese. O objetivo da nova arquitetura é produzir evidência suficiente para corrigir todas as falhas comprovadas de uma vez.

### PRÓXIMO PASSO EXATO

1. identificar a GitHub Actions disparada pelo commit `f7e1b9d66ed876616ceccd57e822fe3772320651`;
2. registrar Run ID e Job IDs;
3. confirmar primeiro o resultado do job `Preflight BMO Linux Base`;
4. se o preflight falhar, corrigir somente a falha barata comprovada e não iniciar análise de imagem;
5. se o preflight passar, observar o build pesado;
6. se a validação pós-build falhar, ler `validation-report.txt` completo e reunir todas as falhas contratuais da mesma imagem;
7. registrar o diagnóstico no `docs/WORKLOG.md` antes de alterar conteúdo funcional da imagem;
8. aplicar uma correção funcional agrupada apenas para defeitos comprovados;
9. `docs/ROADMAP.md` continua sem alteração até validator, compressão, SHA256 e artifact final passarem.

```text
R36S_REQUIRED=NO
```
