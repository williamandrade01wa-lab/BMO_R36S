# BMO Roadmap

## Prioridade atual — BMO Linux Base pública por arquitetura

A direção do projeto mudou: em vez de manter o desktop XFCE como base definitiva, vamos estruturar uma imagem própria/minimalista para o R36S e desenhá-la desde o início para futura distribuição pública.

Arquitetura detalhada:

- [`BMO-LINUX-BASE-DESIGN.md`](BMO-LINUX-BASE-DESIGN.md)

Meta:

```text
boot / U-Boot / DTB
        ↓
Linux mínimo
        ↓
console + rede + SSH + hardware
        ↓
comando bmo
        ↓
bmo install
        ↓
BMO completo
```

## Princípios

- sem XFCE e sem aplicativos de desktop desnecessários;
- partição BOOT legível pelo Windows;
- ScreenFiles preservadas;
- configuração por `BMO-FIRSTBOOT.txt`;
- DHCP como padrão;
- IP/status/logs úteis gravados na BOOT sem segredos;
- `bmo` já presente na imagem base;
- imagem sem chave SSH, token ou credencial GitHub;
- Git público via HTTPS como arquitetura padrão;
- acesso ao Git privado configurado manualmente apenas durante desenvolvimento;
- dependências de terceiros obtidas de upstream oficial quando possível;
- versão da imagem base separada da versão do aplicativo BMO.

## Hardware a preservar e validar

Antes de aposentar a imagem de referência, capturar e validar:

- boot/U-Boot;
- ScreenFiles / suporte aos painéis;
- kernel e DTB do R36S;
- mapeamento completo dos controles físicos;
- hotkeys;
- áudio;
- volume;
- brilho;
- USB OTG;
- HUB USB;
- Wi-Fi USB;
- SSH;
- TF1/TF2;
- DRM/KMS/X mínimo necessário ao kiosk;
- Moonlight;
- RetroArch;
- PPSSPP.

## Fases

### Fase 1 — captura da referência

- [ ] capturar mapeamento dos botões da imagem funcional;
- [ ] capturar módulos/drivers importantes;
- [ ] validar OTG/HUB/Wi-Fi;
- [ ] registrar pacotes essenciais;
- [ ] registrar boot/DTB/ScreenFiles usados.

### Fase 2 — build mínimo

- [ ] criar `image/armbian/userpatches/`;
- [ ] configurar Debian Trixie minimal;
- [ ] `BUILD_MINIMAL=yes`;
- [ ] `BUILD_DESKTOP=no`;
- [ ] preservar suporte específico do R36S;
- [ ] incluir NetworkManager CLI e SSH;
- [ ] incluir `bmo` base.

### Fase 3 — primeiro boot BMO

- [ ] implementar parser seguro de `BMO-FIRSTBOOT.txt`;
- [ ] configurar usuário/senhas;
- [ ] configurar Wi-Fi com autoconnect;
- [ ] aplicar timezone/locale/hostname;
- [ ] gravar `BMO-IP.txt`;
- [ ] gravar `BMO-STATUS.txt`;
- [ ] gravar logs sanitizados na BOOT;
- [ ] garantir comportamento idempotente.

### Fase 4 — Git e instalação

- [ ] `bmo source`;
- [ ] `bmo install`;
- [ ] fonte pública HTTPS por padrão;
- [ ] override SSH manual para desenvolvimento privado;
- [ ] nenhum segredo embutido na imagem;
- [ ] integrar instalador atual.

### Fase 5 — BMO completo

- [ ] kiosk mínimo;
- [ ] gamepad;
- [ ] volume/brilho;
- [ ] SYSTEM / CONTROL;
- [ ] GBA/SNES/PSP;
- [ ] PC STREAM / Moonlight;
- [ ] updater;
- [ ] rollback.

### Fase 6 — publicação

- [ ] build reproduzível;
- [ ] créditos/licenças;
- [ ] SHA256 da imagem;
- [ ] auditoria pública;
- [ ] teste em cartão limpo;
- [ ] teste de `bmo install` por HTTPS sem chave;
- [ ] documentação final de Windows → BOOT → R36S → BMO.
