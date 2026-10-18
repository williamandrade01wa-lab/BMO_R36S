# BMO Roadmap

## Imagem BMO minimalista (console-only)

Objetivo futuro: gerar uma imagem própria/minimalista para o R36S usando a base Linux necessária, removendo o desktop XFCE e aplicativos gráficos que não fazem parte da experiência BMO.

Meta:

```text
boot
  ↓
Linux mínimo
  ↓
console / serviços essenciais
  ↓
BMO kiosk
```

Motivações:

- reduzir espaço ocupado;
- reduzir tempo de boot;
- reduzir consumo de RAM;
- reduzir serviços e aplicativos desnecessários;
- diminuir pontos de falha;
- entregar experiência dedicada ao BMO.

Antes de remover o desktop da imagem-base atual, preservar e validar:

- boot/U-Boot;
- ScreenFiles / suporte aos painéis;
- kernel e DTB do R36S;
- controles físicos;
- áudio;
- brilho;
- USB OTG / HUB;
- Wi-Fi USB;
- SSH;
- DRM/KMS/X necessário ao kiosk;
- Moonlight;
- RetroArch;
- PPSSPP.

Não iniciar essa redução antes de concluir o teste reproduzível Pure → BMO.
