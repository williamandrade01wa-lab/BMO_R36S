# Ambiente e parâmetros operacionais

Última confirmação nesta sessão: 2026-10-25 (America/Sao_Paulo). IPs DHCP podem mudar; confirmar antes de SSH. Não há senhas/chaves privadas neste arquivo.

| Componente | Referência | Observação |
| --- | --- | --- |
| GitHub | williamandrade01wa-lab/BMO_R36S | Repositório privado; main App, feat/bmo-linux-base-v1 imagem |
| R36S Ready de teste | 192.168.1.65, usuário r36s, hostname bmo-r36s | Kernel 6.12.32-lts-rk3326; liga/desliga depende do usuário |
| Cartão original R36S | último IP 192.168.1.28, usuário r36s | Kernel 6.12.74; referência preservada, sons das carinhas confirmados |
| Le Potato | 192.168.1.50, root, hostname lepotato | IP fixo pelo adaptador USB Ethernet AX88179B; economizar disco |
| FTP do roteador | ftp://admin@192.168.1.1/usb1_1_1/ (porta21) | Autenticado; senha local e desconhecida pelo agente |

FTP: usuário testou 8 MiB com SHA/limpeza OK, upload3,14 MiB/s e download3,12 MiB/s. Capacidade livre e limite de arquivos >4GB não medidos. Não expor nem desabilitar autenticação.

## Último ambiente local (não é caminho universal)

PC Windows, PowerShell. Workspace da sessão anterior:
C:/Users/Willi/Documents/Codex/2026-10-23/cons

- outputs/: entregáveis; PureLight final, checksum, manifesto e instruções.
- work/ppsspp-runtime-pinned.tar.gz: runtime PPSSPP pinado usado na finalização (27790924 bytes; SHA no manifesto da imagem).
- work/pure-core-40259216780/: core baixado/validado do Actions.
- work/audio-comparison/: baselines do original e Ready; sons preservados também estão em assets/sounds no Git.
- Credencial SSH da sessão anterior ficava em work/ssh-potato/id_ed25519, FORA DO GIT. Não copiar ao repositório nem presumir que existe em outro ambiente. Host keys separados por cartão; imagem recém-gravada gera identidade nova.

Se o próximo agente estiver em outro PC/cloud, confirmar acesso aos entregáveis e credenciais locais. Arquivo ausente nesse ambiente não significa que nunca foi gerado. Não recompilar nem recriar credenciais sem antes consultar continuidade/manifestos/artifacts.

## Caminhos no R36S

Produção: /opt/bmo-ui/index.html
Candidate: /opt/bmo-ui/index.bmo-next.html
Backend: /usr/local/bin/bmo-control-api.py
Sons: /opt/bmo-sounds
Boot: /boot/u-boot/logo.bmp
Helper: /usr/local/sbin/bmo-deploy-helper
Backups frontend: /home/r36s/.bmo-deploy/backups
Logs Light: journalctl -u bmo-light-install e /var/log/bmo-light-install.log
Status Light: BOOT/BMO-INSTALACAO.txt; rede: BMO-RESUMO.txt e BMO-WIFI.txt.

No hardware testado, HP é o perfil que funcionou. Headphones Jack=on também ocorre no original sem fone. Não inverter GPIO/DTB nem forçar SPK apenas por esse indicador.
