# BMO R36S

> [!IMPORTANT]
> **Aviso Legal e Direitos Autorais (Disclaimer de Propriedade Intelectual):**
> Este projeto é de código aberto, sem fins lucrativos, desenvolvido por entusiastas para fins estritamente educacionais e de estudo de sistemas embarcados. O visual e a interface são **inspirados na estética do personagem BMO**, porém todo o código, arte gráfica gerada e scripts deste repositório são implementações originais e independentes. Nenhuma marca registrada, ativo proprietário ou código de detentores de direitos autorais foi copiado ou infringido. O projeto não possui vínculo, patrocínio ou afiliação oficial com os criadores ou detentores da marca *Hora de Aventura / Adventure Time*.

> [!CAUTION]
> **Política Rigorosa sobre Jogos e Arquivos Protegidos (Zero ROMs / Zero ISOs):**
> Este repositório e suas imagens de instalação **NÃO CONTÊM NENHUMA ROM, ISO, BIOS, JOGO OU ARQUIVO PROTEGIDO POR DIREITOS AUTORAIS**.
> O usuário é integralmente e exclusivamente responsável por qualquer arquivo de mídia ou jogo que decidir transferir para seu próprio aparelho, devendo respeitar a legislação de direitos autorais vigente no seu país.


> [!WARNING]
> ### ⚠️ AVISO IMPORTANTE: PROJETO EXPERIMENTAL & CUIDADOS COM O R36S
> - **Desenvolvimento Amador & Entusiasta:** Este projeto é desenvolvido por um entusiasta explorando os limites de hardware do console R36S. Não é um produto comercial nem uma firmware oficial.
> - **Compatibilidade:** Desenvolvido e testado exclusivamente para o **R36S ORIGINAL** (placa-mãe e tela autênticas). Não há garantia de funcionamento em clones ou variantes com telas não suportadas. *(Link de referência do modelo original adquirido no AliExpress será incluído em breve).*
> - **NÃO USE O CARTÃO SD ORIGINAL:** O cartão microSD genérico que acompanha o console de fábrica é de baixíssima qualidade e corrompe com facilidade. **Faça backup completo** de todos os arquivos, ROMs e bios que vieram nele para o seu computador. Adquira um cartão confiável de marca (SanDisk, Samsung, Kingston original) e instale o BMO nele!


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

## Modo preguiça: assistente no Windows

Extraia o pacote do assistente e abra **ABRIR-BMO.cmd** com dois cliques. O código fica em [scripts/windows](scripts/windows).

Ele pergunta em formato de conversa:
1. onde está a BOOT do cartão;
2. qual pasta ScreenFiles usar;
3. Wi-Fi com senha, Wi-Fi aberto, cabo/Ethernet ou sem rede;
4. nome/senha do Wi-Fi quando necessário;
5. senha do R36S e confirmação;
6. se deseja acesso remoto por SSH.

Depois mostra um resumo sem senhas. Ao clicar em **Preparar cartão**, copia as ScreenFiles do painel para a raiz da BOOT e escreve o TXT. Preserva os originais, faz backup dos destinos e tenta restaurá-los se uma gravação falhar.

O assistente é offline, usa PowerShell/Windows Forms do Windows e não exige Python ou administrador. A escolha do painel é do usuário; não existe detecção automática da tela. Use antes do primeiro boot: no cartão já configurado, salvar o TXT não reaplica as opções automaticamente.

O TXT gerado usa as chaves antigas compatíveis com a imagem #8 e com a nova UX. Nome/senha com espaços internos e caracteres especiais são escritos literalmente, sem aspas. DHCP é o padrão. O TF2 deve ficar fora durante todo o primeiro boot.

Teste automatizado sem cartão real:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/windows/BMO-Preparar-Cartao.ps1 -SelfTest
```

## Configuração simples do primeiro boot

Abra `BMO-FIRSTBOOT.txt` na BOOT e preencha somente:

```text
REDE_WIFI=
SENHA_WIFI=
SENHA_USUARIO=r36s
ACESSO_REMOTO=nao
```

O nome do Wi-Fi preenchido ativa sua configuração automaticamente. Para cabo/Ethernet, deixe Wi-Fi vazio. Para SSH, use `ACESSO_REMOTO=sim` e escolha uma senha diferente de `r36s`. Não use aspas nem envie senhas no chat.

Ao concluir, a tela informa configuração, conexão local, IP e estado do SSH. O resumo também fica em `BMO-RESUMO.txt` na BOOT e reaparece ao entrar no terminal. Falta de IP é mostrada como tal; não se afirma conexão à internet sem teste.

Os nomes antigos e opções avançadas continuam aceitos; não defina uma opção pelos dois nomes.

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


> [!TIP]
> **Compatibilidade Wi-Fi (2.4 GHz vs 5 GHz):**
> O sistema possui suporte tanto para redes **2.4 GHz** quanto **5 GHz** (com dongles compatíveis como RTL8811CU).
> - **Recomendação:** Verifique qual frequência seu adaptador USB reconhece.
> - **Na dúvida na primeira instalação:** Conecte em uma rede **2.4 GHz** para garantir a detecção inicial. Você pode alternar facilmente para 5 GHz posteriormente dentro do menu de configurações do BMO.

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


## Créditos da Imagem Linux Base (Pure)

A base do sistema operacional Linux utilizada no R36S é de código aberto e crédito integral dos desenvolvedores da comunidade:
- **Armbian Trixie para R36S**: Mantido por [ohjhas/armbian-r36s](https://github.com/ohjhas/armbian-r36s) (Release ).
- **Projeto Base Original**: Baseado no fork de [EatPrilosec/R36S-Armbian](https://github.com/EatPrilosec/R36S-Armbian) e no ecossistema [Armbian Linux](https://github.com/armbian/build).
- **Suporte de Painéis e Telas**: Árvore de dispositivos e drivers da comunidade [R36S-Stuff](https://github.com/R36S-Stuff).

*O projeto deste repositório desenvolve exclusivamente a camada de interface/automação BMO e reconhece com gratidão o trabalho das equipes upstream.*
