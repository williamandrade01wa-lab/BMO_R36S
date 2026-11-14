# Dependências de terceiros

Este documento separa o que é **BMO** do que é software de terceiros.

A regra de arquitetura para publicação é simples:

```text
Git público do BMO
        ↓
instalador / configuração / hashes
        ↓
fontes oficiais dos terceiros
        ↓
software instalado no R36S
```

Assim, sempre que tecnicamente possível, o repositório BMO não precisa armazenar uma cópia do binário de terceiros.

## Moonlight Qt

**Função:** PC STREAM.

**Projeto:** https://github.com/moonlight-stream/moonlight-qt

**Versão validada:** `6.2.0-1`

**Licença do projeto:** GPL-3.0-or-later conforme o projeto upstream.

### Estratégia pública pretendida

O `install.sh` deverá configurar o repositório oficial Moonlight/Cloudsmith e instalar a versão validada:

```text
moonlight-qt=6.2.0-1
```

Dessa forma o BMO não hospeda o `.deb`; o pacote é fornecido diretamente pelo repositório oficial do Moonlight.

O SHA-256 do pacote Trixie/arm64 validado está registrado em:

```text
install/manifests/upstream-sources.env
```

## PPSSPP

**Função:** emulação de PSP.

**Projeto:** https://github.com/hrydgard/ppsspp

**Versão validada:** `1.20.4`

**Commit validado:** `fa50bb1976065c4f8b1b47af227d367fe9771555`

**Licença do projeto:** GPL-2.0-or-later.

### Estratégia pública pretendida

A release oficial do PPSSPP possui um AppImage Linux `aarch64` para a versão 1.20.4.

O instalador público deverá baixar esse artefato diretamente da release oficial, verificar o SHA-256 conhecido e preparar o runtime para o BMO.

Se o AppImage oficial não funcionar corretamente no R36S, o fallback será construir o PPSSPP a partir do source/tag oficial no próprio processo de instalação. Não devemos publicar um binário customizado sem antes revisar as obrigações da licença e a reprodutibilidade da build.

## RetroArch, mGBA e Snes9x

Esses componentes são instalados através do APT da distribuição sempre que disponíveis.

O BMO não incorpora seus códigos-fonte ao próprio código. Eles permanecem componentes externos com suas próprias licenças.

## BMO Linux Pure / Armbian

A imagem-base atualmente congelada pelo projeto é byte a byte a mesma release original indicada em `CREDITS.md` e `install/manifests/upstream-sources.env`.

### Estratégia pública pretendida

Em vez de republicar uma cópia da imagem original no repositório BMO, o README público deverá apontar diretamente para a release do projeto que produziu a imagem.

Se futuramente o BMO passar a distribuir uma imagem Linux **modificada**, essa imagem deverá receber uma revisão própria de licença, atribuição e disponibilidade de código-fonte correspondente antes da publicação.

## Runtime privado atual

Durante o desenvolvimento privado, existem artefatos congelados em `install/runtime/` para garantir que o primeiro teste Pure → BMO seja reproduzível.

Eles são considerados **material temporário de desenvolvimento**.

Antes de qualquer repositório público, esses blobs devem deixar de fazer parte da árvore e, idealmente, o repositório público deve nascer de uma exportação limpa sem o histórico privado que já os conteve.

## Licença do próprio BMO

A licença do código original do BMO ainda deve ser escolhida antes da publicação.

A licença do BMO não precisa automaticamente ser a mesma de programas independentes que ele apenas instala ou executa. Porém, qualquer trecho de código efetivamente derivado ou copiado de outro projeto deve respeitar a licença daquele código.

Por isso, a licença final do BMO só deve ser definida depois de uma revisão de proveniência do código próprio.
