# BMO Bootstrap — do zero ao BMO

Este diretório existe para que qualquer pessoa com:

- um R36S compatível;
- a imagem **BMO Linux Pure R36S**;
- acesso a este repositório Git;
- um microSD de teste;

consiga sair de uma instalação limpa e chegar ao BMO sem depender do histórico de desenvolvimento do projeto.

## Visão geral

```text
BMO Linux Pure
      ↓
primeiro boot pré-configurado (opcional)
      ↓
Wi-Fi + usuário r36s + SSH
      ↓
git clone BMO_R36S
      ↓
sudo ./install/install.sh
      ↓
BMO completo
```

O bootstrap cuida somente da conveniência do primeiro boot. O sistema BMO completo continua sendo instalado pelo `install/install.sh`.

---

## 1. Segurança primeiro

Nunca coloque senhas reais, chaves SSH, tokens ou credenciais no Git.

O arquivo versionado é apenas:

```text
bootstrap/firstboot.conf.example
```

Crie sua cópia local:

```bash
cp bootstrap/firstboot.conf.example bootstrap/firstboot.local.conf
chmod 600 bootstrap/firstboot.local.conf
```

Depois edite `bootstrap/firstboot.local.conf`.

O arquivo `firstboot.local.conf` é local e deve permanecer fora do Git.

---

## 2. Configurar Wi-Fi, usuário e IP

No arquivo local, os campos mínimos para um primeiro boot totalmente automático são:

```text
PRESET_NET_WIFI_SSID
PRESET_NET_WIFI_KEY
PRESET_ROOT_PASSWORD
PRESET_USER_PASSWORD
```

A base já usa:

```text
PRESET_USER_NAME="r36s"
PRESET_NET_WIFI_COUNTRYCODE="BR"
PRESET_LOCALE="pt_BR.UTF-8"
PRESET_TIMEZONE="America/Sao_Paulo"
```

### DHCP

Por padrão:

```text
PRESET_NET_USE_STATIC="0"
```

O roteador escolherá o IP.

### IP fixo

Para usar IP fixo, altere:

```text
PRESET_NET_USE_STATIC="1"
```

E preencha todos os campos estáticos no arquivo.

Não use um IP sem saber se ele está livre na sua rede.

---

## 3. Onde o Armbian lê a configuração

A autoconfiguração oficial do Armbian usa:

```text
/root/.not_logged_in_yet
```

E executa uma vez, após o primeiro login bem-sucedido:

```text
/root/provisioning.sh
```

Documentação oficial:

- https://docs.armbian.com/user-guide/autoconfig/

Importante: esses arquivos ficam na **rootfs Linux**, não na partição FAT/BOOT visível normalmente no Windows.

O script `apply-to-rootfs.sh` existe para fazer essa cópia com validações.

---

## 4. Injetar o preset na Pure

Em uma máquina Linux, monte a partição root da Pure. Exemplo conceitual:

```bash
sudo mkdir -p /mnt/bmo-rootfs
sudo mount /dev/SEU_DISPOSITIVO_ROOT /mnt/bmo-rootfs
```

Confirme com cuidado qual é a partição correta. Nunca copie exemplos de `/dev/...` sem verificar o seu dispositivo.

Depois, dentro do repositório:

```bash
sudo bash ./bootstrap/apply-to-rootfs.sh /mnt/bmo-rootfs
```

O resultado esperado é:

```text
BMO FIRSTBOOT PRESET APPLIED
```

Desmonte corretamente:

```bash
sync
sudo umount /mnt/bmo-rootfs
```

Agora o cartão pode ser colocado no R36S.

---

## 5. Primeiro boot

Ao iniciar a Pure com o preset aplicado, o Armbian deverá tentar automaticamente:

1. configurar a rede;
2. conectar no Wi-Fi informado;
3. criar o usuário `r36s`;
4. aplicar locale/timezone;
5. executar `provisioning.sh`;
6. definir o hostname como `bmo-r36s`;
7. habilitar/iniciar SSH caso o serviço já exista na Pure.

O `provisioning.sh` propositalmente não instala pacotes, não clona o Git e não contém credenciais.

Se o preset de rede estiver incorreto, o aparelho pode ficar sem rede. Nesse caso, corrija a configuração ou faça o primeiro login localmente.

---

## 6. Encontrar e acessar o R36S

Se sua rede resolver hostnames locais, tente:

```bash
ssh r36s@bmo-r36s
```

Caso contrário, consulte o IP entregue pelo roteador e use:

```bash
ssh r36s@IP_DO_R36S
```

Use a senha definida em `PRESET_USER_PASSWORD`.

Depois que o ambiente estiver estabelecido, acesso por chave SSH é preferível a senha.

---

## 7. Clonar o Git privado

Este repositório é privado. Portanto, o dispositivo precisa de uma credencial Git autorizada para fazer o primeiro clone.

A estratégia oficial do BMO é uma **GitHub Deploy Key somente leitura**, exclusiva do dispositivo.

A chave privada nunca deve entrar no Git.

Durante a fase de desenvolvimento, use a branch indicada pelo projeto. Para a instalação estável, a intenção é usar `main`.

Fluxo esperado depois que a chave estiver autorizada:

```bash
git clone git@github.com:williamandrade01wa-lab/BMO_R36S.git
cd BMO_R36S
```

Em teste de uma branch antes da promoção:

```bash
git switch feat/installer-updater-v1
```

---

## 8. Instalar o BMO

A instalação real possui um único ponto de entrada:

```bash
sudo ./install/install.sh
```

Não execute manualmente as antigas fases de build/sandbox em `install/phases/`.

O instalador deve terminar com:

```text
BMO_INSTALL_COMPLETE_OK
```

Quando solicitado pelo instalador, reinicie o aparelho.

---

## 9. Validar depois do reboot

O mínimo esperado é:

```bash
bmo status
bmo verify
```

E fisicamente no R36S validar:

- tela/kiosk do BMO;
- D-pad e botões;
- volume e brilho;
- SYSTEM / CONTROL;
- GBA;
- SNES;
- PSP;
- PC STREAM / Moonlight;
- Wi-Fi;
- retorno ao BMO após sair de jogo/stream.

A instalação limpa não inclui ROMs, saves, favoritos pessoais ou pareamento Moonlight.

---

## 10. Arquivos deste diretório

```text
bootstrap/
├── README.md                  # este manual
├── firstboot.conf.example     # template sem segredos
├── provisioning.sh            # ações genéricas do primeiro boot
└── apply-to-rootfs.sh         # injeta os dois arquivos na Pure montada
```

Arquivo local esperado, mas nunca versionado:

```text
bootstrap/firstboot.local.conf
```

---

## Caminho sem preconfiguração

O bootstrap é opcional.

Se você preferir, pode iniciar a BMO Linux Pure sem preset, concluir manualmente o primeiro login do Armbian, configurar Wi-Fi e então seguir diretamente para a etapa do Git.

O objetivo do bootstrap é apenas tornar instalações repetidas e testes de cartões novos mais rápidos e previsíveis.
