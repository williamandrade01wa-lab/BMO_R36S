# BMO Linux Base image

Esta pasta concentra os arquivos de build da futura imagem mínima do BMO para R36S.

A imagem deve ser preparada desde o início para distribuição pública e não pode depender de nenhuma chave, token ou credencial Git privada.

Arquitetura completa:

- [`docs/BMO-LINUX-BASE-DESIGN.md`](../docs/BMO-LINUX-BASE-DESIGN.md)

## Estrutura alvo

```text
image/
├── README.md
├── boot/
│   ├── BMO-FIRSTBOOT.example.txt
│   ├── README-FIRST-BOOT.txt        # a criar
│   └── README-SCREENFILES.txt       # a criar
│
└── armbian/
    └── userpatches/
        ├── config-bmo-r36s.conf     # a implementar
        ├── customize-image.sh       # a implementar
        ├── extensions/              # hooks de build quando necessários
        └── overlay/                 # arquivos copiados para a rootfs
```

## Regra de build

A meta é gerar uma imagem CLI mínima, sem XFCE:

```text
RELEASE=trixie
BUILD_MINIMAL=yes
BUILD_DESKTOP=no
```

Devemos reaproveitar os ajustes específicos do R36S que já provaram funcionar para boot, DTB, ScreenFiles, controles e periféricos.

## Git

A imagem final assume distribuição pública por HTTPS.

Durante o desenvolvimento privado, a autenticação SSH é configurada manualmente no aparelho de teste e nunca é incorporada à imagem.
