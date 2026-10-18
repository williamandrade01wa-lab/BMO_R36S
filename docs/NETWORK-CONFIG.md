# BMO Linux Base — rede e primeiro boot

A partir da v0.2, `BMO-FIRSTBOOT.txt` na partição **BOOT** configura o aparelho sem executar Shell.

## Opções

- `NETWORK_ENABLED=yes|no`
- Wi-Fi e Ethernet/USB independentes
- DHCP ou IPv4 estático para cada interface
- Wi-Fi WPA-PSK ou aberto
- SSID oculto e autoconnect
- SSH opcional
- mDNS opcional (`bmo-r36s.local` quando a rede suportar)

### Wi-Fi DHCP
```text
WIFI_ENABLED=yes
WIFI_SSID=MinhaRede
WIFI_SECURITY=wpa-psk
WIFI_PASSWORD=MinhaSenha
WIFI_HIDDEN=no
WIFI_AUTOCONNECT=yes
WIFI_IPV4_MODE=dhcp
```

### Wi-Fi estático
```text
WIFI_IPV4_MODE=static
WIFI_STATIC_ADDRESS=192.168.1.50/24
WIFI_STATIC_GATEWAY=192.168.1.1
WIFI_STATIC_DNS=1.1.1.1,8.8.8.8
```

### Ethernet/USB DHCP
```text
WIRED_ENABLED=yes
WIRED_AUTOCONNECT=yes
WIRED_IPV4_MODE=dhcp
```

### Ethernet/USB estático
```text
WIRED_IPV4_MODE=static
WIRED_STATIC_ADDRESS=192.168.1.60/24
WIRED_STATIC_GATEWAY=192.168.1.1
WIRED_STATIC_DNS=1.1.1.1,8.8.8.8
```

## SSH
Vem desligado. Para senha, troque `USER_PASSWORD` por algo diferente de `r36s`, defina `SSH_ENABLED=yes` e mantenha `SSH_PASSWORD_AUTH=yes`. Root por SSH permanece bloqueado e as chaves de host são geradas no aparelho no primeiro boot.

## Segurança
Depois de aplicar, `USER_PASSWORD`, `ROOT_PASSWORD` e `WIFI_PASSWORD` viram `__APPLIED__` na BOOT. Logs/status não devem conter segredos.

Arquivos gerados: `BMO-IP.txt`, `BMO-STATUS.txt`, `logs/firstboot.log`.

## Comandos
```bash
bmo status
bmo ip
bmo network status
bmo network scan
bmo network config
sudo bmo network apply
sudo bmo firstboot apply
bmo doctor
bmo source show
sudo bmo install
```

A fonte padrão é HTTPS GitHub e a imagem não contém chave/token. Enquanto o repo estiver privado, a autenticação SSH é configurada manualmente e a origem pode ser alterada com `sudo bmo source set ...`.
