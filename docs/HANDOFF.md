# Iniciar ou transferir uma conversa/agente

## Regra

AGENTS.md e USER-REQUIREMENTS.md são instruções duráveis. PROJECT-CONTINUITY.md é o estado atual; WORKLOG.md é a evidência cronológica. Leia os arquivos e confirme o Git antes de agir. Se abrir snapshot/branch antigo, consulte as regras e a continuidade atuais da main e as particularidades da branch de trabalho.

## Prompt para copiar

```text
Continue o projeto BMO R36S no repositório williamandrade01wa-lab/BMO_R36S.
Antes de alterar qualquer arquivo, leia AGENTS.md, docs/USER-REQUIREMENTS.md,
docs/PROJECT-CONTINUITY.md, docs/ENVIRONMENT.md, WORKLOG, ROADMAP,
PROJECT-STRUCTURE e CHECKPOINTS em docs; depois a documentação da área.
Confirme branch/HEAD, alterações locais e último CI. Use branch/checkout isolado
para esta conversa; preserve trabalho de outros agentes.
O Git é a memória obrigatória: registre cada etapa significativa no WORKLOG,
atualize continuidade/checkpoints quando necessário e deixe próximo passo exato
antes de encerrar. Nunca grave credenciais/ROMs/saves nem dependa só do chat.
O estado do App, imagens e testes deve vir da continuidade e dos manifestos atuais.
Leia docs/releases antes de repetir build ou chamar imagem de pronta.
Não publique uma candidata sem teste e autorização do usuário.
Priorize GitHub/PC e economize Le Potato. Continue a prioridade atual registrada
ou a área que eu indicar, mantendo as funções do BMO durante mudanças visuais.
```

## Inicializador Windows

Na raiz de um clone atualizado, execute INICIAR-CODEX.cmd. Ele reúne contexto dos documentos, observa branch/HEAD/status local e copia um prompt. Não altera branch nem faz pull/reset.

Opções: -Area geral|visual|imagem|infra; -Refresh busca refs do origin sem trocar arquivos; -StartCodex abre o CLI, se instalado. O CLI é iniciado em worktree isolado quando houver checkout Git. Sem -StartCodex, cole o prompt no Codex desktop ou em outro agente com o projeto aberto.

Saídas locais: .bmo-context/CONTEXTO-ATUAL.md e PROMPT-INICIAL.txt (ignoradas pelo Git). Elas são snapshots auxiliares; os documentos versionados continuam sendo a fonte da verdade. O script não instala ai-memory, não captura chats nem altera configuração global do Codex.

Para outra conversa/parte do projeto, use outro checkout/worktree e escolha a área correspondente. Ao terminar, commite/registre o progresso no Git. Atualizações de IP/estado devem indicar data e evidência.
