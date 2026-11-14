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

## Runtime do kiosk

O kiosk usa `/etc/default/bmo-kiosk` para decidir qual frontend abrir.

Estado normal:

```text
BMO_UI_ENTRY=index.html
```

Durante um deploy de teste:

```text
BMO_UI_ENTRY=index.bmo-next.html
```

O launcher aceita somente `index.html` e `index.bmo-next.html`. Qualquer valor invalido cai de forma segura para `index.html`.

Fluxo oficial:

```text
main / operacao normal
  -> index.html
  -> kiosk em producao

deploy-candidate.sh
  -> instala index.bmo-next.html
  -> muda kiosk para candidate
  -> reinicia somente kiosk
  -> teste fisico

promote-production.sh --confirmed
  -> exige candidate ativo
  -> copia candidate para index.html
  -> muda kiosk para producao
  -> reinicia somente kiosk

rollback.sh
  -> restaura backup
  -> muda kiosk para producao
  -> reinicia somente kiosk
```

## Defaults

Os scripts usam por padrao:

- host R36S: `<R36S_IP>`
- usuario SSH: `r36s`
- chave: `/home/hipo/.ssh/bmo_r36s_deploy`

Podem ser sobrescritos sem alterar o Git:

```bash
export BMO_R36S_HOST=<R36S_IP>
export BMO_R36S_USER=r36s
export BMO_R36S_KEY="/home/hipo/.ssh/bmo_r36s_deploy"
```

## Preparacao do R36S

Instalar como root:

- `deploy/r36s/bmo-deploy-helper` em `/usr/local/sbin/bmo-deploy-helper`
- `deploy/r36s/bmo-deploy.sudoers` em `/etc/sudoers.d/bmo-deploy`
- `deploy/r36s/bmo-kiosk.default` em `/etc/default/bmo-kiosk`
- `launchers/bmo-kiosk.sh` em `/usr/local/bin/bmo-kiosk.sh`

Permissoes:

```text
/usr/local/sbin/bmo-deploy-helper  root:root 0755
/etc/sudoers.d/bmo-deploy         root:root 0440
/etc/default/bmo-kiosk            root:root 0644
/usr/local/bin/bmo-kiosk.sh       root:root 0755
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
6. muda o runtime para candidate;
7. reinicia somente o kiosk;
8. confirma `KIOSK_ENTRY=index.bmo-next.html`;
9. executa health checks;
10. para antes de producao.

Depois do deploy, o teste fisico no R36S e obrigatorio.

## Promocao

Somente depois do teste fisico:

```bash
runuser -u hipo -- /home/hipo/bmo/BMO_R36S/scripts/promote-production.sh --confirmed
```

A promocao exige:

- candidate remoto com o mesmo SHA256 do checkout local;
- runtime atualmente apontando para `index.bmo-next.html`.

Ao concluir, o script:

- copia o candidate validado para `index.html`;
- altera o runtime para producao;
- reinicia somente o kiosk;
- confirma `KIOSK_ENTRY=index.html`;
- valida o frontend de producao e o backend.

## Rollback

Listar backups:

```bash
runuser -u hipo -- /home/hipo/bmo/BMO_R36S/scripts/rollback.sh --list
```

Restaurar candidate e producao de um backup:

```bash
runuser -u hipo -- /home/hipo/bmo/BMO_R36S/scripts/rollback.sh YYYYMMDD-HHMMSS --confirmed
```

O rollback sempre retorna o runtime para `index.html`, reinicia somente o kiosk e executa health checks.

## Diagnostico do runtime

```bash
sudo -n /usr/local/sbin/bmo-deploy-helper status
sudo -n /usr/local/sbin/bmo-deploy-helper kiosk-entry
```

Valores validos:

```text
index.html
index.bmo-next.html
```

## Regras

- operacao normal deve usar `index.html`;
- candidate so fica ativo durante teste fisico;
- nunca promover automaticamente;
- nunca copiar `Moonlight.conf`;
- nunca versionar ROMs, saves, states, caches, chaves ou senhas;
- nao usar deploy para alterar particoes;
- nao executar `fstrim`, `blkdiscard` ou `apt autoremove`;
- manter candidate, teste fisico, backup e producao como etapas separadas.
