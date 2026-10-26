# Continuidade — BMO App beta

## Estado em 2026-10-25

App v0.1.0-beta.1 preparado em beta/app-v0.1.0 para integrar à main. Base main: 613fb076e3d4fb4274df5afdc457503266cc2a69. App funcional preservado de feat/bmo-linux-base-v1 e71d87a8ab9e37554487a85d5fc3002ba07d4da5. A construção da imagem/Light permanece nessa branch separada.

Frontend testado: SHA256 946f7596ee4f82781a092ff9af598da877a685279c790e691a859a973cda348f. R36S em 192.168.1.65, r36s. Navegação e sons das carinhas confirmados pelo usuário; candidate, promoção e retorno ao backup testados com frontend idêntico. Produção voltou a index.html com hash preservado. Chave privada não está no repositório.

12 sons recuperados em assets/sounds, com hashes, corrigem conteúdo ausente na Ready. Nova logo assets/boot/logo.bmp já instalada no aparelho, SHA 4b6e0533c080b3e374529887927123e0b56aa70e879f8ba774418ef6fcfaa661; falta confirmar visualmente no próximo boot. Política Chromium TranslateEnabled=false já aplicada.

## Próximo passo exato

Concluir CI e integrar esta beta App à main pelo PR. Para alterações de visual, criar branch a partir de main, editar frontend/index.bmo-next.html, usar scripts/update-visual.py candidate com a branch do Git, testar fisicamente e só então promover/sincronizar frontend/index.html e abrir PR. Não usar bmo update no aparelho: ainda não implementado. O update desta beta roda no PC e precisa de Git autenticado no repositório privado.

Não alterar gamepad, backend nem launchers apenas para mudar visual. Imagem Light, instalador inicial e auditoria pública continuam fora do escopo desta promoção. Registros anteriores completos permanecem em docs/WORKLOG.md da branch feat/bmo-linux-base-v1.

R36S_REQUIRED=YES para novo visual, jogos/streaming e confirmação da nova arte de boot. Testes unitários e envio de HTML idêntico não validam qualquer visual futuro.
