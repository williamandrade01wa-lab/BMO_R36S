BMO LIGHT 0.1.0 - CANDIDATA

1. Grave em SD extra de 8 GB ou maior e abra a BOOT no Windows.
2. Abra ABRIR-BMO.cmd, escolha ScreenFiles e configure Wi-Fi/senha/SSH.
3. TF2 de jogos fora durante todo o primeiro boot.
4. Ligue com rede e energia estaveis. O SD expande antes da instalacao.
5. O instalador baixa dependencias, mostra sete etapas e abre o BMO.
6. Sem internet ele avisa e tenta novamente; status em BMO-INSTALACAO.txt.
7. Depois desligue completamente antes de recolocar TF2.

Nao precisa chave/token Git nem senha FTP. O runtime pequeno do PPSSPP
acompanha a imagem; os pacotes grandes sao baixados na primeira instalacao.
BMO install permite iniciar uma tentativa manual com sudo bmo install.
Logs: journalctl -u bmo-light-install e /var/log/bmo-light-install.log.

A imagem core da CI nao e o entregavel final: precisa receber o runtime
pinado em BOOT/BMO-RUN/PPSSPP.TGZ e ter hash/contrato verificados no PC.
Validacao fisica desta nova candidata continua pendente.
