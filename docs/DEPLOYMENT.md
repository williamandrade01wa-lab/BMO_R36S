# Deploy do BMO

## Arquitetura

```text
GitHub
  -> Le Potato
  -> SSH dedicado
  -> R36S incoming
  -> helper sudo restrito
  -> candidate
  -> teste fisico
  -> producao
```

O GitHub e a fonte de verdade. A Le Potato atua como ponte de deploy e backup. O R36S executa e valida fisicamente.

## Defaults

Os scripts usam por padrao:

- host R36S: `192.168.1.28`
- usuario SSH: `r36s`
- chave: `/home/hipo/.ssh/bmo_r36s_deploy`

Podem ser sobrescritos sem alterar o Git:

```bash
export BMO_R36S_HOST=192.168.1.28
export BMO_R36S_USER=r36s
export BMO_R36S_KEY="/home/hipo/.ssh/bmo_r36s_deploy"
```

## Preparacao do R36S

Instalar como root:

- `deploy/r36s/bmo-deploy-helper` em `/usr/local/sbin/bmo-deploy-helper`
- `deploy/r36s/bmo-deploy.sudoers` em `/etc/sudoers.d/bmo-deploy`

Permissoes:

```text
/usr/local/sbin/bmo-deploy-helper  root:root 0755
/etc/sudoers.d/bmo-deploy         root:root 0440
```

Validar o sudoers com:

```bash
visudo -cf /etc/sudoers.d/bmo-deploy
```

O usuario `r36s` nao recebe `NOPASSWD: ALL`. Apenas o helper e autorizado.

## Validacao

Na Le Potato, executar como o usuario `hipo`, nunca como root:

```bash
cd /home/hipo/bmo/BMO_R36S
./scripts/validate.sh
```

Se a sessao atual estiver como root:

```bash
runuser -u hipo -- /home/hipo/bmo/BMO_R36S/scripts/validate.sh
```

## Deploy candidate

```bash
runuser -u hipo -- /home/hipo/bmo/BMO_R36S/scripts/deploy-candidate.sh
```

Esse comando:

1. valida o checkout;
2. testa SSH/helper;
3. envia apenas `frontend/index.bmo-next.html`;
4. confere SHA256 antes e depois da instalacao;
5. cria backup remoto;
6. reinicia somente o kiosk;
7. executa health checks;
8. para antes de producao.

Depois do deploy, o teste fisico no R36S e obrigatorio.

## Promocao

Somente depois do teste fisico:

```bash
runuser -u hipo -- /home/hipo/bmo/BMO_R36S/scripts/promote-production.sh --confirmed
```

A promocao exige que o candidate remoto tenha o mesmo SHA256 do candidate do checkout local.

## Rollback

Listar backups:

```bash
runuser -u hipo -- /home/hipo/bmo/BMO_R36S/scripts/rollback.sh --list
```

Restaurar candidate e producao de um backup:

```bash
runuser -u hipo -- /home/hipo/bmo/BMO_R36S/scripts/rollback.sh YYYYMMDD-HHMMSS --confirmed
```

O rollback reinicia somente o kiosk e executa health checks.

## Regras

- nunca promover automaticamente;
- nunca copiar `Moonlight.conf`;
- nunca versionar ROMs, saves, states, caches, chaves ou senhas;
- nao usar deploy para alterar particoes;
- nao executar `fstrim`, `blkdiscard` ou `apt autoremove`;
- manter candidate, teste fisico, backup e producao como etapas separadas.
