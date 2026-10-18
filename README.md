# BMO R36S

Projeto do BMO para R36S.

Este repositório é a fonte oficial do código do projeto.

## Começando do zero

Se você tem um R36S compatível, a imagem **BMO Linux Pure R36S** e acesso a este Git, comece por:

[`bootstrap/README.md`](bootstrap/README.md)

O objetivo desse manual é permitir reproduzir a instalação sem depender do histórico de desenvolvimento do projeto:

```text
BMO Linux Pure
      ↓
primeiro boot / rede / SSH
      ↓
git clone BMO_R36S
      ↓
sudo ./install/install.sh
      ↓
BMO completo
```

O preset de primeiro boot é opcional. O template genérico fica em:

```text
bootstrap/firstboot.conf.example
```

Credenciais reais devem ficar apenas em arquivos locais ignorados pelo Git.

## Instalação do BMO

Após clonar o repositório no R36S, a instalação real possui um único ponto de entrada:

```bash
sudo ./install/install.sh
```

As antigas fases em `install/phases/` são ferramentas de build/sandbox e não devem ser executadas manualmente para instalar o aparelho.

## Ambientes

- **Produção no R36S:** `/opt/bmo-ui/index.html`
- **Candidate no R36S:** `/opt/bmo-ui/index.bmo-next.html`
- **Le Potato:** servidor de deploy, validação, backup e rollback

## Fluxo de desenvolvimento e promoção

```text
editar -> validar -> candidate -> teste físico -> backup -> produção
```

Nunca promover alterações diretamente para produção sem teste físico no R36S.

## Estrutura

```text
bootstrap/   primeiro boot e manual de instalação limpa
frontend/    interface do BMO
backend/     APIs locais
launchers/   jogos, kiosk e Moonlight
configs/     configurações versionadas
systemd/     serviços do sistema
install/     instalador e runtimes congelados
scripts/     validação, deploy e utilitários
docs/        documentação adicional
```

## Segurança

Este repositório não deve conter ROMs, saves, states, backups privados, chaves SSH, tokens, credenciais, senhas reais de Wi-Fi ou o conteúdo privado de `Moonlight.conf`.

Para bootstrap, edite uma cópia local de `bootstrap/firstboot.conf.example`; arquivos `bootstrap/*.local.conf` são ignorados pelo Git.

As regras operacionais detalhadas para agentes e Codex ficam em [`AGENTS.md`](AGENTS.md).
