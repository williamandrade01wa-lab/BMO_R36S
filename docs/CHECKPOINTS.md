# Checkpoints — App beta

## CP-APP-BETA-001 — Base funcional para evolução visual

STATUS=PRIVATE_BETA
VERSION=0.1.0-beta.1
SOURCE_APP=e71d87a8ab9e37554487a85d5fc3002ba07d4da5
FRONTEND_SHA256=946f7596ee4f82781a092ff9af598da877a685279c790e691a859a973cda348f
R36S_REQUIRED=YES

Confirmados navegação e efeitos das carinhas, envio de frontend idêntico para candidate, confirmação do usuário, promoção e retorno ao backup no R36S .65. Fluxo usa backups 20261025-225237 e 20261025-225428. Produção termina em index.html, SHA preservado. Sons com 12 hashes conferidos; tradução Chromium já corrigida.

Limites: não é release pública estável nem valida todos os jogos/streaming. Novo visual exige novo teste físico. Light e instalação inicial permanecem na branch de imagem. Nova logo foi gravada/hash conferido; falta confirmação no boot.

Retorno seguro: helper rollback-frontend com BACKUP_ID e reinício do kiosk; cartão original preservado. Branch de beta e PR conservam a referência de fonte para main.

Integração confirmada: PR #5, main c8e218953ce3d710d47042db16448fc664ad3997; CI PR40257425587 e main40257577056 verdes. A base é beta privada do App. Próximas imagens recebem a arte pelo commit ad0bca4b8de36edbd5d5b98df7ac3fa3248a35b1 na branch de imagem, ainda sujeitas a novo build/teste.
