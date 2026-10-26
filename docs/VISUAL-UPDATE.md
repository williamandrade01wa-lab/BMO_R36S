# Atualização visual — App beta

A ferramenta `scripts/update-visual.py` roda no PC (Windows/Linux/macOS) e usa o helper existente `/usr/local/sbin/bmo-deploy-helper`. Não altera kernel, DTB, partições, emuladores, ROMs/saves, som ou rede.

## Preparação única

1. Instalar Git, Python 3.10+ e cliente OpenSSH no PC.
2. Clonar `https://github.com/williamandrade01wa-lab/BMO_R36S.git` e autenticar o GitHub privado no PC. O origin deve apontar para esse repositório por HTTPS ou SSH.
3. Ter chave SSH cadastrada no usuário r36s e helper/sudoers já instalados no R36S. A chave privada e o login GitHub ficam no PC, fora do repositório.
4. Ligar o aparelho para `candidate`, `promote` e `rollback`. `check` consulta somente o Git.

O clone deve conter esta versão do atualizador. Enquanto o PR ainda não estiver em main, usar `--ref beta/app-v0.1.0`. A busca usa fetch+commit imutável; não executa pull/reset no seu diretório de trabalho.

## Fluxo

- `check`: busca a branch, valida marcadores funcionais do HTML e mostra commit/SHA256.
- `candidate`: faz upload só de index.bmo-next.html, confere SHA local/remoto, usa backup do helper, ativa candidate, reinicia somente kiosk e verifica serviços/HTTP. Produção não é substituída nesta etapa.
- `promote --tested-sha`: exige candidate ativo e exatamente o hash testado; promove com novo backup, reinicia kiosk e verifica produção. Rodar somente após teste físico.
- `rollback --backup-id`: restaura o backup e retorna ao frontend de produção.

Falhas depois da instalação tentam restaurar o backup. Se a conexão cair e o aparelho ficar inacessível, a ferramenta pode não conseguir concluir a recuperação remotamente; guarde o BACKUP_ID exibido e execute rollback quando o SSH voltar. O helper é responsável pelos backups em /home/r36s/.bmo-deploy/backups.

Parâmetros comuns: `--target r36s@IP`, `--identity CAMINHO_DA_CHAVE`, opcional `--known-hosts ARQUIVO`. O primeiro contato registra a chave do host; uma chave já conhecida divergente é rejeitada. A ferramenta não coleta nem grava senhas.

## Evidência desta beta

- 13 testes locais aprovados, incluindo upload divergente, candidate incompleto, promoção de hash diferente e recuperação após falha HTTP.
- No R36S .65: frontend SHA 946f7596ee4f82781a092ff9af598da877a685279c790e691a859a973cda348f enviado sem mudança de visual, candidate ativado, serviços/HTTP/SHA conferidos; usuário confirmou navegação e sons.
- Promoção e retorno ao backup executados no mesmo aparelho com esse HTML idêntico; runtime terminou em index.html com SHA preservado. A etapa Git fetch privada deve ser autenticada no PC de quem executar; o teste físico acima usou bytes preservados do Git e as mesmas funções de envio/promoção/rollback.

Isso valida o fluxo básico da atualização visual, não todos os cenários de falta de energia nem mudanças futuras de interface. Jogos/streaming requerem regressão específica quando suas integrações forem alteradas.
