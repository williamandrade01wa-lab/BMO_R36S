# BMO R36S — Estrutura do Projeto

## 1. Objetivo desta estrutura

Este documento define **onde cada responsabilidade pertence** e qual é a fronteira entre imagem, bootstrap, aplicação, instalação, deploy e documentação.

A organização deve servir a dois públicos diferentes:

1. **usuário final**, que quer apenas baixar e rodar o BMO;
2. **engenharia**, que precisa construir, validar, atualizar e recuperar o sistema.

A complexidade da engenharia não deve vazar para a experiência normal do usuário.

## 2. Produto em camadas

O BMO é dividido em quatro camadas lógicas.

```text
┌──────────────────────────────────────┐
│ 4. BMO App                           │
│ frontend, backend, launchers, jogos  │
├──────────────────────────────────────┤
│ 3. Instalação e manutenção           │
│ bmo install / update / rollback      │
├──────────────────────────────────────┤
│ 2. Bootstrap                         │
│ firstboot, rede, SSH, comando bmo    │
├──────────────────────────────────────┤
│ 1. BMO Linux Base                    │
│ boot, kernel, DTB, drivers, rootfs   │
└──────────────────────────────────────┘
```

Cada camada deve poder ser validada antes da próxima.

## 3. Diretórios e responsabilidades

### `.github/`

Automação do repositório.

Responsabilidades:

- GitHub Actions;
- CI da imagem;
- validações automáticas.

Não deve conter lógica funcional que só existe no YAML quando ela puder morar em script versionado e testável.

### `image/`

Fonte da **BMO Linux Base**.

Responsabilidades:

- builder da imagem;
- pins de upstream;
- userpatches/overlay;
- firstboot embarcado;
- configuração mínima de rede;
- contrato do conteúdo da imagem;
- validação da imagem pronta.

O usuário final não deve precisar entrar aqui.

### `bootstrap/`

Área de bootstrap e referência histórica da instalação limpa anterior.

Enquanto a BMO Linux Base substitui o fluxo antigo, este diretório deve ser tratado como:

- documentação/referência de comportamentos conhecidos;
- ferramentas que ainda não migraram para `image/` ou para o comando `bmo`.

Não criar um segundo fluxo público concorrente ao `BMO-FIRSTBOOT.txt` sem decisão explícita.

### `install/`

Instalação do **BMO App completo** sobre uma base saudável.

Responsabilidades:

- instalação principal;
- manifests;
- dependências externas;
- verificações de versão/hash;
- integração dos componentes do BMO.

Direção de produto:

```text
usuário chama: bmo install
             ↓
bmo usa internamente a lógica de install/
```

O usuário público não deve precisar conhecer scripts internos de fases.

### `frontend/`

Interface visual/kiosk do BMO.

Responsabilidades:

- menu principal;
- navegação;
- listas de jogos;
- favoritos;
- PC STREAM;
- componentes visuais.

### `backend/`

Controle local e APIs do BMO.

Responsabilidades:

- estado do sistema;
- comandos expostos ao frontend;
- integração com hardware/serviços quando aplicável.

### `launchers/`

Entrada e saída de aplicações/jogos/streaming.

Responsabilidades:

- RetroArch;
- PPSSPP;
- Moonlight;
- retorno seguro ao BMO;
- argumentos e ambiente de execução.

### `assets/sounds/`

Efeitos WAV do BMO, preservados do cartão funcional do usuário, com SHA256SUMS e inventário. O instalador copia para /opt/bmo-sounds; o payload Light inclui estes pequenos arquivos. Detalhes e validação em docs/AUDIO.md. Não colocar ROMs, saves ou credenciais neste diretório.

### `configs/`

Configurações versionadas e públicas.

Responsabilidades:

- defaults de emuladores;
- layouts/configurações sem segredo;
- arquivos reprodutíveis.

Nunca armazenar credenciais ou configurações pessoais reais.

### `systemd/`

Unidades e integração de serviços do BMO instalado.

Responsabilidades:

- kiosk;
- backend;
- serviços auxiliares do BMO App.

Serviços estritamente pertencentes à imagem mínima podem viver no overlay da BMO Linux Base quando isso for mais correto arquiteturalmente.

### `scripts/`

Ferramentas de engenharia e validação que não fazem parte da interface pública normal.

Responsabilidades:

- checks;
- verificações;
- tarefas de manutenção do repositório;
- utilitários de desenvolvimento.

Não transformar `scripts/` em um conjunto de comandos que o usuário final precise executar manualmente.

### `deploy/`

Deploy para ambientes de desenvolvimento/candidate.

Responsabilidades:

- envio para R36S de desenvolvimento;
- candidate;
- ferramentas de promoção controlada.

Não faz parte do fluxo público de instalação.

### `docs/`

Fonte de verdade documental.

Arquivos centrais:

```text
docs/PROJECT-CONTINUITY.md    estado atual + próximo passo
docs/WORKLOG.md               histórico operacional
docs/ROADMAP.md               gates até a release
docs/PROJECT-STRUCTURE.md     responsabilidades do repositório
docs/CHECKPOINTS.md           pontos seguros e critérios
docs/BMO-LINUX-BASE-DESIGN.md arquitetura técnica da imagem
docs/BMO-CI-ARCHITECTURE.md   arquitetura do CI
```

## 4. Interface pública do usuário

A versão pública deve expor o mínimo possível.

### Antes do boot

Interface:

```text
BOOT/
├── ScreenFiles/
├── BMO-FIRSTBOOT.txt
├── README-FIRST-BOOT.txt
└── README-SCREENFILES.txt
```

### Depois do boot

Interface principal:

```bash
bmo
```

O usuário não deve precisar conhecer a estrutura interna do Git para operar o produto.

## 5. Fluxo final de instalação

```text
Release GitHub
   ↓
BMO Linux Base .img.xz + SHA256
   ↓
usuário grava microSD
   ↓
abre BOOT
   ↓
COPIA ScreenFiles
   ↓
edita BMO-FIRSTBOOT.txt
   ↓
primeiro boot
   ↓
BMO-IP.txt / BMO-STATUS.txt
   ↓
bmo install
   ↓
BMO App
```

O fluxo deve continuar compreensível mesmo se a pessoa não ler documentação de desenvolvimento.

## 6. Fluxo de engenharia

```text
issue/objetivo
   ↓
recuperar estado do Git
   ↓
validar evidência
   ↓
pequena alteração
   ↓
revisar diff
   ↓
CI / candidate
   ↓
teste físico quando exigido
   ↓
checkpoint
   ↓
próxima camada
```

## 7. Regra para refatoração física de diretórios

Esta estrutura define responsabilidades, mas **não autoriza mover tudo imediatamente**.

Mover um componente só quando:

- a responsabilidade estiver clara;
- referências forem conhecidas;
- CI puder detectar quebra;
- houver rollback simples;
- o checkpoint atual estiver preservado.

Preferir migração incremental.

## 8. Versionamento

Separar:

```text
BMO Linux Base x.y.z
BMO App x.y.z
```

Nova imagem deve ser exigida principalmente quando mudarem:

- boot;
- kernel;
- DTB;
- drivers;
- rootfs/base;
- firstboot/bootstrap fundamental.

Mudanças comuns do BMO App devem preferencialmente chegar por update sem regravar o microSD.

## 9. Dependências externas

Moonlight, PPSSPP e outros componentes de terceiros devem, quando possível:

1. vir da fonte oficial;
2. ter versão pinada;
3. ter SHA256 validado;
4. manter créditos/licenças aplicáveis.

Evitar transformar o repositório público em espelho de binários que podem ser obtidos do upstream.

## 10. Definição de simplicidade

Uma release não é considerada didática somente porque possui documentação longa.

Ela deve minimizar decisões do usuário.

Meta de experiência:

- uma imagem claramente identificada;
- um arquivo principal de configuração;
- uma regra simples para ScreenFiles;
- um comando principal (`bmo`);
- mensagens de erro legíveis;
- arquivos de status acessíveis pela BOOT;
- recuperação documentada;
- nenhuma credencial Git necessária para uso público.

## 11. O que não deve existir na release pública

- múltiplos instaladores concorrentes;
- instruções que exigem escolher branch;
- deploy key obrigatória;
- tokens;
- passos dependentes de conhecimento de Git;
- ROMs/saves;
- configurações pessoais;
- comandos experimentais apresentados como fluxo normal.

## 12. Critério de evolução

Ao propor uma mudança, perguntar:

> Isso deixa mais fácil para uma pessoa nova baixar e rodar o BMO sem aumentar fragilidade ou esconder um risco importante?

Se a resposta for não, a mudança precisa de justificativa técnica clara antes de entrar.
