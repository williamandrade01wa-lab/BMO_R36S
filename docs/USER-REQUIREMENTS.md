# Especificações e diretrizes permanentes do usuário

Estas decisões valem para novas conversas, agentes e partes do BMO até alteração explícita do usuário. O Git é a memória durável do projeto; uma conversa não substitui estes arquivos.

## Produto

- R36S dedicado ao BMO, simples para usuário leigo: baixar, gravar cartão, abrir assistente na BOOT, configurar e usar.
- Prioridade atual de imagem: **PureLight** pequena; apenas boot, rede, configuração e instalador inicialmente. Baixar BMO/dependências automaticamente após conectar no primeiro boot, mostrando progresso.
- Expandir o filesystem antes dos pacotes para usar a capacidade disponível do SD. Recomendação atual: cartão extra de 8 GB ou maior.
- Remover extras Linux que não sejam necessários diretamente ao BMO, preservando drivers, firmware e dependências reais. Sem remover bibliotecas arbitrariamente/forçar Depends.
- TF2 de jogos deve ficar FORA durante todo primeiro boot; recolocar somente com aparelho desligado.
- Separar versão da imagem e versão do App; distinguir candidata, teste físico e release.

## Experiência e visual

- Nome público profissional: Assistente de Preparação BMO. Não usar apelidos informais da conversa no produto.
- Assistente Windows com perguntas/opções, seleção de ScreenFiles, cópia e backup dos destinos, configuração sem editar TXT e sem exigir admin como solução padrão.
- Valores do TXT são literais: não acrescentar aspas a SSID/senha; nunca usar eval/source no TXT de usuário.
- Progresso/resultado de rede e IP devem ser fáceis de encontrar; logs precisam explicar falhas sem revelar senhas.
- Preferir Wi-Fi 2,4 GHz para compatibilidade. 5 GHz depende do adaptador/região; verificar driver/bandas, não inferir capacidade pelo SSID nem afirmar que todos os adaptadores só usam 2,4 GHz.
- Evoluir visual em mudanças pequenas de HTML/CSS/JS, preservando backend, gamepad, launchers e funções já existentes. Não refatorar funções apenas para mudar aparência.
- Preservar os 12 sons originais em assets/sounds e a arte de boot em assets/boot, com hashes. Imagem BMP deve manter formato compatível 640x480 RGB24 sem compressão.

## Funções que não podem regredir

PC STREAM/Moonlight; retorno ao BMO; FN+SELECT para sair do streaming; Favorites X/Y; Fast Nav/Virtual Window/Lazy Load; GBA ZIP; PSP standalone; volume físico; FN+Volume para brilho; navegação pelo gamepad; tty1/kiosk. Preservar mapeamentos descritos no AGENTS.md.

## Build e armazenamento

- Priorizar GitHub Actions e PC. Economizar armazenamento da Le Potato; não iniciar nela builds, extrações ou cópias grandes por padrão.
- Operações pequenas de diagnóstico/SSH continuam permitidas. Preservar dados e ambiente da Potato.
- Reutilizar base/kernel validados, com fonte e hashes registrados; recompilar kernel apenas por necessidade demonstrada.
- FTP do roteador pode guardar arquivos compactados e checksums; manter autenticação. Não usar FTP como diretório de build, rootfs ou banco ativo. Senha somente entrada local segura.
- Imagens, archives grandes, runtimes e backups ficam fora dos blobs do Git. Git guarda código, receitas, manifestos, hashes, evidências e decisões.

## Atualizações e publicação

- App funcional está em main; imagem experimental/PureLight usa feat/bmo-linux-base-v1. Confirmar no Git antes de operar, pois branches podem evoluir.
- Atualização visual desta beta roda no PC com Git/SSH: candidate, teste físico, promoção e retorno ao backup. bmo update no aparelho ainda não implementado.
- Autenticação do Git privado fica no PC. Não embutir tokens/chaves do usuário na imagem.
- Não publicar PureLight no Releases antes do teste do usuário e autorização para publicar. Build/CI verde não substitui teste físico.
- Cumprir autorização já dada e concluir trabalho necessário sem repetir confirmações rotineiras. Pedir somente informação/decisão realmente faltante ou permissão imposta pelo ambiente.

## Memória e trabalho em várias conversas

- Ler AGENTS.md e esta especificação antes de trabalhar. Confirmar estado real no Git, não apenas resumo do chat.
- Registrar toda etapa significativa em WORKLOG antes de avançar; atualizar continuidade quando mudar branch, arquitetura, bloqueio, imagem ou próximo passo.
- Registrar escopo, branch/commit inicial, ação, arquivos, teste/evidência, resultado, riscos, R36S_REQUIRED e próximo passo exato.
- Antes de encerrar, migrar ou perder contexto, deixar handoff no Git. Não deixar a única cópia de uma decisão no chat.
- Conversas paralelas devem usar branches/checkouts isolados e respeitar alterações de outros agentes. Não fazer reset/force-push/limpeza para apagar trabalho alheio.
- Nunca registrar senhas, chaves privadas, tokens, ROMs, saves, pareamentos reais ou TXT/backups preenchidos. Registrar resumos técnicos curados, não despejar conversas/configurações privadas.
- A avaliação de ai-memory permanece apenas referência. Não foi instalado servidor, hook ou captura global; estes documentos Git são a memória ativa.
