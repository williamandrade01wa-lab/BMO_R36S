BMO LINUX BASE v0.2 - PRIMEIRO BOOT
===================================
1. Grave a imagem no microSD.
2. Abra a particao BOOT no Windows.
3. COPIE os arquivos de ScreenFiles/Panel X para a raiz da BOOT. NAO mova.
4. Edite BMO-FIRSTBOOT.txt.
5. Com o R36S desligado, retire o cartao TF2 de jogos.
6. Coloque somente o cartao do sistema na entrada TF1 e ligue.
7. Mantenha o TF2 FORA durante todo o primeiro boot/configuracao inicial.
8. Quando a configuracao terminar, desligue completamente, insira o TF2 e ligue novamente.
Nao formate nem altere o TF2 para realizar esse procedimento.

REDE: Wi-Fi e Ethernet/USB aceitam DHCP ou IPv4 estatico. Wi-Fi suporta WPA-PSK, rede aberta, SSID oculto e autoconnect. SSH vem desligado.
SEGURANCA: BMO-FIRSTBOOT.txt nao e Shell. Depois de aplicado, senhas viram __APPLIED__.
STATUS: BMO-IP.txt, BMO-STATUS.txt e logs/firstboot.log sao gravados na BOOT.

Comandos: bmo status | bmo ip | bmo network status | bmo network scan | bmo network config | sudo bmo network apply | bmo doctor | bmo source show | sudo bmo install
