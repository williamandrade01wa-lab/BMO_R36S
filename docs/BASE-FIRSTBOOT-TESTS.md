# BMO Linux Base v0.2 — validação do primeiro boot

Imagem em teste: Run #8, commit `701ed1d7a2946a143cbbd90527f141e0b05c3867`.
`R36S_REQUIRED=YES`. Este roteiro valida a Base; emuladores, Moonlight e kiosk completo pertencem à etapa Ready.

## Preparação

- Usar o microSD extra de sistema em TF1 e preservar o cartão original.
- **Retirar o TF2 de jogos antes do primeiro boot e mantê-lo fora até a configuração inicial terminar.**
- Depois, desligar completamente antes de inserir o TF2. Não formatar o cartão de jogos.
- SSH vem desligado; os comandos abaixo podem ser executados no terminal local com teclado.
- Não compartilhar senhas, chaves privadas ou o BMO-FIRSTBOOT.txt completo.

## 1. Estado básico — somente leitura

```bash
bmo version
bmo status
bmo firstboot status
bmo doctor
systemctl --failed --no-pager
```

Esperado: Base 0.2.0, FIRSTBOOT=OK, sem serviços essenciais falhando. O doctor apenas verifica presença de componentes/diretórios; não substitui testes de funcionamento físico. SSH inativo é esperado quando não habilitado.

## 2. Armazenamento e rede — somente leitura

```bash
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS
findmnt /
findmnt /boot/u-boot
df -h / /boot/u-boot
bmo network status
bmo ip
ip route
```

Confirmar: root ext4 em leitura/escrita, FAT da BOOT montada, expansão/espaço coerentes e interface de rede com IP/rota quando conectada. Se não houver rede configurada/conectada, não classificar automaticamente como defeito de hardware.

## 3. Hardware — inventário e teste físico

```bash
cat /proc/bus/input/devices
aplay -l
ls /sys/class/backlight
lsusb
```

- Tela: imagem legível, painel/orientação corretos e ausência de apagamentos.
- Gamepad: validar eventos de todos os botões/analógicos com ferramenta de eventos disponível, sem instalar ou remapear por tentativa.
- Áudio: inventário ALSA é apenas detecção; saída audível deve ser testada a volume confortável.
- Brilho: confirmar backlight e controle físico disponível; ausência das hotkeys do App não prova defeito na Base.
- USB/Wi-Fi: confirmar detecção, obtenção de IP e reconexão.

Registrar saídas e observações antes de realizar correções.

## 4. Reboot e TF2

Após registrar os testes anteriores, executar desligamento/reboot controlado pelo usuário. Confirmar retorno ao sistema, usuário/senha preservados, FIRSTBOOT=OK e autoconnect, sem reaplicar configurações manualmente.

Com o aparelho totalmente desligado, inserir o TF2 e ligar. Listar discos para confirmar detecção. Não executar fsck corretivo, formatação, reparticionamento ou instalação no TF2.

Se houver diferença entre iniciar com TF2 e sem TF2, registrar lsblk/labels/UUIDs/logs antes de inferir a causa.

## Critério de avanço

CP-BOOT-001 só passa com evidência de boot, configuração inicial, usuário, status/IP e reboot idempotente. CP-HW-001 exige testes físicos específicos. Não executar `bmo install` antes de confirmar o instalador e a branch adequada à etapa Ready.
