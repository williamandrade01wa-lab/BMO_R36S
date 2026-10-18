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

### 2. Opcional: deixe Wi-Fi, usuário e rede prontos antes do primeiro boot

Se quiser que o R36S já tente conectar sozinho ao ligar, use o bootstrap.

**[📖 Abrir o manual de primeiro boot](bootstrap/README.md)**

**[⚙️ Abrir o arquivo modelo de configuração](bootstrap/firstboot.conf.example)**

O fluxo é:

```text
firstboot.conf.example
        ↓ copiar
firstboot.local.conf
        ↓ editar
Wi-Fi / senha / DHCP ou IP fixo / usuário
        ↓
aplicar na imagem-base
        ↓
ligar o R36S
```

Crie uma configuração local a partir do modelo:

```bash
cp bootstrap/firstboot.conf.example bootstrap/firstboot.local.conf
chmod 600 bootstrap/firstboot.local.conf
```

Depois edite apenas:

```text
bootstrap/firstboot.local.conf
```

> **Nunca coloque sua senha de Wi-Fi, senha do usuário, token ou chave privada no Git.**
>
> Arquivos `bootstrap/*.local.conf` são ignorados e também bloqueados pela auditoria de segurança do projeto.

Se você não quiser pré-configurar nada, pode simplesmente iniciar a imagem e configurar rede/usuário manualmente.

---

### 3. Ligue o R36S e acesse por SSH

Com o bootstrap aplicado, o padrão esperado é:

```text
hostname: bmo-r36s
usuario:  r36s
```

Exemplo:

```bash
ssh r36s@bmo-r36s
```

Se sua rede não resolver o hostname, use o IP entregue pelo roteador:

```bash
ssh r36s@IP_DO_R36S
```

**[🔎 Ver instruções completas de rede e primeiro boot](bootstrap/README.md#5-primeiro-boot)**

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
┌──────────────────────────┐
│ Armbian Trixie R36S      │
│ imagem original          │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ Bootstrap (opcional)     │
│ Wi-Fi / IP / user / SSH  │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ Primeiro boot do R36S    │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ Git clone BMO_R36S       │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ sudo ./install/install.sh│
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ BMO completo             │
└──────────────────────────┘
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
| Configurar Wi-Fi/IP antes de ligar | **[firstboot.conf.example](bootstrap/firstboot.conf.example)** |
| Aplicar o preset em uma imagem montada | **[apply-to-rootfs.sh](bootstrap/apply-to-rootfs.sh)** |
| Ver o que roda no primeiro boot | **[provisioning.sh](bootstrap/provisioning.sh)** |
| Instalar o BMO | **[install/install.sh](install/install.sh)** |
| Ver créditos/origem da Pure | **[CREDITS.md](CREDITS.md)** |
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
