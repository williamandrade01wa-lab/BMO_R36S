#!/usr/bin/env bash

# BMO generic first-boot provisioning
# Executado uma vez pelo Armbian apos o primeiro login bem-sucedido.

set -euo pipefail

HOSTNAME_BMO="${BMO_FIRSTBOOT_HOSTNAME:-bmo-r36s}"

hostnamectl set-hostname "$HOSTNAME_BMO"

# Habilita SSH se o servico ja existir na Pure.
if systemctl list-unit-files ssh.service >/dev/null 2>&1; then
    systemctl enable ssh.service >/dev/null 2>&1 || true
    systemctl start ssh.service >/dev/null 2>&1 || true
elif systemctl list-unit-files sshd.service >/dev/null 2>&1; then
    systemctl enable sshd.service >/dev/null 2>&1 || true
    systemctl start sshd.service >/dev/null 2>&1 || true
fi

# Nao instala pacotes, nao clona repositorios e nao contem credenciais.
# O BMO completo continua sendo instalado explicitamente pelo Git:
#   sudo ./install/install.sh

printf '%s\n' "BMO_FIRSTBOOT_PROVISIONING_OK"
