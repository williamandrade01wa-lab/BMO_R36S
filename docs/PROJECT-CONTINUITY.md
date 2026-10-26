# BMO R36S — estado atual e continuidade

Snapshot de encerramento/migração: **2026-10-26**, America/Sao_Paulo. Este arquivo substitui resumos antigos como estado operacional. Histórico/evidências anteriores continuam no WORKLOG e nos commits. Confirmar HEAD/CI reais antes de qualquer alteração.

## 1. Prioridade imediata

**PureLight v0.1.0-beta pronta no PC para teste físico do usuário.** Não repetir compilação por desconhecer o chat. Não publicar no Releases antes do teste e autorização do usuário.

Arquivo local: outputs/BMO-R36S-PureLight-v0.1.0-beta.img.xz na máquina descrita em ENVIRONMENT.md.

- Download: 425364488 bytes (~425,4 MB).
- Raw descompactada: 2386558976 bytes (~2,39 GB).
- Root usada antes dos pacotes: 1404530688 bytes; não é a ocupação final após instalar.
- SHA256 XZ: 419adb83a60970834387bdad590a319b260ee7b85d57c9798b4c2ed43a623b90
- SHA256 IMG: 707845c2c55562ad959c82ea21bf8a48bbcd7d9ee3f3f5dd30c88abaa75581d1
- Manifesto versionado: docs/releases/PureLight-v0.1.0-beta.manifest.json.
- Checksum versionado: docs/releases/PureLight-v0.1.0-beta.img.xz.sha256.
- Validação física: PENDING. Publicação em Releases: não realizada.

## 2. Git e versões

- Repositório privado: williamandrade01wa-lab/BMO_R36S.
- main: App v0.1.0-beta.1, base para evolução visual. PR #5 integrado (merge c8e218953ce3d710d47042db16448fc664ad3997); CI PR40257425587 e main40257577056 aprovadas. Mudanças posteriores de documentação não alteram esse frontend.
- beta/app-v0.1.0: snapshot do App (a21dea53d902c031b8775989ed55526ff59977eb), preservado.
- feat/bmo-linux-base-v1: montagem/firstboot/Light; código core da candidata af93facc944df8d019ff6189c1ccc007373dc749. Ferramentas PC versionadas em 7533e2dfb718cc12435567da8108ee036531d57f. HEAD de documentação pode ser posterior; consultar Git.
- Versão da imagem PureLight 0.1.0-beta é separada da versão do App 0.1.0-beta.1 e da Base 0.2.

## 3. Build/artefatos e verificações concluídas

CI core **40259216780**, job121367704287: sucesso. Base9 pinada da run40118103143; kernel6.12.32-lts-rk3326 reutilizado. Sem build/arquivo pesado novo na Le Potato.

Artifact core12624200746, bmo-purelight-core-40259216780; ZIP403604477 bytes, SHA c8c5ff6f744ed77586890ece54d1fee908503c4283ff180f4c23c3c837b076c7. Esse artifact é intermediário: sozinho não é a imagem final, pois o runtime PPSSPP foi incluído no PC depois.

Core XZ SHA2ff0895dc49663d22b530fc3ef85f2280c93e0150f419ae8295b7a4c47b1bf85. Finalização PC terminou com BMO_LIGHT_FINAL_IMAGE_OK: 96 arquivos conferidos, 12 WAV, política Chromium, frontend, versão/commit, sanitização, runtime PPSSPP e logo lidos de volta na FAT, raiz ext4 preservada e descompressão completa conferida por SHA raw.

- Frontend: 946f7596ee4f82781a092ff9af598da877a685279c790e691a859a973cda348f
- Assistente: v0.2.1; SHA e84d521a8c7e0c10a08b4c5846551d2f08d975f6063d200a57d38dd7a6123444
- Logo: 4b6e0533c080b3e374529887927123e0b56aa70e879f8ba774418ef6fcfaa661
- PPSSPP.TGZ: 1af91efd8374a2c164e5f2ffa37b3d65980b825a207cbb09c688b2997088c5ad
- Finalizador PC: 7617e4ce68d0bf46171dac93ae2e9a69c7f964e1f5fcd452fd472f921a804a2a

Entregáveis finais estão em outputs no PC: .img.xz, .sha256, .manifest.json e -LEIA-ME.txt. Imagens Ready beta1 (raw12GiB) e primeira Light antiga continuam como históricos separados; não confundir com esta PureLight atualizada.

## 4. Comportamento esperado da PureLight — ainda testar

Cartão extra8GB+, ABRIR-BMO.cmd na BOOT, copiar ScreenFiles pelo assistente (Panel4 é o que funcionou no aparelho do usuário), configurar Wi-Fi/senha/SSH. TF2 de jogos FORA durante todo primeiro boot. Expandir SD, conectar à rede, baixar dependências automaticamente com progresso e abrir BMO. Após concluir/desligar, recolocar TF2.

Inclui assistente v0.2.1 com logs, 12 sons originais, nova arte de boot, política Chromium sem tradução, fonte local e runtime pequeno PPSSPP. Chromium/emuladores grandes são baixados depois; sem chave/token Git, Wi-Fi real, SSH pessoal ou pareamento na imagem.

Próximo passo exato: usuário gravar a candidata e reportar primeiro boot/expansão/rede/progresso/abertura BMO. Depois conferir carinhas/som, botões, volume/brilho, reinício, TF2 e jogo/streaming. Só então discutir publicação. R36S_REQUIRED=YES.

## 5. O que foi confirmado na Ready/App

Na Ready em .65: boot/SSH, navegação e sons das carinhas confirmados pelo usuário. O som voltou ao incluir /opt/bmo-sounds e restaurar HP. DTB/DTBO são idênticos ao original .28, que usa kernel6.12.74; Jack=on também ocorre no original. Não inverter GPIO/trocar DTB/forçar SPK por esse indicador.

Update visual do PC foi testado com HTML idêntico: candidate, confirmação física do usuário, promoção e rollback, SHA preservado e serviços/HTTP OK. Backups20261025-225237 e20261025-225428. Produção final index.html. CLI bmo update no aparelho não foi implementado; ferramenta atual é scripts/update-visual.py no PC, com Git privado autenticado nesse PC.

Nova logo foi aplicada no aparelho com backup/hash conferido; renderização no boot ainda não foi confirmada pelo usuário. Esses testes da Ready não substituem teste da PureLight.

## 6. Memória e múltiplas frentes

Leia AGENTS.md, USER-REQUIREMENTS.md e ENVIRONMENT.md antes de trabalhar. Registre etapas/evidências no WORKLOG e atualize apenas o andamento da área sem apagar outras conversas. Use branch/checkout isolado, confirme Git/CI e preserve alterações alheias.

Para visual: partir de main e seguir VISUAL-UPDATE.md. Para imagem: feat/bmo-linux-base-v1 e LIGHT-INSTALL.md. Para infra: confirmar IP e permissão/credenciais locais, economizando Potato. Não capturar segredos nem instalar hooks/ai-memory automaticamente.

INICIAR-CODEX.cmd prepara contexto/prompt; -StartCodex abre CLI em worktree se instalado. Para outro agente, usar docs/HANDOFF.md. O script é auxílio: as regras e o estado versionados são a memória durável.
