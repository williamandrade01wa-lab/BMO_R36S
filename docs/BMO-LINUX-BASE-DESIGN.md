# BMO Linux Base — arquitetura pública desde o início

Este documento define a arquitetura da futura imagem **BMO Linux Base** para R36S.

A regra principal é simples:

> A imagem deve ser construída como se o repositório BMO já fosse público, mesmo enquanto o desenvolvimento continuar em um Git privado.

A imagem **não deve conter chaves SSH, tokens, credenciais GitHub ou qualquer segredo de desenvolvimento**.

Durante a fase privada, o desenvolvedor configura manualmente o acesso SSH ao Git depois do boot. Quando o repositório público existir, a mesma imagem deverá funcionar por HTTPS sem precisar ser redesenhada.

---

## 1. Objetivo

Criar uma imagem mínima e dedicada ao BMO:

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

A imagem base não deve depender do XFCE nem de um desktop tradicional.

---

## 2. Princípios

### 2.1 Público por padrão

A distribuição final deve usar leitura pública por HTTPS:

```text
https://github.com/.../BMO_R36S.git
```

Nenhuma chave é necessária para instalar ou atualizar uma versão pública.

### 2.2 Privado apenas durante desenvolvimento

Enquanto o Git continuar privado:

```text
R36S de teste
   ↓
chave SSH criada manualmente
   ↓
chave pública autorizada manualmente no GitHub
   ↓
fonte Git temporariamente alterada para SSH
```

Esse processo não faz parte da imagem e não deixa segredo gravado na distribuição.

### 2.3 Base pequena, BMO atualizável

A imagem contém apenas o necessário para conseguir:

- iniciar;
- reconhecer o hardware;
- configurar rede;
- aceitar SSH;
- executar `bmo`;
- instalar o BMO pela rede.

Frontend, backend, launchers e componentes atualizáveis pertencem ao repositório BMO e não precisam ser congelados dentro da imagem base.

### 2.4 A BOOT é a interface para quem usa Windows

A partição de boot deve continuar legível pelo Windows.

O usuário não precisa montar ext4 para preparar o primeiro boot.

---

## 3. Imagem base

A base deve ser gerada com o Armbian Build Framework ou com a árvore R36S-Armbian compatível já validada, preservando os ajustes específicos do R36S.

Meta de build:

```text
Debian Trixie
BUILD_MINIMAL=yes
BUILD_DESKTOP=no
```

Manter apenas os pacotes necessários ao aparelho e ao bootstrap.

### Pacotes mínimos esperados

- bash
- systemd
- sudo
- ca-certificates
- git
- openssh-client
- openssh-server
- curl ou wget
- iproute2
- NetworkManager
- wpasupplicant
- rfkill
- udev
- python3
- utilitários ALSA necessários

A lista final deve ser medida e validada em hardware real.

### Não incluir na base

- XFCE;
- gerenciador de desktop;
- navegador de desktop;
- suíte de escritório;
- utilitários gráficos genéricos;
- jogos;
- ROMs;
- saves;
- credenciais;
- runtimes BMO de terceiros que possam ser obtidos de upstream durante a instalação.

---

## 4. Hardware que precisa sobreviver à migração

Antes de considerar a imagem base pronta, preservar e testar:

- U-Boot;
- kernel;
- DTB do R36S;
- ScreenFiles / painel MIPI;
- framebuffer/DRM necessário à tela;
- gamepad interno;
- D-pad e botões;
- hotkeys;
- áudio;
- volume;
- brilho;
- USB OTG;
- HUB USB;
- Wi-Fi USB;
- Bluetooth se utilizado;
- bateria / leitura de energia quando disponível;
- TF1 e TF2;
- RTC/timezone;
- SSH.

O mapeamento atual dos botões deve ser capturado antes de abandonar a imagem de referência e transformado em configuração versionada do BMO.

---

## 5. Estrutura da partição BOOT

Proposta pública:

```text
BOOT/
├── ScreenFiles/
│   ├── Panel 0/
│   ├── Panel 1/
│   ├── Panel 2/
│   ├── Panel 3/
│   └── Panel 4/
│
├── BMO-FIRSTBOOT.txt
├── README-FIRST-BOOT.txt
├── README-SCREENFILES.txt
├── BMO-IP.txt
├── BMO-STATUS.txt
└── logs/
    ├── firstboot.log
    ├── network.log
    └── install.log
```

`BMO-IP.txt`, `BMO-STATUS.txt` e `logs/` podem ser criados pelo sistema no primeiro boot.

Nunca gravar senhas nesses arquivos de status/log.

---

## 6. ScreenFiles

Manter a mesma lógica já comprovada no R36S:

1. o usuário identifica o painel correto;
2. entra em `ScreenFiles/Panel X/`;
3. **COPIA** os arquivos para a raiz da BOOT;
4. os originais permanecem dentro de `ScreenFiles`.

Nunca orientar o usuário a mover os arquivos.

A documentação da própria BOOT deve explicar isso mesmo quando o usuário não tiver aberto o GitHub.

---

## 7. BMO-FIRSTBOOT.txt

A nova imagem não deve `source` esse arquivo como Shell.

O bootstrap deve usar um parser limitado a uma lista conhecida de chaves. Isso evita que caracteres especiais em SSID/senhas sejam interpretados como comandos e evita execução arbitrária como root.

Formato simples atual (v0.2, melhoria de UX de 2026-10-24):

```text
REDE_WIFI=
SENHA_WIFI=
SENHA_USUARIO=r36s
ACESSO_REMOTO=nao
```

Aliases são normalizados pelo parser: REDE_WIFI → WIFI_SSID, SENHA_WIFI → WIFI_PASSWORD, SENHA_USUARIO → USER_PASSWORD e ACESSO_REMOTO → SSH_ENABLED. Nome de Wi-Fi preenchido ativa Wi-Fi se WIFI_ENABLED não foi explicitamente informado. `sim`/`nao` são aceitos; arquivo é dado literal, nunca Shell. Opções duplicadas via alias/nome antigo são recusadas para evitar ambiguidades. Senhas dos dois formatos são sanitizadas.

O console mostra resumo com rede local/IP/SSH; `--summary` atualiza a visualização sem reaplicar configurações. `BMO-RESUMO.txt` fica na BOOT. O perfil de login reapresenta o resumo com o IP atual após reboot. O IP não comprova internet.

Formato avançado legado, ainda aceito:

```text
# Rede
WIFI_SSID=CHANGE_ME
WIFI_PASSWORD=CHANGE_ME

# Usuario
USER_NAME=r36s
USER_PASSWORD=CHANGE_ME
ROOT_PASSWORD=CHANGE_ME

# Sistema
HOSTNAME=bmo-r36s
TIMEZONE=America/Sao_Paulo
LOCALE=pt_BR.UTF-8

# BMO
BMO_AUTO_INSTALL=no
BMO_CHANNEL=stable
```

Regras:

- somente chaves conhecidas;
- uma linha `CHAVE=VALOR`;
- comentários iniciados por `#`;
- nenhuma expansão de `$`, backticks ou `$(...)`;
- o valor é tratado literalmente;
- senhas nunca entram em logs;
- arquivo pode ser apagado ou sanitizado depois de aplicado.

### IP

DHCP continua sendo o padrão.

A primeira versão não precisa exigir IP fixo.

Depois de conectar, o sistema grava apenas o endereço recebido em:

```text
BOOT/BMO-IP.txt
```

Exemplo:

```text
HOSTNAME=bmo-r36s
IPV4=192.168.1.123
SSH=ssh r36s@192.168.1.123
```

---

## 8. Serviço de primeiro boot

A imagem terá um serviço dedicado, por exemplo:

```text
bmo-firstboot.service
```

Fluxo:

```text
boot
 ↓
ler BMO-FIRSTBOOT.txt
 ↓
validar sintaxe
 ↓
configurar usuario/senhas
 ↓
configurar Wi-Fi com autoconnect
 ↓
configurar timezone/locale/hostname
 ↓
obter IP
 ↓
grava BMO-IP.txt e BMO-STATUS.txt
 ↓
marca firstboot concluido
 ↓
opcionalmente chama bmo install
```

O serviço deve ser idempotente: reiniciar o aparelho não pode recriar usuário ou destruir uma rede já configurada.

Em falha, gravar diagnóstico em `BOOT/logs/firstboot.log` sem segredos.

---

## 9. Rede

Preferir NetworkManager em modo CLI, sem frontend gráfico.

Requisitos:

- Wi-Fi USB reconhecido;
- conexão criada com `autoconnect=yes`;
- DHCP por padrão;
- reconexão automática após reboot;
- comando de diagnóstico disponível pelo `bmo`;
- status e IP gravados na BOOT.

A imagem deve incorporar as regras necessárias para o HUB/Wi-Fi já identificadas no BMO, depois de validadas novamente na imagem mínima.

---

## 10. Comando `bmo` presente desde a imagem base

A imagem deve nascer com `/usr/local/bin/bmo`.

Ele terá dois estágios lógicos.

### Estágio Base

Antes do BMO completo existir:

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

### Estágio Instalado

Depois de instalar o BMO:

```text
bmo status
bmo verify
bmo check-update
bmo update
bmo promote
bmo rollback
bmo config
bmo logs
bmo doctor
```

O usuário não precisa aprender dois executáveis diferentes.

---

## 11. Fonte Git

A imagem deve ser orientada ao Git público.

### Fonte padrão futura

```text
BMO_REPO_TRANSPORT=https
BMO_REPO_URL=https://github.com/OWNER/BMO_R36S.git
BMO_BRANCH=main
BMO_CHANNEL=stable
```

Esses valores ficam em defaults públicos da imagem, nunca em um arquivo secreto.

### Desenvolvimento privado

Durante desenvolvimento, depois de entrar por SSH e configurar uma chave manualmente, o desenvolvedor pode alterar a fonte local:

```text
BMO_REPO_TRANSPORT=ssh
BMO_REPO_URL=git@github.com:williamandrade01wa-lab/BMO_R36S.git
BMO_BRANCH=feat/...
```

A chave SSH continua fora da imagem e fora do Git.

### Regra de segurança

`bmo install` e `bmo update` devem aceitar somente origens e protocolos explicitamente permitidos. Não executar scripts arbitrários vindos de URLs fornecidas sem validação.

---

## 12. Instalação automática

A base suporta, mas não precisa habilitar por padrão:

```text
BMO_AUTO_INSTALL=no
```

### BMO Linux Base

`no` é o padrão.

O usuário vê o sistema funcionando e chama:

```text
bmo install
```

### BMO Ready (futuro)

Uma variante futura poderá usar:

```text
BMO_AUTO_INSTALL=yes
```

Depois que o fluxo estiver estável e recuperável.

---

## 13. Dependências externas

A imagem pública não deve embutir cópias desnecessárias de programas de terceiros quando a instalação puder obter uma versão pinada da fonte oficial.

Fluxo desejado:

```text
bmo install
├── valida arquitetura
├── valida versão
├── baixa upstream oficial
├── confere SHA256
└── instala
```

Isso vale especialmente para Moonlight e PPSSPP.

---

## 14. Estrutura proposta no repositório

```text
image/
├── README.md
├── boot/
│   ├── BMO-FIRSTBOOT.example.txt
│   ├── README-FIRST-BOOT.txt
│   └── README-SCREENFILES.txt
│
└── armbian/
    └── userpatches/
        ├── config-bmo-r36s.conf
        ├── customize-image.sh
        ├── extensions/
        └── overlay/
            ├── usr/local/bin/bmo
            ├── usr/local/sbin/bmo-bootstrap
            ├── usr/share/bmo/defaults.conf
            ├── etc/systemd/system/bmo-firstboot.service
            └── etc/udev/rules.d/
```

A implementação deve ficar em `userpatches/` sempre que possível, para evitar editar diretamente o Build Framework upstream.

---

## 15. Versionamento

Separar versão da imagem e versão do aplicativo.

Exemplo:

```text
BMO Linux Base 1.0.0
BMO App 1.4.2
```

A imagem base deve mudar apenas quando kernel, boot, drivers, bootstrap ou componentes fundamentais mudarem.

O BMO App pode evoluir via Git/update sem exigir nova gravação do SD.

---

## 16. Publicação

Antes de publicar a primeira imagem:

- gerar a imagem a partir de build reproduzível;
- registrar commit/fonte do Armbian e R36S-Armbian utilizados;
- registrar SHA256 da imagem;
- incluir créditos/licenças aplicáveis;
- garantir ausência de chaves/tokens/senhas;
- garantir ausência de dados de rede pessoais;
- testar cartão novo;
- testar primeiro boot apenas com arquivos da BOOT;
- testar Wi-Fi e reboot;
- testar SSH;
- testar `bmo install` por HTTPS público;
- testar update;
- testar recuperação após falha de rede.

---

## 17. Fluxo final desejado

```text
Usuário baixa BMO Linux Base
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
rede + usuario + SSH
          ↓
BMO-IP.txt aparece na BOOT
          ↓
bmo install
          ↓
HTTPS público, sem chave
          ↓
BMO completo
```

Durante desenvolvimento privado, somente a etapa de acesso ao Git muda. A arquitetura da imagem permanece a mesma.
