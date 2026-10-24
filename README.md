# BMO R36S

BMO é um sistema dedicado para transformar o R36S em uma experiência simples de jogos, streaming e gerenciamento, sem exigir que o usuário conheça Linux, Git ou a história técnica do projeto.

> **Objetivo principal do projeto:** uma pessoa deve conseguir **baixar, gravar, configurar e rodar o BMO** seguindo poucos passos claros e reproduzíveis.

## Estado atual

O projeto ainda está em desenvolvimento. A **BMO Linux Base** própria está sendo construída e validada antes de uma distribuição pública estável.

Por isso, este README descreve primeiro a experiência final que estamos construindo. O estado técnico exato, bloqueios e próximo passo ficam versionados em [`docs/PROJECT-CONTINUITY.md`](docs/PROJECT-CONTINUITY.md).

## Experiência final desejada

O usuário comum não deverá precisar clonar repositório, configurar chave SSH ou executar vários scripts manualmente.

```text
1. Baixar BMO Linux Base
        ↓
2. Gravar no microSD
        ↓
3. Abrir BOOT no Windows
   - copiar ScreenFiles corretas
   - editar BMO-FIRSTBOOT.txt
        ↓
4. Primeiro boot somente com o cartao do sistema em TF1
   - retirar o TF2 de jogos antes de ligar
   - rede, usuário e SSH configurados
   - BMO-IP.txt / BMO-STATUS.txt disponíveis
        ↓
5. Executar bmo install
        ↓
6. BMO completo
```

Quando o fluxo estiver suficientemente estável, uma variante futura poderá permitir instalação automática, mas o caminho manual `bmo install` será mantido como opção recuperável e didática.

## O que a BMO Linux Base deve entregar

A imagem base deve ser pequena e previsível. Ela contém somente o necessário para:

- iniciar o R36S corretamente;
- preservar U-Boot, kernel, DTB e suporte de tela;
- reconhecer hardware essencial;
- configurar rede por `BMO-FIRSTBOOT.txt`;
- permitir SSH;
- disponibilizar o comando `bmo`;
- instalar o restante do BMO pela internet.

Ela **não deve depender de XFCE** nem de um desktop tradicional.

## Primeiro boot: retirar o TF2 de jogos

**Mantenha o cartão TF2 de jogos fora do R36S durante todo o primeiro boot.** Inicie somente com o cartão do sistema na entrada TF1 e aguarde a configuração inicial terminar.

Depois, desligue completamente o aparelho, insira o TF2 de jogos e ligue novamente. Não formate nem altere o TF2 para realizar esse procedimento.

Esta orientação foi registrada após o primeiro teste físico da Base v0.2 da Run #8. O motivo técnico ainda precisa de diagnóstico; não presumir que os jogos ou o cartão estão com defeito.

## Regra da ScreenFile

Na partição `BOOT`, o usuário escolhe a variante correta dentro de `ScreenFiles/Panel X/` e **COPIA** os arquivos da pasta para a raiz da BOOT.

**Copiar, nunca mover.** Os originais devem continuar dentro de `ScreenFiles/Panel X/`.

## Um comando, dois estágios

O usuário aprende somente um comando:

```bash
bmo
```

Na imagem base, ele oferece funções de bootstrap e diagnóstico, como:

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

Depois da instalação completa, o mesmo comando também oferece manutenção:

```text
bmo verify
bmo check-update
bmo update
bmo rollback
bmo config
```

## Organização do projeto

A responsabilidade de cada área está definida em [`docs/PROJECT-STRUCTURE.md`](docs/PROJECT-STRUCTURE.md).

Resumo:

```text
image/       geração da BMO Linux Base e contrato da imagem
bootstrap/   referência histórica e ferramentas de bootstrap
install/     instalação do BMO completo e dependências
frontend/    interface/kiosk
backend/     API e controle local
launchers/   jogos, emuladores e streaming
configs/     configurações versionadas
systemd/     serviços do BMO
scripts/     validação e utilitários de engenharia
deploy/      ferramentas de deploy para desenvolvimento
docs/        arquitetura, continuidade, roadmap e checkpoints
.github/     automações e CI
```

Não mover componentes funcionais apenas por organização visual. Refatorações de diretório devem ocorrer somente quando houver ganho claro, validação e caminho de rollback.

## Checkpoints do projeto

O projeto usa checkpoints versionados para impedir que uma etapa seja considerada pronta apenas porque "compilou".

Consulte [`docs/CHECKPOINTS.md`](docs/CHECKPOINTS.md) para saber:

- qual gate estamos validando;
- quais critérios precisam passar;
- se exige R36S físico;
- qual commit é o ponto seguro de retorno.

## Desenvolvimento

A branch atual da BMO Linux Base é:

```text
feat/bmo-linux-base-v1
```

`main` não recebe promoção apenas porque o CI passou. Uma versão só pode ser tratada como estável depois das validações físicas e funcionais previstas nos checkpoints.

Fluxo de engenharia:

```text
recuperar → validar → editar → revisar diff → candidate → teste físico → backup → produção
```

Para continuar o projeto em outro chat/agente, leia primeiro [`AGENTS.md`](AGENTS.md).

## Segurança

Nunca commitar:

- ROMs;
- saves/states;
- backups privados;
- chaves SSH;
- tokens;
- senhas reais;
- credenciais de Wi-Fi;
- `Moonlight.conf` real.

A distribuição pública deverá usar Git/HTTPS sem segredo embutido na imagem.

## Documentação principal

- [`docs/PROJECT-STRUCTURE.md`](docs/PROJECT-STRUCTURE.md) — organização e responsabilidades;
- [`docs/CHECKPOINTS.md`](docs/CHECKPOINTS.md) — gates e pontos seguros de retorno;
- [`docs/PROJECT-CONTINUITY.md`](docs/PROJECT-CONTINUITY.md) — estado atual e próximo passo;
- [`docs/WORKLOG.md`](docs/WORKLOG.md) — histórico operacional;
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — caminho até a publicação;
- [`docs/BMO-LINUX-BASE-DESIGN.md`](docs/BMO-LINUX-BASE-DESIGN.md) — arquitetura técnica da imagem;
- [`docs/BMO-CI-ARCHITECTURE.md`](docs/BMO-CI-ARCHITECTURE.md) — CI em camadas;
- [`CREDITS.md`](CREDITS.md) e [`THIRD_PARTY.md`](THIRD_PARTY.md) — origem e dependências externas.
