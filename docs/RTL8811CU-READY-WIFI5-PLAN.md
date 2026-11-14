# BMO R36S — plano de correção do Wi-Fi interno RTL8811CU

## Rumo vigente: Ready v1.0.0-beta.2-WiFi5

**Estado em 14/11/2026:** candidata `BMO-R36S-Ready-v1.0.0-beta.2-WiFi5.img.gz` pronta no PC, 1.891.182.973 bytes, SHA256 `e0888fb7f28d3cd56f29612aa4506a7ad2bb40688cb7e692db351377fa819429`. O gzip passou em `pigz -t` e descompactou exatamente para raw SHA256 `896c2d2a8c0ff4a5f2cd6ca0597b7a2c909cc4fb017e8c48f8b063d508f95ec4`. FAT32/ext4 verificados somente leitura; BMO, driver e serviço presentes. Falta teste físico de boot, 5 GHz e SSH. Próxima ação: gravar em outro microSD de 16 GB ou maior, preservar F:, configurar a BOOT e iniciar o R36S. Depois ler `BMO-WIFI5-STATUS.txt`.

O usuário escolheu uma nova imagem beta com BMO completo já instalado. A sequência vigente é: concluir o build com GCC 13, comparar `vermagic` e CRCs com os módulos da Ready original, integrar os três módulos na cópia raw, executar `depmod` e validar dependências, instalar o relatório de boot, comprimir a candidata e conferir hashes. Só depois gravar **outro** microSD de 16 GB ou maior e testar boot, associação em 5xxx MHz, IP e SSH no R36S. O plano antigo de instalar módulos no F: por hook de BOOT, abaixo, permanece apenas como histórico diagnóstico e não será executado nesta candidata.

Data do registro: 13/11/2026 (America/Sao_Paulo). Estado: diagnóstico físico/USB confirmado; correção de software pendente. Este documento é um ponto de retomada, não um relato de correção concluída.

Atualização 13/11/2026: a segunda coleta `BMO-WIFI-SSH-INVENTORY.txt` confirmou no kernel `6.12.32-lts-rk3326` que `CONFIG_RTW88_8821CU` está desativado. Faltam os módulos `rtw88_usb`, `rtw88_8821c` e `rtw88_8821cu`; `rtw88_core`, `mac80211` e `cfg80211` já existem. `CONFIG_MODVERSIONS=y` no perfil upstream fixado, então os símbolos/headers do build exato precisam ser preservados. `sshd -t` passou; o serviço foi visto inativo numa coleta feita cedo no boot, o que ainda não determina sua condição após o início normal. O `boot.ini` foi restaurado após a coleta. Uma terceira tarefa de boot já está preparada para exportar os headers e verificar SSH mais tarde.

Atualização seguinte: o usuário pediu uma **nova beta completa com BMO já instalado**, e não uma PureLight que instale o aplicativo depois. Base selecionada: `BMO-R36S-Ready-v1.0.0-beta.1.img.gz`, com SHA256 `e21a446dccfde7e115a8e0cf79ae251d41aca02f3edfb4c274e4bc405b1794a7` verificado no PC. A imagem original e o cartão atual são preservados; a candidata será construída em cópia. Duas tentativas de exportar headers pelo boot produziram tela preta e nenhum relatório, por isso os hooks temporários foram removidos e `boot.ini` original restaurado. Próxima coleta de configuração/símbolos será feita diretamente da cópia da imagem Ready no PC. A tela preta no cartão atual precisa de validação separada e não deve ser atribuída automaticamente ao driver ausente.

Atualização de execução: a Ready raw de 12 GiB foi descompactada e seu SHA256 `b7a9ab2567084f42da2c6a7628fbacd68c683ff120f64dca54fc252f15e35f7e` conferido. O rootfs contém BMO completo, kernel `6.12.32-lts-rk3326`, firmware `rtw8821c_fw.bin` e serviço `bmo-ready-firstboot`; não contém headers nem `Module.symvers`. O build do kernel foi iniciado com a fonte fixada `d5da60f7ee9fcafed61f1e93590eb85ca0ecd7c0`, a configuração extraída da Ready, GCC ARM64 13 e `LOCALVERSION=-lts-rk3326`; o release calculado corresponde exatamente ao kernel da Ready. Saídas ainda pendentes. O cartão F: passou em verificação FAT32 somente leitura, hash repetido de quatro arquivos e comparação do `boot.ini` com backup; a saúde da partição ext4 e falhas intermitentes não estão comprovadas. Não formatar nem sobrescrever o cartão atual.

## Evidência obtida

- O módulo foi soldado nos pads dedicados da placa. O usuário confirmou ausência de curto aparente e funcionamento geral do R36S.
- Diagnóstico executado pelo cartão BOOT: `BMO-USB-DIAG.txt`. O relógio do R36S registrou `2026-11-01T00:08:18Z`; essa data não deve ser usada para datar a intervenção.
- Kernel em execução: `6.12.32-lts-rk3326`.
- USB detectou `0bda:c811`, descrito como `Realtek 802.11ac NIC`, no endereço `1-1`. Logo, o módulo recebe energia e responde à enumeração USB; isso não certifica toda a parte de rádio/antena.
- `modinfo rtw88_8821cu` retornou `Module ... not found`. O arquivo `/lib/firmware/rtw88/rtw8821c_fw.bin` existe.
- A tentativa limitada de correção não carregou nada porque o módulo não existe na imagem. A ausência de interface na coleta inicial ocorreu cedo no boot, antes de o NetworkManager responder; a conclusão principal é a falta do driver utilizável.
- O código do Linux 6.12 associa `0bda:c811` ao driver `rtw88_8821cu`.
- O `boot.ini` original foi restaurado após o diagnóstico. O relatório permanece na BOOT. Não repetir a alteração do boot sem motivo.

## Objetivo e aceite

Fazer o Wi-Fi interno aparecer como interface de rede no BMO e conectar a uma rede configurada, preservando boot, tela, gamepad, áudio e dados do cartão. Aceite exige: USB `0bda:c811` presente; driver vinculado ao dispositivo sem erro de firmware; interface Wi-Fi criada; conexão/IP confirmados; reinício com persistência; logs de erro relevantes ausentes. A porta OTG pode permanecer indisponível se compartilhar fisicamente o barramento com o Wi-Fi interno; avaliar separadamente, sem declarar dano por isso.

## Plano de ação

1. **Inventariar o kernel instalado, sem escrever no sistema.** Pela BOOT, executar uma segunda coleta de uso único para registrar `uname -r`, `modprobe -n -v rtw88_8821cu`, `find /lib/modules/$(uname -r) -iname '*rtw*'`, `modules.builtin`, `modules.dep`, `/boot/config-*` ou `/proc/config.gz` (quando disponíveis), e `lsusb -v` apenas para `0bda:c811`. Gravar relatório na BOOT sem SSID, senhas, MAC completo ou outros segredos. Conferir também se `rtw88_usb`, `rtw88_8821c`, `rtw88_core`, `mac80211` e `cfg80211` existem como módulos ou embutidos.
2. **Escolher o menor pacote compatível.** Se as dependências já estiverem disponíveis, compilar apenas os módulos faltantes a partir da fonte/commit e configuração exatos do kernel `6.12.32-lts-rk3326`. Se a pilha `rtw88` ou suas dependências tiverem sido excluídas da configuração, gerar uma imagem candidata com essas opções habilitadas. Não usar `.ko` de outro kernel, nem alterar o DTB/ScreenFiles para resolver um driver ausente.
3. **Validar antes de tocar no cartão.** Em CI/PC: conferir `vermagic`, arquitetura ARM64, dependências, presença do ID `0bda:c811`, firmware, tamanho e SHA256; testar que o pacote é instalável e que o script de BOOT recusa versão de kernel diferente. Preservar o cartão atual e criar backup dos arquivos que serão modificados.
4. **Aplicar uma correção controlada via BOOT.** Copiar somente o pacote verificado e um script de uso único para a partição FAT. Iniciar pelo `boot.ini` com o mecanismo já testado (`systemd.run`), com `success_action=none` e `failure_action=none`. O script deve confirmar o kernel e os hashes, instalar os módulos em `/lib/modules/6.12.32-lts-rk3326`, executar `depmod`, tentar `modprobe rtw88_8821cu` e salvar resultado na BOOT. Se qualquer pré-condição falhar, não instalar parcialmente; registrar erro legível. Não escrever senhas ou executar `BMO-FIRSTBOOT.txt` como shell.
5. **Validar no aparelho.** Confirmar detecção USB, associação do driver, criação de `wlan`, varredura e conexão na interface do BMO, IP e estabilidade após reinício. Diferenciar falha de driver, de firmware, de configuração de rede e de sinal/antena pelos logs. Não interpretar a indisponibilidade do OTG como falha nova sem verificar o desenho da placa.
6. **Fechar e documentar.** Restaurar o `boot.ini` original e remover o mecanismo de execução temporário após a validação. Registrar arquivos, commits, hashes, logs relevantes, resultado real e rollback em `docs/WORKLOG.md`; atualizar `docs/PROJECT-CONTINUITY.md` e checkpoints somente quando houver evidência. Manter a imagem candidata separada de qualquer release.

## Próximo passo exato

O build, a integração, `fsck`, gzip e hashes foram concluídos. Branch privada no GitHub: `fix/rtl8811cu-ready-wifi5-beta`, commit `8fd8b2c3f765c6747fccac9d60c0ed67e8134186`. Aguardar o usuário inserir um microSD **extra** de 16 GB ou maior no PC e informar sua letra, preservando F:. Gravar nele a candidata já verificada, abrir a BOOT para selecionar ScreenFiles e configurar rede 5 GHz e SSH com senha nova; depois colocá-lo no R36S. Após o primeiro boot e eventual reinício, devolver o cartão ao PC e ler `BMO-WIFI5-STATUS.txt`. O aceite físico exige interface Wi-Fi, conexão em frequência 5xxx MHz, IP, SSH ativo e boot estável. Não colocar credenciais no relatório.

`R36S_REQUIRED=YES` para a coleta/validação física; `R36S_REQUIRED=NO` para análise, compilação e validação prévia.

## Fonte de referência

- Linux 6.12 `rtw8821cu.c`: https://github.com/torvalds/linux/blob/v6.12/drivers/net/wireless/realtek/rtw88/rtw8821cu.c
- Repositório do projeto: `williamandrade01wa-lab/BMO_R36S`. A pasta local OneDrive é um snapshot sem `.git`; confirmar checkout/branch/HEAD antes de editar fonte ou publicar.
- Ao migrar chat: leia este plano, `AGENTS.md`, `docs/GOLDEN-RULES.md`, `docs/MAESTRO-TASKS.md`, `docs/PROJECT-CONTINUITY.md` e os registros recentes do `docs/WORKLOG.md`. O diagnóstico do cartão é evidência; o `.md` é o estado curado.
