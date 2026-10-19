# AGENTS.md

## Missão do projeto

Este repositório mantém o código e a configuração versionável do BMO para R36S.

A regra de produto é:

> O BMO deve ser simples o suficiente para que uma pessoa consiga **baixar, gravar, configurar e rodar** o sistema sem precisar entender Linux, Git, CI ou a história interna do projeto.

Toda decisão técnica deve proteger essa experiência final.

## Continuidade obrigatória entre chats/agentes

O projeto **não pode depender da memória de uma conversa**.

Antes de qualquer alteração significativa, ler nesta ordem:

1. `AGENTS.md`;
2. `docs/PROJECT-CONTINUITY.md`;
3. `docs/WORKLOG.md`;
4. `docs/ROADMAP.md`;
5. `docs/BMO-LINUX-BASE-DESIGN.md` quando o assunto envolver a imagem base.

Depois, ler quando aplicável:

6. `docs/PROJECT-STRUCTURE.md`;
7. `docs/CHECKPOINTS.md`;
8. documentação específica da fase.

Em seguida confirmar no GitHub:

- branch atual;
- HEAD atual;
- último GitHub Actions relevante;
- checkpoint atual;
- próximo passo registrado.

Não assumir que uma informação antiga do chat continua válida quando o Git puder confirmá-la.

## Regra de registro

**Toda etapa significativa deve ser escrita em `docs/WORKLOG.md` antes de avançar para a próxima etapa significativa.**

O registro deve conter, no mínimo:

- data;
- fase;
- branch;
- commit inicial quando relevante;
- objetivo;
- ações realizadas;
- arquivos alterados;
- resultado esperado;
- resultado obtido;
- validação;
- `R36S_REQUIRED=YES` ou `R36S_REQUIRED=NO`;
- pendência/risco;
- próximo passo exato.

Quando mudar arquitetura, bloqueio principal, branch de trabalho, imagem candidata ou próximo passo, atualizar também `docs/PROJECT-CONTINUITY.md`.

Atualizar `docs/ROADMAP.md` somente quando houver evidência para marcar/desmarcar tarefa ou quando a estrutura do roadmap mudar por decisão explícita.

Quando um gate for atingido ou substituído, atualizar `docs/CHECKPOINTS.md`.

## North Star de experiência do usuário

A versão pública estável deve convergir para:

```text
baixar imagem
   ↓
grava microSD
   ↓
abre BOOT no Windows
   ↓
COPIA ScreenFiles corretas
   ↓
edita BMO-FIRSTBOOT.txt
   ↓
liga o R36S
   ↓
bmo install
   ↓
BMO completo
```

O usuário público não deve precisar:

- criar chave SSH para baixar o BMO;
- configurar token GitHub;
- clonar o repositório manualmente;
- executar vários scripts internos;
- montar ext4 no Windows;
- conhecer branches ou commits;
- entender detalhes de Armbian para concluir a instalação normal.

Complexidade de engenharia deve permanecer atrás das interfaces `BOOT` e `bmo`.

## Estrutura do projeto

A responsabilidade oficial de cada diretório está em `docs/PROJECT-STRUCTURE.md`.

Não mover código estável somente por estética. Mudanças físicas de diretório devem ter:

1. motivo claro;
2. impacto conhecido;
3. atualização de referências/scripts;
4. validação;
5. rollback;
6. registro no Worklog.

## Checkpoints

`docs/CHECKPOINTS.md` define os gates do produto.

Um build verde não significa automaticamente que o produto está pronto.

Exemplos de gates independentes:

- contrato/CI da imagem;
- boot físico;
- firstboot/rede;
- hardware;
- `bmo install`;
- BMO completo;
- update/rollback;
- release pública.

## Fluxo obrigatório

Sempre seguir:

`recuperar -> validar -> editar -> revisar diff -> candidate -> teste físico -> backup -> produção`

Não alterar produção diretamente quando houver candidate disponível.

## Caminhos do R36S

- Produção frontend: `/opt/bmo-ui/index.html`
- Candidate frontend: `/opt/bmo-ui/index.bmo-next.html`
- Backend principal: `/usr/local/bin/bmo-control-api.py`

## Não regredir

Preservar explicitamente:

- PC STREAM / Moonlight;
- retorno ao BMO após streaming;
- saída do streaming com FN+SELECT;
- Favorites X/Y;
- Games Fast Nav;
- Games Virtual Window;
- Games Lazy Load;
- suporte GBA ZIP;
- PSP standalone;
- volume pelos botões físicos;
- brilho com FN+Volume;
- navegação pelo gamepad;
- tty1 e fluxo de kiosk existentes.

## Gamepad

Evitar alterações em `R36S_GAMEPAD.poll()` sem necessidade comprovada.

Mapeamentos relevantes conhecidos:

- B = 0
- A = 1
- X = 2
- Y = 3
- L1 = 4
- R1 = 5
- L2 = 6
- R2 = 7
- SELECT = 8
- START = 9
- FN = 10
- L3 = 11
- R3 = 12
- D-pad = 13-16
- analógico esquerdo = axes 0/1
- analógico direito = axes 2/3

## Segurança de sistema

Não executar sem necessidade explícita:

- `fstrim`;
- `blkdiscard`;
- `apt autoremove`;
- alterações de partição.

Não desmascarar `fstrim.timer` ou `upower.service` sem decisão explícita.

Evitar reboot quando restart isolado do serviço for suficiente.

## Shell / SSH

Não usar `set -e` solto na sessão SSH interativa.

Para blocos transacionais, preferir subshell:

```bash
(
set -euo pipefail
# ...
)
```

Tarefas longas devem preferencialmente sobreviver à queda de SSH usando `systemd-run`, `tmux` ou `screen`.

## Backups e pontos seguros

Fazer backup antes de mudança importante.

Para checkpoints oficiais:

- registrar o commit em `docs/CHECKPOINTS.md`;
- quando houver artifact/imagem, registrar SHA256;
- para checkpoints físicos importantes, manter cópia local e remota na Le Potato quando aplicável.

## Dados proibidos no Git

Nunca commitar:

- ROMs;
- saves/states;
- backups `.tar.gz`;
- chaves SSH;
- tokens/senhas;
- `Moonlight.conf` real;
- qualquer segredo ou credencial.

## Filosofia de mudança

Preferir alterações pequenas, isoladas, didáticas e reversíveis.

Não reescrever componentes estáveis quando uma correção localizada resolve o problema.

Sempre revisar o diff antes de deploy e sempre distinguir:

- **estado de engenharia**;
- **checkpoint validado**;
- **release para usuário final**.
