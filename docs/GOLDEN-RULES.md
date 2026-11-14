# Regras de ouro — BMO R36S e Segundo Cérebro

- O repositório, `docs/PROJECT-CONTINUITY.md` e `docs/WORKLOG.md` registram o estado executável e o histórico canônico do BMO.
- O cofre Obsidian em `G:\Meu Drive\Segundo Cérebro\Cérebro` guarda uma síntese navegável do projeto, com links para fontes e commits. Sua estrutura e operação estão no `AGENTS.md` e `REGRAS-DE-OURO.md` dentro do cofre.
- Depois de uma etapa significativa, atualize primeiro a documentação deste projeto; em seguida atualize a página `wiki/projetos/bmo-r36s.md` do cofre, `wiki/index.md` quando mudar a navegação, e acrescente uma entrada em `wiki/log.md`.
- Separe resultados físicos confirmados, relato do usuário, hipótese e teste pendente. Uma tela preta anterior não invalida um boot funcional posterior.
- Não copie arquivos inteiros do cartão, senhas de Wi-Fi/SSH, chaves ou tokens para o cofre.
- Se `G:` não estiver disponível, conclua o registro neste repositório e anote a sincronização do cofre como pendência.
- Registre cada acerto e erro com causa, correção, teste e prevenção. Antes de uma compilação ou gravação longa, consulte o Worklog e os gotchas, procure a mesma dependência em **todos os scripts distribuídos** e rode um gate curto no ambiente real do usuário. Uma correção pontual não encerra uma classe de falhas até a esteira barrar sua recorrência.
- Para políticas do Chromium, teste a imagem final no aparelho: arquivo no caminho efetivo, permissões, leitura pelo navegador e ausência visual do aviso após reboot. A existência do JSON na fonte ou na imagem não encerra a validação.
