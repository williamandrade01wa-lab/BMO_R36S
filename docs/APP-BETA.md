# App 0.1.0-beta.1

## Base congelada

Branch beta/app-v0.1.0 criada sobre main 613fb076e3d4fb4274df5afdc457503266cc2a69. Snapshot do App vindo de feat/bmo-linux-base-v1 em e71d87a8ab9e37554487a85d5fc3002ba07d4da5, sem importar os 109 commits de construção da imagem. Frontend físico conferido por SHA256: 946f7596ee4f82781a092ff9af598da877a685279c790e691a859a973cda348f.

## Confirmado no aparelho

- Primeiro boot e acesso SSH da Ready.
- Navegação do BMO por botões e efeitos das carinhas, inclusive após novo boot relatado pelo usuário.
- 12 sons recuperados, SHA256 conferidos.
- Tradução Chromium desativada por política.
- Envio de candidate visual, confirmação física do usuário, promoção e retorno ao backup com frontend idêntico.
- Nova logo R36S instalada, leitura SHA conferida; exibição da arte no próximo boot ainda depende de confirmação visual.

## Limites

Beta privada de desenvolvimento do App. Não declara publicação estável, instalação Light validada do zero nem regressão completa de todos os jogos/streaming. A imagem Light segue em outra branch e precisa receber as correções no próximo build. Recursos binários, scripts e instruções desta branch não contêm credenciais/ROMs/saves.

## Correções para próximas imagens

A branch de imagem já contém sons e política Chromium nos instaladores. A nova arte de assets/boot deve ser usada no finalizador de BOOT e na montagem local seguinte; imagens já gravadas não mudam apenas por publicar código no Git. O assistente de cartão v0.2.1 continua na branch de imagem.

## Desenvolvimento visual

Manter alterações pequenas em HTML/CSS/JS, preservar contratos do backend e gamepad, testar candidate no R36S e só então sincronizar produção no Git e promover. Consulte VISUAL-UPDATE.md.
