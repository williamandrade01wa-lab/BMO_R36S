#!/usr/bin/env bash
# ==============================================================================
# BMO R36S — Instalador Automático de Linha Única
# Projeto Open Source inspirado no BMO para consoles R36S (Hardware Original).
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "      BMO R36S — Instalador Automático v1.0.0"
echo "  Projeto Open Source inspirado no BMO (Zero ROMs/ISOs)"
echo "=========================================================="

# 1. Checagem de privilégios
if [ "$(id -u)" -ne 0 ]; then
    echo "[!] Este script precisa ser executado como root ou via sudo."
    echo "    Use: sudo bash install_bmo.sh"
    exit 1
fi

# 2. Checagem de arquitetura
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "armv7l" ]; then
    echo "[!] Aviso: Arquitetura detectada: $ARCH. O R36S original utiliza RK3326 (aarch64)."
fi

# 3. Reconhecimento automático de Adaptadores Wi-Fi USB (RTL8811CU / RTL8188)
echo "[*] Verificando adaptadores Wi-Fi..."
if lsusb | grep -qi "0bda:c811\|0bda:1a2b\|Realtek"; then
    echo "[+] Adaptador Wi-Fi Realtek (RTL8811CU/RTL8188) detectado no barramento USB."
    # Garantir que o modo modem USB não fique preso (usb-modeswitch)
    if command -v usb_modeswitch >/dev/null 2>&1; then
        usb_modeswitch -K -v 0bda -p 1a2b >/dev/null 2>&1 || true
    fi
    modprobe 8821cu 2>/dev/null || modprobe 8812au 2>/dev/null || true
    echo "[+] Módulos de rede sem fio configurados."
else
    echo "[-] Nenhum adaptador Wi-Fi USB Realtek detectado no momento."
fi

# 4. Instalação e links do aplicativo BMO
BMO_DIR="/opt/bmo"
mkdir -p "$BMO_DIR"
echo "[*] Instalando arquivos do BMO em $BMO_DIR..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/frontend" ]; then
    cp -r "$SCRIPT_DIR/frontend" "$BMO_DIR/"
    cp -r "$SCRIPT_DIR/assets" "$BMO_DIR/"
    cp -r "$SCRIPT_DIR/scripts" "$BMO_DIR/"
    [ -d "$SCRIPT_DIR/backend" ] && cp -r "$SCRIPT_DIR/backend" "$BMO_DIR/"
    [ -d "$SCRIPT_DIR/launchers" ] && cp -r "$SCRIPT_DIR/launchers" "$BMO_DIR/"
fi

# 5. Configurar inicialização automática
echo "[*] Configurando serviços de inicialização..."
if [ -f "$SCRIPT_DIR/install/beta/bmo-ready-firstboot.service" ]; then
    cp "$SCRIPT_DIR/install/beta/bmo-ready-firstboot.service" /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable bmo-ready-firstboot.service 2>/dev/null || true
fi

echo "=========================================================="
echo " [+] Instalação concluída com sucesso!"
echo " [*] Ao reiniciar, o BMO iniciará automaticamente no display."
echo "=========================================================="
