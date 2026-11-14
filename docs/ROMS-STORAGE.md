# BMO — estrutura de ROMs e modos de armazenamento

O BMO suporta **dois modos de armazenamento de ROMs** no R36S.

A regra é:

1. se houver um segundo cartão (TF2/SD2) montado, o BMO procura ROMs nele primeiro;
2. o armazenamento local do TF1 continua disponível como fallback;
3. os dois podem coexistir;
4. se o mesmo arquivo relativo existir nos dois locais, a cópia do SD2 tem prioridade.

---

## 1. Modo local — TF1

As ROMs podem ficar no mesmo cartão onde está o sistema.

Estrutura:

```text
/home/r36s/ROMs/
├── gba/
│   └── jogos .gba ou .zip
├── snes/
│   └── jogos .sfc ou .smc
└── psp/
    └── jogos .iso, .cso ou .pbp
```

Caminhos usados pelo BMO:

```text
GBA   /home/r36s/ROMs/gba
SNES  /home/r36s/ROMs/snes
PSP   /home/r36s/ROMs/psp
```

Esse modo é o mais simples quando o usuário deseja trabalhar com apenas um microSD.

---

## 2. Modo SD2 — segundo cartão / TF2

Quando um segundo cartão estiver presente, o BMO usa o mount point:

```text
/mnt/bmo-sd2
```

Dentro do cartão, a estrutura esperada é:

```text
EASYROMS/
├── gba/
│   └── jogos .gba ou .zip
├── sfc/
│   └── jogos .sfc ou .smc
├── psp/
│   └── jogos .iso, .cso ou .pbp
├── saves/
└── states/
```

Depois de montado, o Linux enxerga esses diretórios como:

```text
GBA   /mnt/bmo-sd2/EASYROMS/gba
SNES  /mnt/bmo-sd2/EASYROMS/sfc
PSP   /mnt/bmo-sd2/EASYROMS/psp
```

Importante: no SD2 o diretório do Super Nintendo é chamado `sfc`, enquanto no armazenamento local do TF1 ele é chamado `snes`.

---

## 3. Ordem de prioridade

O BMO não precisa escolher permanentemente entre TF1 e TF2.

Ele procura os dois, nesta ordem:

```text
GBA
1. /mnt/bmo-sd2/EASYROMS/gba
2. /home/r36s/ROMs/gba

SNES
1. /mnt/bmo-sd2/EASYROMS/sfc
2. /home/r36s/ROMs/snes

PSP
1. /mnt/bmo-sd2/EASYROMS/psp
2. /home/r36s/ROMs/psp
```

Se o SD2 não estiver montado, os caminhos dele são ignorados automaticamente.

O TF1 continua funcionando normalmente.

Se TF1 e TF2 estiverem presentes ao mesmo tempo, jogos únicos de ambos podem aparecer na biblioteca.

Se existir o mesmo caminho/nome de arquivo nos dois, a versão do SD2 vence por ter prioridade maior.

---

## 4. Extensões aceitas atualmente

### Game Boy Advance

```text
.gba
.zip
```

### Super Nintendo

```text
.sfc
.smc
```

### PSP

```text
.iso
.cso
.pbp
```

O SNES aceita busca recursiva em subdiretórios.

GBA e PSP atualmente usam a estrutura direta do diretório do sistema.

---

## 5. Saves e save states

Quando não existe SD2, os saves permanecem localmente.

RetroArch:

```text
/home/r36s/.config/retroarch/saves
/home/r36s/.config/retroarch/states
```

PPSSPP:

```text
/home/r36s/.config/ppsspp/PSP/SAVEDATA
/home/r36s/.config/ppsspp/PSP/PPSSPP_STATE
```

Quando o SD2 está presente, o BMO também utiliza:

```text
EASYROMS/saves/
EASYROMS/states/
```

Para PSP, os dados do PPSSPP continuam sendo utilizados localmente durante a execução e são sincronizados com o SD2 quando ele está disponível.

A lógica de sincronização atual copia arquivos ausentes ou mais novos e não apaga automaticamente os arquivos do destino.

---

## 6. Objetivo para a BMO Linux Base

A nova imagem deve preservar os dois modos:

```text
1 CARTÃO
TF1
├── sistema
└── /home/r36s/ROMs
```

ou:

```text
2 CARTÕES
TF1
└── sistema BMO

TF2
└── EASYROMS
    ├── gba
    ├── sfc
    ├── psp
    ├── saves
    └── states
```

O uso de TF2 deve continuar opcional.

A ausência do segundo cartão nunca deve impedir o BMO de iniciar ou jogar ROMs locais.

---

## 7. Regras para distribuição pública

A imagem e o repositório BMO não devem conter ROMs comerciais.

O projeto pode criar apenas a estrutura vazia de diretórios e a documentação necessária para o usuário adicionar os próprios arquivos.

ROMs, saves e estados são dados locais do usuário e não devem ser versionados no Git.
