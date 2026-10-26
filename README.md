# BMO R36S — App 0.1.0-beta.1

Base de desenvolvimento do aplicativo BMO para evoluir o visual preservando as funções atuais. **Versão beta privada**, com validações parciais no R36S.

Esta branch reúne o frontend em uso no aparelho, launchers compatíveis, os 12 sons originais e a nova arte de boot. A imagem Linux/Light permanece em `feat/bmo-linux-base-v1`; não é necessário recompilar a imagem para cada mudança de HTML/CSS/JS do App.

## Atualizar o visual

No PC com Git, Python 3.10+ e OpenSSH, usando um clone do repositório:

```powershell
.\BMO-Atualizar-Visual.cmd check --ref main
.\BMO-Atualizar-Visual.cmd candidate --ref main --target r36s@IP --identity C:\caminho\chave_ssh
```

O GitHub privado é autenticado no PC. O R36S precisa apenas do acesso SSH já configurado e do helper instalado. A ferramenta busca o commit do Git sem sobrescrever arquivos de trabalho locais, verifica o hash, guarda backup e ativa a versão de teste.

Teste botões, carinhas e som. Para efetivar o HTML validado, use o SHA256 impresso:

```powershell
.\BMO-Atualizar-Visual.cmd promote --tested-sha SHA256 --target r36s@IP --identity C:\caminho\chave_ssh
```

Falha de verificação após instalar dispara tentativa de retorno ao backup. Retorno manual:

```powershell
.\BMO-Atualizar-Visual.cmd rollback --backup-id AAAAMMDD-HHMMSS --target r36s@IP --identity C:\caminho\chave_ssh
```

Detalhes: [atualização visual](docs/VISUAL-UPDATE.md), [estado da beta](docs/APP-BETA.md) e [continuidade](docs/PROJECT-CONTINUITY.md). O comando `bmo update` no R36S ainda não faz parte desta versão; o atualizador desta beta roda no PC.

## Próximas mudanças de interface

Crie uma branch de visual a partir de main, altere `frontend/index.bmo-next.html`, faça commit/push e use `candidate --ref SUA_BRANCH`. Após teste físico, sincronize `frontend/index.html` com o candidate e abra PR para main. Preserve o backend, o mapeamento do gamepad, os launchers e as integrações de jogos/streaming durante mudanças visuais.

## Recursos recuperados

- Sons: `assets/sounds/`, 12 WAV, 2183032 bytes, SHA256 individual.
- Boot: `assets/boot/logo.bmp`, 640×480, BMP RGB de 24 bits sem compressão.
- Tradução: política `install/system/chromium/bmo-kiosk.json`, já aplicada no aparelho de teste.

Atualizar o HTML preserva estes recursos instalados. Sons, boot e política exigem seus próprios passos de instalação quando estiverem ausentes; o atualizador visual não executa um instalador geral.
