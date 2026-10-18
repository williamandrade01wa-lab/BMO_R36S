# BMO R36S

Transforme uma instalação limpa de **Armbian Trixie para R36S** em um R36S com o BMO completo usando este repositório.

> **Quer instalar do zero?** Você não precisa conhecer o histórico do projeto. Siga o caminho abaixo.

## 🚀 Quero instalar o BMO do zero

### 1. Baixe e grave a imagem-base

A imagem-base que validamos veio do projeto **ohjhas/armbian-r36s**:

**[⬇️ Abrir a release original Armbian Trixie para R36S](https://github.com/ohjhas/armbian-r36s/releases/tag/trixie-r1)**

Arquivo validado:

```text
armbian-r36s-trixie-xfce.img.xz
SHA256: 5f9f35375c88fd945e780577cd92d1a30a58675a7eb043fd4547bcc77895a2e6
```

Grave a imagem em um microSD destinado ao TF1 do R36S.

**[🙏 Ver créditos e origem da imagem](CREDITS.md)**

---

### 2. Antes do primeiro boot: tela + Wi-Fi + usuário

Depois da gravação, abra no PC a partição chamada `boot`.

Ela já contém os arquivos necessários para preparar o primeiro boot.

#### 2.1 Selecione a ScreenFile correta

Dentro da partição existe a pasta `ScreenFiles` com variantes de painel.

Entre na pasta correspondente ao painel correto do seu R36S e **COPIE os arquivos que estão dentro dela** para a raiz da partição `boot`.

```text
boot/
├── ScreenFiles/
│   └── Panel X/
│       └── arquivos do painel
│
└── ...

          ↓ COPIAR o conteúdo de Panel X

boot/
├── cópia dos arquivos do painel  ← aqui
├── ScreenFiles/
│   └── Panel X/
│       └── arquivos originais continuam aqui
└── ...
```

> **IMPORTANTE: COPIE, NÃO MOVA.**
>
> Use **Copiar + Colar**. Não use **Recortar + Colar**. Os arquivos originais precisam continuar dentro de `ScreenFiles/Panel X/`; mover os arquivos pode causar erro no boot.

> Não copie somente a pasta `Panel X`. Copie os arquivos contidos nela para a raiz do `boot`.

Usar a variante errada pode resultar em tela apagada ou imagem incorreta.

#### 2.2 Edite `firstrun_overrides.txt`

Na própria raiz da partição `boot` existe:

```text
firstrun_overrides.txt
```

A imagem já usa esse arquivo para configurar automaticamente o primeiro login.

Exemplo original:

```text
rootpass=r36s
FancyUserName=R36S
username=r36s
userpass=r36s
ssid=WiFi
wifipass=asuhdude
```

Antes de ligar, recomendamos alterar pelo menos:

```text
rootpass=SUA_SENHA_ROOT
FancyUserName=R36S
username=r36s
userpass=SUA_SENHA_R36S
ssid=SEU_WIFI
wifipass=SUA_SENHA_WIFI
timezone=America/Sao_Paulo
locale=pt_BR.UTF-8
```

**[📖 Abrir o manual completo de primeiro boot](bootstrap/README.md)**

**[⚙️ Ver um modelo de `firstrun_overrides.txt`](bootstrap/firstrun_overrides.example.txt)**

> O arquivo contém senhas em texto simples. Edite apenas o cartão e nunca envie uma cópia preenchida para o Git.

---

### 3. Primeiro boot: aguarde o processo automático

Depois de preparar o cartão:

1. ejete o microSD corretamente;
2. coloque-o no TF1 do R36S;
3. ligue o aparelho;
4. **aguarde o boot automático concluir**.

> **Podem acontecer reinicializações durante o primeiro boot.** Não interrompa o processo apenas porque o aparelho reiniciou ou a tela mudou. Aguarde a inicialização terminar.

A imagem deverá criar o usuário `r36s`, aplicar as senhas informadas e tentar conectar ao Wi-Fi configurado em `firstrun_overrides.txt`.

O endereço IP normalmente é entregue automaticamente pelo roteador via DHCP.

#### Se ficar em tela preta

Se a tela permanecer preta e o boot não prosseguir:

1. aguarde primeiro para confirmar que o processo realmente parou;
2. desligue o R36S pelo botão **POWER**;
3. retire o microSD;
4. conecte o cartão novamente ao PC;
5. abra a partição `boot`;
6. verifique o erro/arquivo de diagnóstico gerado dentro do diretório `boot` antes de alterar outras coisas.

Confirme também se os arquivos da ScreenFile correta foram **copiados** e se os originais ainda estão dentro de `ScreenFiles/Panel X/`.

Depois que o boot concluir, descubra o IP na sua rede e acesse:

```bash
ssh r36s@IP_DO_R36S
```

Use a senha configurada em:

```text
userpass=
```

**[🔎 Ver instruções completas de primeiro boot e rede](bootstrap/README.md#5-primeiro-boot--aguarde-o-processo-automático)**

---

### 4. Clone o projeto

#### Enquanto o projeto estiver privado

O GitHub exige autenticação para ler um repositório privado. Durante o desenvolvimento usamos uma **Deploy Key somente leitura**, exclusiva do aparelho.

**[🔐 Ver como funciona o acesso ao Git privado](bootstrap/README.md#7-clonar-o-git-privado)**

Depois que a chave estiver autorizada:

```bash
git clone git@github.com:williamandrade01wa-lab/BMO_R36S.git
cd BMO_R36S
```

#### Quando existir a versão pública

A instalação normal não precisará de chave, token ou senha do GitHub. O clone será por HTTPS:

```bash
git clone https://github.com/USUARIO/BMO_R36S.git
cd BMO_R36S
```

**[🌐 Entender o plano privado → público](docs/PUBLIC-RELEASE.md)**

Durante testes, pode ser necessário selecionar uma branch específica antes de instalar. Na versão estável, o fluxo será pela `main`.

---

### 5. Instale o BMO

Existe **um único comando de instalação**:

```bash
sudo ./install/install.sh
```

**[🛠️ Ver o instalador](install/install.sh)**

Não execute manualmente os scripts antigos em `install/phases/`. Eles são ferramentas de build/sandbox e não são o instalador do aparelho.

O final esperado é:

```text
BMO_INSTALL_COMPLETE_OK
```

Depois, reinicie quando o instalador solicitar.

---

### 6. Valide o BMO

Após o reboot:

```bash
bmo status
bmo verify
```

E valide fisicamente:

- interface/kiosk do BMO;
- D-pad e botões;
- volume e brilho;
- SYSTEM / CONTROL;
- GBA;
- SNES;
- PSP;
- PC STREAM / Moonlight;
- Wi-Fi;
- retorno ao BMO depois de jogos e streaming.

**[✅ Ver checklist completo pós-instalação](bootstrap/README.md#9-validar-depois-do-reboot)**

---

## 🗺️ Resumo visual

```text
┌──────────────────────────────┐
│ Gravar Armbian Trixie R36S   │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Abrir partição BOOT          │
│ COPIAR ScreenFiles + firstrun│
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Primeiro boot automático     │
│ aguardar reinicializações    │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ SSH + Git clone              │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ sudo ./install/install.sh    │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ BMO completo                 │
└──────────────────────────────┘
```

## 📦 O que o BMO instala e o que pertence a terceiros?

O código do BMO é separado dos programas externos que ele usa.

```text
BMO
├── frontend / backend / launchers / services
│
├── instala Moonlight a partir da fonte oficial
├── instala PPSSPP a partir da fonte oficial
├── instala RetroArch/cores pelo sistema
└── não precisa republicar a imagem Linux original
```

Durante o desenvolvimento privado ainda mantemos runtimes congelados para reproduzir o primeiro teste da Pure. Eles são temporários e **não fazem parte da estratégia pública final**.

**[📦 Ver política de dependências de terceiros](THIRD_PARTY.md)**

As versões, URLs e hashes upstream ficam registrados em:

**[`install/manifests/upstream-sources.env`](install/manifests/upstream-sources.env)**

---

## 📚 Atalhos

| Quero... | Abrir |
|---|---|
| Fazer tudo do zero | **[Manual completo](bootstrap/README.md)** |
| Ver como preparar a partição BOOT | **[Manual de primeiro boot](bootstrap/README.md)** |
| Ver modelo do `firstrun_overrides.txt` | **[firstrun_overrides.example.txt](bootstrap/firstrun_overrides.example.txt)** |
| Instalar o BMO | **[install/install.sh](install/install.sh)** |
| Ver créditos/origem da imagem | **[CREDITS.md](CREDITS.md)** |
| Ver dependências externas | **[THIRD_PARTY.md](THIRD_PARTY.md)** |
| Entender como ficará público | **[PUBLIC-RELEASE.md](docs/PUBLIC-RELEASE.md)** |
| Entender regras do projeto/Codex | **[AGENTS.md](AGENTS.md)** |

## Estrutura do projeto

```text
bootstrap/   primeiro boot e manual de instalação limpa
frontend/    interface do BMO
backend/     APIs locais
launchers/   jogos, kiosk e Moonlight
configs/     configurações versionadas
systemd/     serviços do sistema
install/     instalador, manifests e runtime privado temporário
scripts/     validação, deploy e utilitários
docs/        documentação adicional
```

## Desenvolvimento e promoção

No aparelho de desenvolvimento:

```text
editar → validar → candidate → teste físico → backup → produção
```

- **Produção no R36S:** `/opt/bmo-ui/index.html`
- **Candidate no R36S:** `/opt/bmo-ui/index.bmo-next.html`
- **Le Potato:** deploy, validação, backup e rollback

Alterações não devem ir para produção sem validação e teste físico no R36S.

## Segurança

O Git não deve conter ROMs, saves, states, backups privados, chaves SSH, tokens, credenciais, senhas reais de Wi-Fi ou o conteúdo privado de `Moonlight.conf`.

Use sempre arquivos locais ignorados pelo Git para dados específicos de cada aparelho/rede.

Antes de uma versão pública, o projeto passará por uma exportação limpa e auditoria específica para evitar levar o histórico privado desnecessário para o repositório público.
