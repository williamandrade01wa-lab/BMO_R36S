# Worklog — BMO App

O histórico de construção da imagem anterior a esta separação permanece na branch feat/bmo-linux-base-v1. Este log registra a base do App destinada à main.

## 2026-10-25 — Semi-beta do App, update visual e nova imagem de boot

- Branch/base: beta/app-v0.1.0, main inicial 613fb076e3d4fb4274df5afdc457503266cc2a69; snapshot do App na feature e71d87a8ab9e37554487a85d5fc3002ba07d4da5.
- Objetivo autorizado pelo usuário: congelar base funcional para main, fazer atualizações sutis pelo Git e iniciar evolução visual preservando funções. Pedido adicional: atualizar boot com arte R36S fornecida pelo usuário.
- Escopo: aplicativo/frontend e launchers existentes, 12 WAV originais (2183032 bytes), política Chromium, logo BMP e documentação. Não importar os 109 commits experimentais de imagem/Light nem executar instalador no aparelho.
- Update PC: novo scripts/update-visual.py, wrapper CMD e instruções. Git fetch lê commit sem sobrescrever trabalho local; autenticação GitHub privada fica no PC. Envio pelo helper existente confere SHA/backup, ativa candidate, exige hash testado para promover e tenta rollback se verificação falhar. Corrigida expansão de BMO_DEPLOY_CONFIG no common.sh legado.
- Validação local: 13 testes unitários aprovados (contrato HTML, branch/destino inválidos, upload divergente, candidate ativo, promoção com SHA divergente, recuperação de falha). Falhas iniciais de temp no sandbox resolvidas usando temp dentro do workspace no executor de testes, sem contornar permissões.
- Teste físico: SHA frontend 946f7596ee4f82781a092ff9af598da877a685279c790e691a859a973cda348f coincide com fonte e produção. Update candidate no R36S .65; usuário confirmou botões/carinha/som funcionando. Backup 20261025-225237. Promoção gerou backup 20261025-225428. Retorno ao primeiro backup completou com index.html e SHA original, HTTP/serviços OK. Busca Git privada no PC de usuário exige autenticação; envio físico usou bytes preservados do Git e as mesmas funções candidate/promote/recover.
- Boot: JPG do usuário convertido sem redesenho para BMP 640x480, RGB24, sem compressão, 921654 bytes. SHA 4b6e0533c080b3e374529887927123e0b56aa70e879f8ba774418ef6fcfaa661. Usuário executou helper com sudo local, backup e troca via arquivo temporário; leitura no aparelho confere SHA. Exibição no boot ainda não confirmada visualmente.
- Arquivos: VERSION, assets/sounds, assets/boot, frontend, launchers, scripts/update-visual.py, validate-app.py, tests/test_update_visual.py, workflow CI e docs de App/update/checkpoint. Sem credenciais/ROMs/saves.
- Resultado esperado: base beta privada do App em main e evolução visual por branches/PR, sem regravar cartão para HTML/CSS/JS. CI do commit final e PR são gates antes da integração.
- R36S_REQUIRED=YES para novo visual e regressões de jogos/streaming; fluxo básico testado no aparelho com HTML idêntico.
- Próximo passo exato: CI, PR para main, integrar se checks passarem; depois branch de visual conforme direção do usuário. Manter imagem experimental separada e incorporar nova logo na próxima montagem dessa imagem.
