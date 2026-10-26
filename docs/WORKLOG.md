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


### Fechamento da beta em main

PR #5 integrado por autorização do usuário após candidate e confirmação física, validação de promoção/retorno e CI verde. Merge main c8e218953ce3d710d47042db16448fc664ad3997. CI PR 40257425587 e main 40257577056 concluíram com sucesso, incluindo fetch do Git autenticado. Diff preservou a imagem experimental na branch própria. A nova arte e cópia/checksum nos finalizadores Base/Light/Ready foram versionadas em feat/bmo-linux-base-v1 ad0bca4b8de36edbd5d5b98df7ac3fa3248a35b1; os três scripts passaram bash -n, sem novo build de imagem nesta etapa. Exibição da arte no próximo boot ainda pendente. Próximo passo: alteração visual em branch a partir de main, com novo teste físico. R36S_REQUIRED=YES para novo visual e boot renderizado.


## 2026-10-26 — PureLight concluída e preparada para handoff

- Branch de imagem/core: feat/bmo-linux-base-v1, fonte af93facc944df8d019ff6189c1ccc007373dc749. CI40259216780 aprovada; artifact core12624200746 baixado e verificado por SHA/CRC. Finalizador PC versionado em 7533e2dfb718cc12435567da8108ee036531d57f.
- Resultado: outputs/BMO-R36S-PureLight-v0.1.0-beta.img.xz, 425364488 bytes. SHA256 419adb83a60970834387bdad590a319b260ee7b85d57c9798b4c2ed43a623b90. Raw 2386558976 bytes, SHA 707845c2c55562ad959c82ea21bf8a48bbcd7d9ee3f3f5dd30c88abaa75581d1.
- Validação: BMO_LIGHT_FINAL_IMAGE_OK, 96 arquivos de payload, 12 sons, assistente v0.2.1, política e logo conferidos, runtime pinado lido de volta, root preservada e descompressão total validada. Hash XZ recalculado independentemente antes do handoff. Root usada 1404530688 bytes; uso após dependências ainda não medido.
- Arquivos: imagem/checksum/manifesto/LEIA-ME no PC; manifesto e checksum pequenos em docs/releases no Git. Sem novo uso pesado da Potato, sem Release/tag publicado.
- Resultado esperado/obtido: candidata entregue para teste privado, sem declarar teste físico concluído. R36S_REQUIRED=YES. Próximo passo exato: teste do usuário em cartão extra, TF2 fora, expansão/rede/progresso/abertura BMO e regressão do hardware/jogos; só depois discutir publicação.

## 2026-10-26 — Regra permanente de memória e inicialização do Codex

- Pedido explícito: especificações/parâmetros e ponto atual no Git, registro obrigatório das etapas para trocar de agente/conversa e trabalhar em várias partes do projeto; criar inicializador Codex.
- Ação: AGENTS reforçado nas branches main e de imagem; USER-REQUIREMENTS, ENVIRONMENT, HANDOFF e continuidade consolidada; estado da PureLight/manifestos/checkpoint registrados. Regras valem até alteração explícita do usuário; não dependem de memória do chat.
- Script: INICIAR-CODEX.cmd + scripts/windows/INICIAR-CODEX.ps1 geram contexto e prompt a partir de documentos permitidos, observam Git local e copiam prompt. Área geral/visual/imagem/infra; refresh opcional por fetch; CLI opcional em worktree. Não fazem pull/reset, captura global de conversas, configuração global ou leitura de credenciais.
- Validação: selftest Windows PowerShell passou: documentos obrigatórios, ausência de vazamento de arquivo .env sentinela, geração de contexto/prompt, áreas, falha em documento ausente e detecção real de branch/HEAD em fixture Git. CLI local --help confirmou -C/--worktree; abertura interativa não executada pelo agente. Documentação oficial confirma AGENTS como instrução de projeto.
- Próximo passo: CI do inicializador, integrar à main e sincronizar metadados na branch de imagem; entregar prompt/pacote de inicialização e candidata PureLight. R36S_REQUIRED=NO para o inicializador, YES para a imagem. Novo agente deve verificar Git/arquivos locais e aguardar teste físico, sem repetir build já concluído por falta de contexto.
