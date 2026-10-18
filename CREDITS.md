# Créditos e origem do projeto

O BMO é uma camada de interface, automação e integração criada para o R36S. Ele depende de projetos de terceiros para a base Linux, emulação e streaming.

## Imagem base usada pela BMO Linux Pure

A imagem atualmente usada como base foi identificada de forma verificável pelo nome do arquivo e SHA-256:

```text
armbian-r36s-trixie-xfce.img.xz
SHA256: 5f9f35375c88fd945e780577cd92d1a30a58675a7eb043fd4547bcc77895a2e6
```

Origem:

- **ohjhas/armbian-r36s** — Armbian Trixie para R36S
  - https://github.com/ohjhas/armbian-r36s
  - release `trixie-r1`
- O repositório de `ohjhas` é um fork do trabalho de **EatPrilosec/R36S-Armbian**.
  - https://github.com/EatPrilosec/R36S-Armbian
- A base usa o projeto **Armbian**.
  - https://github.com/armbian/build
- A cadeia de suporte do R36S também utiliza trabalhos da comunidade **R36S-Stuff**, inclusive suporte de boot/painéis herdado pelos projetos de origem.
  - https://github.com/R36S-Stuff

O BMO não reivindica autoria sobre a imagem Linux base, kernel, U-Boot, Debian, Armbian ou componentes derivados desses projetos.

## PPSSPP

PPSSPP foi criado por Henrik Rydgård e possui contribuições de muitos desenvolvedores.

- Projeto oficial: https://github.com/hrydgard/ppsspp
- Site: https://www.ppsspp.org/
- Versão atualmente validada pelo BMO: `1.20.4`

O BMO apenas integra o PPSSPP como emulador externo.

## Moonlight Qt

- Projeto oficial: https://github.com/moonlight-stream/moonlight-qt
- Versão atualmente validada pelo BMO: `6.2.0-1`
- Pacotes Debian oficiais hospedados no Cloudsmith pelo projeto Moonlight.

O BMO apenas integra o Moonlight Qt como cliente externo de streaming.

## RetroArch e cores

O BMO utiliza RetroArch e cores instalados através dos repositórios do sistema quando disponíveis, incluindo mGBA e Snes9x.

Cada projeto mantém sua própria autoria e licença.

## Política para futura publicação

A intenção é que uma futura versão pública do repositório BMO:

1. distribua apenas código e configuração próprios do BMO;
2. não reempacote a imagem-base quando puder apontar para a origem oficial;
3. não versione binários de PPSSPP/Moonlight quando puder obtê-los diretamente dos projetos oficiais;
4. mantenha links, versões e hashes verificáveis em `install/manifests/upstream-sources.env`;
5. preserve créditos e avisos exigidos pelos projetos de terceiros.

Este arquivo registra proveniência e reconhecimento dos projetos utilizados. Ele não substitui os termos das licenças originais de cada componente.
