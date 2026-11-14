# BMO Ready Wi-Fi 5: candidata privada

Esta pasta contém os arquivos versionáveis para testar o Wi-Fi interno RTL8811CU (`0bda:c811`) e SSH na Ready v1.0.0-beta.1. A imagem candidata, módulos compilados, logs e credenciais ficam fora do Git.

## Base reproduzível

- Ready v1.0.0-beta.1 gzip SHA256: `e21a446dccfde7e115a8e0cf79ae251d41aca02f3edfb4c274e4bc405b1794a7`.
- Raw SHA256: `b7a9ab2567084f42da2c6a7628fbacd68c683ff120f64dca54fc252f15e35f7e`.
- Kernel instalado: `6.12.32-lts-rk3326` ARM64; `CONFIG_MODVERSIONS=y`.
- Fonte do kernel: `https://github.com/EatPrilosec/linux-stable-rk3326.git`, commit `d5da60f7ee9fcafed61f1e93590eb85ca0ecd7c0`.
- Configuração de build: `/boot/config-6.12.32-lts-rk3326` extraída da Ready, com `CONFIG_RTW88_8821CU=m` e dependências calculadas por `olddefconfig`.
- Toolchain: `aarch64-linux-gnu-gcc-13`, `ARCH=arm64`, `CROSS_COMPILE=aarch64-linux-gnu-`, `LOCALVERSION=-lts-rk3326`.
- Gerar `Image modules`, conferir `kernelrelease` idêntico e guardar `Module.symvers`. A candidata só precisa receber `rtw88_usb.ko`, `rtw88_8821c.ko` e `rtw88_8821cu.ko` se os CRCs dos símbolos coincidirem com os módulos existentes. Caso contrário, substituir kernel e módulos de modo consistente em nova candidata.

## Integração e teste

Instalar os três `.ko` em `/lib/modules/6.12.32-lts-rk3326/kernel/drivers/net/wireless/realtek/rtw88/` da **cópia** da imagem e executar `depmod -b ROOT 6.12.32-lts-rk3326`. Conferir `vermagic`, alias `usb:v0BDApC811`, firmware `rtw8821c_fw.bin` e resolução de dependências. Instalar `bmo-wifi5-report.sh` como `/usr/local/sbin/bmo-wifi5-report`, instalar o serviço em `/etc/systemd/system/` e habilitá-lo no `multi-user.target`.

`assemble-ready-wifi5.sh WORK_DIR` implementa essa montagem. `WORK_DIR` deve conter `Ready-base.img` (cópia raw verificada da Ready) e `modules/rtw88_usb.ko`, `modules/rtw88_8821c.ko`, `modules/rtw88_8821cu.ko`. Execute como root em Linux/WSL com suporte a loop mounts. O script modifica somente essa cópia e gera `modprobe-dry-run.txt` em `WORK_DIR`; os arquivos do serviço vêm desta pasta versionada.

O relatório é gravado na BOOT após o firstboot, sem SSID ou senha. O teste físico requer cartão extra de pelo menos 16 GB e confirmação de interface Wi-Fi, conexão em frequência 5xxx MHz, IP e `ssh` ativo. Preservar o cartão atual e a imagem Ready original. Não declarar a candidata validada sem boot real.

Na montagem de 2026-11-14, os três `.ko` passaram em `vermagic` e alias USB. Os 68 CRCs exportados pelo `rtw88_core` original e compilado coincidiram, e as importações verificadas contra `rtw88_core`, `mac80211` e `cfg80211` não divergiram. `modprobe -n` resolveu a cadeia de dependências. A cópia da imagem passou em `fsck.vfat -n` e `e2fsck -fn`. Isso valida a preparação no PC; o boot e a associação em 5 GHz ainda precisam do R36S.

Imagem gzip montada em 2026-11-14: SHA256 `e0888fb7f28d3cd56f29612aa4506a7ad2bb40688cb7e692db351377fa819429`, 1.891.182.973 bytes. Raw SHA256 `896c2d2a8c0ff4a5f2cd6ca0597b7a2c909cc4fb017e8c48f8b063d508f95ec4`, confirmado por descompressão do gzip. Arquivo binário mantido fora do Git.

Plano e evidências: [`docs/RTL8811CU-READY-WIFI5-PLAN.md`](../../../docs/RTL8811CU-READY-WIFI5-PLAN.md).
