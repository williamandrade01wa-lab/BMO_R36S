BMO READY 1.0.0-beta.1
====================
Esta imagem ja inclui BMO, Chromium/Xorg, RetroArch + cores GBA/SNES,
PPSSPP, Moonlight, audio e suas dependencias. Nao execute bmo install.

PREPARAR
1. Grave em um cartao extra de 16 GB ou maior. Preserve seu cartao atual.
2. Abra a BOOT no Windows e execute ABRIR-BMO.cmd.
3. Escolha o painel ScreenFiles conhecido e configure rede/senha/SSH.
4. Retire TF2 de jogos. Primeiro boot somente com o cartao do sistema TF1.
5. Ligue. A configuracao ocorre automaticamente, mostra resumo/IP/SSH
   e abre o BMO. Pode reiniciar uma vez para expandir o cartao.
6. Depois, desligue completamente antes de recolocar TF2.

JOGOS
Nenhuma ROM ou save esta incluida.
Use pastas gba, snes e psp em /home/r36s/ROMs.
TF2 em exFAT/FAT com pasta EASYROMS e detectado no boot seguinte;
o cartao do sistema nunca e escolhido como TF2. Cartoes sem EASYROMS
nao sao alterados. Nao conecte TF2 durante o primeiro boot.
O pareamento Moonlight/Sunshine e configurado depois no seu PC.

BETA
Usuario desta receita: r36s. Escolha a senha pelo assistente.
SSH permanece desligado a menos que voce habilite.
O primeiro candidato ainda precisa de teste fisico de tela, gamepad,
audio, brilho, jogos, streaming e retorno ao BMO.
As funcionalidades da Base e do BMO sao preservadas; CI/offline
nao substituem esses testes no aparelho.

RECUPERACAO
Use Ctrl+Alt+F2 com teclado para acessar outro terminal.
A BOOT contem BMO-RESUMO.txt, BMO-STATUS.txt e logs apos configurar.
Seu cartao anterior continua sendo o retorno seguro.
