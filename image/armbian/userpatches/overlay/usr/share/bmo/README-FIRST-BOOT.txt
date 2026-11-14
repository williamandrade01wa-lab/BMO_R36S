BMO - PRIMEIRO BOOT
==================
1. Grave a imagem no cartao do sistema (TF1).
2. Abra a BOOT no Windows.
3. COPIE os arquivos do seu ScreenFiles/Panel X para a raiz da BOOT.
   Nao mova os originais.
4. Abra BMO-FIRSTBOOT.txt no Bloco de Notas:
   REDE_WIFI = nome do seu Wi-Fi (deixe vazio se usar cabo)
   SENHA_WIFI = senha do Wi-Fi
   SENHA_USUARIO = senha que voce escolhe para o R36S
   ACESSO_REMOTO = sim para SSH, ou nao para manter desligado
   Edite depois do sinal =, sem aspas.
   Para ligar o SSH, escolha uma senha diferente de r36s.
5. Salve e remova o cartao com seguranca.
6. Com o R36S desligado, retire o TF2 de jogos.
7. Ligue somente com TF1 e aguarde a configuracao.
   A tela mostrara se conectou, o IP e se o SSH esta ligado.
   Pode ocorrer uma reinicializacao para preparar o cartao.
   O resumo reaparece ao entrar no terminal.
8. Depois de concluir, desligue completamente antes de inserir TF2.
   Nao formate nem altere o cartao de jogos.

SE NAO CONECTAR
Confira o nome/senha do Wi-Fi e o cabo/adaptador.
O sistema informa SEM CONEXAO / SEM IP; isso nao impede uso local.
No computador, consulte BMO-RESUMO.txt na BOOT apos desligar o R36S.

SENHAS
Este arquivo de configuracao nao executa comandos.
Apos aplicar, senhas sao substituidas por __APPLIED__.
Nao envie suas senhas a ninguem.

STATUS
BMO-RESUMO.txt = resumo simples, com IP e SSH
BMO-IP.txt / BMO-STATUS.txt / logs/firstboot.log = diagnostico
Rede conectada com IP nao significa que a internet foi testada.

OPCOES AVANCADAS
Os nomes antigos (WIFI_SSID, USER_PASSWORD, SSH_ENABLED etc.)
continuam aceitos; nao repita a mesma opcao com dois nomes.
IP automatico (DHCP) e o padrao.
