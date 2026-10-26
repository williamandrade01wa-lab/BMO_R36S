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


## CP-PURELIGHT-001 — candidata completa verificada no PC

STATUS=OFFLINE_VERIFIED_PHYSICAL_PENDING
VERSION=0.1.0-beta
DATE=2026-10-26
R36S_REQUIRED=YES
PUBLISHED_TO_RELEASES=NO
CORE_SOURCE=af93facc944df8d019ff6189c1ccc007373dc749
PC_TOOL_SOURCE=7533e2dfb718cc12435567da8108ee036531d57f
CI_RUN=40259216780
CORE_ARTIFACT=12624200746
IMAGE=BMO-R36S-PureLight-v0.1.0-beta.img.xz
XZ_BYTES=425364488
XZ_SHA256=419adb83a60970834387bdad590a319b260ee7b85d57c9798b4c2ed43a623b90
RAW_BYTES=2386558976
RAW_SHA256=707845c2c55562ad959c82ea21bf8a48bbcd7d9ee3f3f5dd30c88abaa75581d1

Finalização completa com BMO_LIGHT_FINAL_IMAGE_OK: 96 arquivos do payload, 12 WAV, política Chromium, frontend, sanitização e commit conferidos; runtime PPSSPP, logo e assistente v0.2.1 lidos de volta na FAT; ext4 preservada; XZ descomprimida integralmente com SHA raw igual. Arquivo XZ teve SHA recalculado após a finalização. Manifesto em docs/releases. Root usada antes das dependências: 1404530688 bytes.

Não confundir com Light antiga ou Ready12GiB. Próximo passo: usuário gravar cartão extra8GB+, preparar pelo ABRIR-BMO.cmd, TF2 fora, testar expansão/rede/instalação automática/BMO; depois hardware/jogos. Não publicar Releases antes do teste/autorização. Arquivo final permanece no PC, fora dos blobs Git.
