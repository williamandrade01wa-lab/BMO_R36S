# BMO Linux Base — Arquitetura de CI e Validação

## Objetivo

Reduzir ciclos caros de build, impedir divergência entre o que o repositório declara e o que a imagem deve conter e produzir diagnóstico completo em uma única execução pós-build.

A pipeline segue quatro barreiras, sempre nesta ordem:

```text
1. contrato/estrutura
        ↓
2. sintaxe + pins + segurança
        ↓
3. build pesado da imagem
        ↓
4. validação agregada da imagem + artifact
```

Uma falha barata deve impedir o início de uma compilação cara.

## Camada 1 — contrato da imagem

Arquivo:

```text
image/armbian/ci/image-contract.tsv
```

Formato TSV:

```text
partition    kind    source_path    image_path
```

- `partition`: `boot` ou `root`;
- `kind`: `file` ou `exec`;
- `source_path`: arquivo-fonte versionado no repositório;
- `image_path`: destino obrigatório dentro da partição final.

O contrato concentra os requisitos críticos que antes estavam repetidos dentro do YAML da GitHub Actions.

## Camada 2 — preflight barato

Script:

```text
image/armbian/ci/preflight.sh
```

Executa antes do build e valida, de forma agregada:

- arquivos estruturais obrigatórios;
- formato do contrato;
- destinos duplicados;
- existência dos arquivos-fonte;
- bit executável dos fontes marcados como `exec`;
- sintaxe Bash dos scripts críticos;
- sintaxe Python do `bmo-firstboot`, sem executá-lo;
- presença e formato dos pins de upstream;
- board/release esperados;
- assinaturas óbvias de chave privada ou token GitHub nas fontes da imagem.

Se qualquer item falhar, o job pesado não inicia.

## Camada 3 — build

O builder existente continua sendo a fonte de geração da imagem:

```text
image/armbian/build-bmo-linux-base.sh
```

Esta mudança de CI não altera kernel, DTB, overlay, firstboot, rede ou conteúdo da imagem. A intenção é melhorar o processo antes de corrigir qualquer defeito funcional ainda não comprovado.

## Camada 4 — validação pós-build

Script:

```text
image/armbian/ci/validate-image.sh
```

Responsabilidades:

1. confirmar que a imagem existe e não está vazia;
2. anexar a imagem em loop device com partscan;
3. identificar BOOT FAT e ROOT ext4;
4. montar ambas somente para leitura;
5. verificar todo o contrato;
6. acumular todas as falhas de conteúdo em vez de encerrar no primeiro erro;
7. emitir diagnóstico direcionado das pastas relevantes;
8. gerar um resumo único com quantidade de falhas.

Sucesso:

```text
BMO_IMAGE_CONTENTS_OK
```

Falha:

```text
BMO_IMAGE_VALIDATION_FAILED count=N
```

## Artifact de diagnóstico

A saída da validação é salva em:

```text
image/armbian/output/validation-report.txt
```

O workflow publica esse relatório com `if: always()`. Assim, mesmo quando a imagem falha na validação, o diagnóstico da execução permanece disponível sem depender de copiar manualmente trechos do log.

O artifact comprimido da imagem só é produzido depois que a validação passa.

## Concorrência

Runs da mesma branch usam `cancel-in-progress: true`.

Se um novo commit substituir uma versão ainda compilando, a run antiga é cancelada para não consumir runner em um estado obsoleto.

## Regras de manutenção

- critérios novos de conteúdo crítico devem entrar primeiro em `image-contract.tsv`;
- não colocar novamente uma lista paralela de arquivos obrigatórios dentro do workflow;
- validações estáticas devem ficar no preflight;
- validações que dependem do filesystem gerado devem ficar em `validate-image.sh`;
- não adicionar rede externa ao preflight quando o mesmo requisito puder ser validado deterministicamente no repositório;
- não transformar warning em build pesado por tentativa: primeiro tornar a falha observável;
- `docs/ROADMAP.md` só muda quando uma etapa for realmente validada;
- teste físico do R36S continua obrigatório para hardware e não é substituído pela CI.

## Limites

Estas camadas reduzem risco e tempo desperdiçado, mas não provam:

- boot real no R36S;
- painel/ScreenFiles;
- gamepad;
- áudio;
- brilho;
- OTG/HUB/Wi-Fi;
- comportamento real do firstboot;
- `bmo install` completo.

Esses itens permanecem nas fases físicas do projeto.
