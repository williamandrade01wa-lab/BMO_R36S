# Preparação para uma futura versão pública

Este repositório permanece **privado durante o desenvolvimento**.

O objetivo é desenvolver desde já de forma que a publicação futura seja simples e segura.

## Conceito importante: privado agora, público depois

No Git, um repositório guarda não só os arquivos atuais, mas também o histórico de commits.

Por isso, simplesmente trocar o botão de `Private` para `Public` no fim do projeto não é a estratégia preferida para o BMO: o histórico privado já contém artefatos de desenvolvimento e referências que não precisam fazer parte da distribuição pública.

### Estratégia recomendada

```text
Repositorio privado de desenvolvimento
            ↓
versao stable validada
            ↓
public-release-audit
            ↓
exportacao limpa do estado atual
            ↓
Repositorio publico BMO
```

A exportação pública deve começar com histórico limpo (ou um histórico deliberadamente preparado), contendo somente o que realmente será distribuído.

Isso reduz risco de expor:

- credenciais removidas em commits antigos;
- IPs ou caminhos pessoais antigos;
- binários de terceiros que foram usados durante testes;
- backups e artefatos internos;
- experimentos que não fazem parte do produto.

## Git privado durante desenvolvimento

Enquanto este repositório for privado, os R36S de teste podem usar uma **Deploy Key somente leitura** para fazer clone/fetch.

Isso serve apenas porque o GitHub precisa autenticar quem pode ler um repositório privado.

```text
Repositorio privado
      ↓
Deploy Key read-only
      ↓
R36S pode fazer clone/fetch
```

Nenhuma chave privada deve ser salva no Git.

## Git público futuro

Quando existir um repositório público estável, dispositivos comuns não precisarão de Deploy Key para leitura.

O fluxo esperado será:

```text
https://github.com/.../BMO_R36S.git
              ↓
git clone / git fetch via HTTPS
              ↓
sem token
sem senha
sem chave SSH
```

A arquitetura do updater deve aceitar os dois transportes:

- **SSH** enquanto o repositório de desenvolvimento for privado;
- **HTTPS somente leitura** para a distribuição pública.

## Terceiros

A distribuição pública deve preferir instalar software diretamente das fontes oficiais.

### Moonlight

```text
BMO install.sh
      ↓
repositorio oficial Moonlight/Cloudsmith
      ↓
moonlight-qt 6.2.0-1
```

### PPSSPP

```text
BMO install.sh
      ↓
release oficial PPSSPP v1.20.4
      ↓
AppImage oficial aarch64 + verificacao SHA256
```

### Pure

```text
README BMO
      ↓
release original ohjhas/armbian-r36s
      ↓
armbian-r36s-trixie-xfce.img.xz
```

Não há necessidade de o BMO republicar esses arquivos se os projetos originais já os distribuem de forma estável.

## Checklist antes de publicar

A futura publicação só deve ocorrer quando todos os itens abaixo estiverem concluídos:

- [ ] Pure → `install.sh` validado em cartão novo.
- [ ] Reboot e teste físico completo do R36S.
- [ ] `bmo status` e `bmo verify` funcionando.
- [ ] updater validado.
- [ ] updater suporta HTTPS público sem chave.
- [ ] Moonlight instalado diretamente de upstream.
- [ ] PPSSPP instalado diretamente de upstream.
- [ ] nenhum binário temporário de `install/runtime/` na exportação pública.
- [ ] README aponta para a imagem Pure original, sem rehost desnecessário.
- [ ] `CREDITS.md` revisado.
- [ ] `THIRD_PARTY.md` revisado.
- [ ] licença do código original do BMO escolhida.
- [ ] proveniência do código revisada antes de aplicar a licença do BMO.
- [ ] nenhum segredo/chave/token/config local.
- [ ] nenhum ROM/save/state/favorito/pairing pessoal.
- [ ] nenhum IP ou hostname pessoal hardcoded.
- [ ] nomes/e-mails de autoria dos commits avaliados para a publicação.
- [ ] auditoria de segurança aprovada.
- [ ] branch estável testada antes da exportação.

## Sobre `main`, branch e publicação

Para quem está começando com Git:

- `main` é a linha principal do projeto.
- uma `branch` é uma linha separada de trabalho usada para desenvolver sem mexer na versão principal.
- um `commit` é um checkpoint das alterações.
- `push` envia commits do computador para o GitHub.
- `pull` traz para o computador os commits que estão no GitHub.
- um Pull Request (PR) é uma revisão antes de juntar uma branch na `main`.
- `merge` é a junção efetiva da branch aprovada na `main`.

O fato de uma branch estar no GitHub não significa que ela já faça parte da versão principal.

## Regra final

O repositório privado é nosso ambiente de engenharia.

O futuro repositório público deve ser tratado como um produto: limpo, reproduzível, documentado e sem depender de segredos para instalação ou atualização.
