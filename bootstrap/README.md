# BMO Bootstrap — do zero ao BMO

Este diretório documenta o caminho mais simples para sair da imagem original do R36S e chegar ao BMO.

O fluxo principal usa os próprios recursos que já vêm na imagem:

```text
Gravar imagem
    ↓
abrir partição BOOT no PC
    ↓
selecionar ScreenFiles corretas
    ↓
editar firstrun_overrides.txt
    ↓
primeiro boot do R36S
    ↓
Wi-Fi + usuário r36s
    ↓
Git clone
    ↓
sudo ./install/install.sh
    ↓
BMO completo
```

---

## 1. Grave a imagem

Use a imagem validada do projeto `ohjhas/armbian-r36s`:

```text
armbian-r36s-trixie-xfce.img.xz
SHA256: 5f9f35375c88fd945e780577cd92d1a30a58675a7eb043fd4547bcc77895a2e6
```

Depois da gravação, remova e reconecte o cartão se necessário.

No Windows deverá aparecer uma partição chamada aproximadamente:

```text
boot
```

Essa é a partição que usamos antes do primeiro boot.

---

## 2. IMPORTANTE — configure a tela correta

Na partição `boot` existe uma pasta `ScreenFiles` com variações de painel.

O projeto-base possui variantes como:

```text
ScreenFiles/
├── Panel 0/
├── Panel 1/
├── Panel 2/
├── Panel 3/
└── Panel 4/
```

Você precisa usar a variante correta para o painel do seu R36S.

### O que copiar

Entre na pasta correspondente ao painel correto e copie **os arquivos que estão dentro dela** para a raiz da partição `boot`.

Exemplo conceitual:

```text
ANTES

boot/
├── ScreenFiles/
│   ├── Panel 0/
│   ├── Panel 1/
│   ├── Panel 2/
│   ├── Panel 3/
│   └── Panel 4/
├── firstrun_overrides.txt
└── ...


ESCOLHEU O PAINEL CORRETO

ScreenFiles/Panel X/
└── arquivos do painel

              ↓ copiar o CONTEÚDO

boot/
├── arquivos do painel  ← aqui
├── ScreenFiles/
├── firstrun_overrides.txt
└── ...
```

**Não copie apenas a pasta `Panel X` para a raiz.** Copie os arquivos que estão dentro dela.

Se o Windows perguntar se deseja substituir arquivos existentes, isso pode fazer parte da seleção do painel.

> Usar arquivos de painel incorretos pode resultar em tela apagada, imagem incorreta ou boot sem vídeo. Não escolha um painel aleatoriamente se você já sabe qual variante funciona no seu aparelho.

---

## 3. Configure o primeiro boot pelo arquivo que já vem na imagem

Na raiz da partição `boot` existe:

```text
firstrun_overrides.txt
```

Esse é o arquivo que recomendamos editar.

A imagem original usa esse arquivo no primeiro login. Dentro do Linux ele aparece em:

```text
/boot/u-boot/firstrun_overrides.txt
```

O script original lê esse arquivo e usa as variáveis para criar o usuário e configurar o Wi-Fi.

### Exemplo que vem na imagem

A imagem pode vir com valores semelhantes a:

```text
rootpass=r36s
FancyUserName=R36S
username=r36s
userpass=r36s
ssid=WiFi
wifipass=asuhdude
```

Esses são valores padrão, não dados pessoais do BMO.

### O que recomendamos editar antes de ligar

Exemplo:

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

Também existe um modelo sem credenciais reais neste repositório:

[`firstrun_overrides.example.txt`](firstrun_overrides.example.txt)

### O que cada campo significa

| Campo | Função |
|---|---|
| `rootpass` | senha administrativa do Linux |
| `FancyUserName` | nome descritivo do usuário |
| `username` | nome da conta Linux; para o BMO usamos `r36s` |
| `userpass` | senha da conta `r36s` |
| `ssid` | nome da rede Wi-Fi |
| `wifipass` | senha da rede Wi-Fi |
| `timezone` | fuso horário; recomendamos `America/Sao_Paulo` |
| `locale` | idioma/localização; recomendamos `pt_BR.UTF-8` |

O script original usa DHCP para o Wi-Fi, portanto normalmente o roteador atribui o IP automaticamente.

---

## 4. Segurança

O `firstrun_overrides.txt` contém senhas em texto simples.

Por isso:

- edite apenas a cópia que está no seu cartão;
- nunca envie o arquivo preenchido para o Git;
- nunca publique prints que mostrem as senhas;
- para uso permanente, prefira SSH por chave depois que o aparelho estiver configurado.

O arquivo de exemplo do Git contém apenas `CHANGE_ME`.

---

## 5. Primeiro boot

Depois de configurar:

1. ejete o cartão corretamente do PC;
2. coloque-o no TF1 do R36S;
3. ligue o aparelho;
4. aguarde o primeiro boot terminar.

O script original deverá:

1. definir a senha de `root`;
2. criar o usuário informado em `username`;
3. definir a senha desse usuário;
4. adicionar o usuário aos grupos necessários do aparelho;
5. configurar o Wi-Fi informado;
6. usar DHCP para obter um IP;
7. aplicar `timezone` e `locale` quando informados;
8. iniciar o ambiente gráfico.

O usuário padrão recomendado pelo BMO é:

```text
r36s
```

---

## 6. Descobrir o IP e acessar por SSH

Depois que o Wi-Fi estiver conectado, descubra o IP do R36S no roteador ou pela sua rede local.

Exemplo:

```bash
ssh r36s@IP_DO_R36S
```

Use a senha colocada em:

```text
userpass=
```

Neste ponto já conseguimos continuar a instalação remotamente.

---

## 7. Clonar o Git privado

Enquanto o projeto BMO estiver privado, o GitHub exige autenticação para fazer o clone.

Durante o desenvolvimento usamos uma **Deploy Key somente leitura**, exclusiva do aparelho.

A chave privada nunca deve ser adicionada ao Git.

Depois que a chave estiver autorizada:

```bash
git clone git@github.com:williamandrade01wa-lab/BMO_R36S.git
cd BMO_R36S
```

Para testar a versão em desenvolvimento atual:

```bash
git switch feat/installer-updater-v1
```

### Quando o BMO for público

Essa etapa ficará mais simples e não exigirá Deploy Key:

```bash
git clone https://github.com/USUARIO/BMO_R36S.git
cd BMO_R36S
```

---

## 8. Instalar o BMO

Existe um único ponto de entrada para a instalação real:

```bash
sudo ./install/install.sh
```

Não execute manualmente os scripts antigos de build/sandbox em `install/phases/`.

O resultado esperado ao final é:

```text
BMO_INSTALL_COMPLETE_OK
```

Depois reinicie quando o instalador solicitar.

---

## 9. Validar depois do reboot

Comece por:

```bash
bmo status
bmo verify
```

Depois valide fisicamente:

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

A instalação limpa não inclui ROMs, saves, favoritos pessoais ou pareamento Moonlight.

---

## 10. Por que usamos `firstrun_overrides.txt`?

Porque essa imagem do R36S já foi construída para isso.

O script `armbian-firstlogin` do projeto-base procura:

```text
/boot/u-boot/firstrun_overrides.txt
```

Depois carrega as variáveis desse arquivo e configura usuário, senha, Wi-Fi, timezone e locale.

Portanto, para a experiência normal de instalação, **não precisamos montar a partição Linux rootfs apenas para configurar o primeiro boot**.

Os arquivos antigos `firstboot.conf.example`, `apply-to-rootfs.sh` e `provisioning.sh` permanecem temporariamente no branch enquanto consolidamos o fluxo, mas não são mais o caminho recomendado para esta imagem.

---

## Resumo rápido

```text
1. Grave a imagem
2. Abra a partição BOOT
3. Copie o conteúdo da ScreenFiles correta para a raiz do BOOT
4. Edite firstrun_overrides.txt
5. Ejete o cartão
6. Ligue o R36S
7. Descubra o IP
8. SSH
9. Git clone
10. sudo ./install/install.sh
```
