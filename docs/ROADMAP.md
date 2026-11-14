# BMO Roadmap

## North Star

O projeto existe para entregar uma experiência simples e didática:

```text
baixar → gravar → configurar BOOT → ligar → bmo install → usar
```

A engenharia pode ser complexa internamente; a instalação pública não deve ser.

## Princípios permanentes

- imagem própria/minimalista para R36S;
- sem XFCE como dependência da solução final;
- BOOT legível pelo Windows;
- ScreenFiles preservadas;
- configuração por `BMO-FIRSTBOOT.txt`;
- DHCP como padrão;
- status/logs úteis na BOOT sem segredos;
- comando `bmo` presente na imagem base;
- Git público via HTTPS na distribuição final;
- nenhum token/chave/credencial embutido;
- dependências externas pinadas e verificadas;
- versão da imagem separada da versão do BMO App;
- cada avanço importante protegido por checkpoint versionado.

## Gates do produto

Os critérios detalhados e os commits seguros de retorno ficam em [`CHECKPOINTS.md`](CHECKPOINTS.md).

### Gate 0 — estrutura e continuidade

Objetivo: garantir que qualquer novo chat/agente/dev consiga entender e continuar o projeto pelo Git.

- [x] estrutura de responsabilidades versionada;
- [x] checkpoints versionados;
- [x] README alinhado com a experiência pública desejada;
- [x] continuidade aponta exatamente o próximo passo;
- [x] Worklog registra decisões significativas.

Evidência:

```text
CP-STRUCTURE-001
commit base: ed658f30c1a3a599b37557188cd8856b5ef54b2b
```

### Gate 1 — imagem base reproduzível

Objetivo: gerar uma imagem mínima válida sem depender do R36S físico.

- [ ] auditoria completa dos pins externos (ScreenFiles/PanCho e checksum obrigatório do U-Boot pendentes);
- [x] Debian Trixie minimal;
- [x] `BUILD_MINIMAL=yes`;
- [x] `BUILD_DESKTOP=no`;
- [x] preflight passa;
- [x] build conclui;
- [x] contrato da imagem passa;
- [x] imagem comprimida;
- [x] SHA256 gerado;
- [x] artifact final publicado pelo CI.

Evidência de CI/contrato: `CP-IMAGE-002`, Run #8 `40057180564`, commit `701ed1d7a2946a143cbbd90527f141e0b05c3867`. Pipeline completo aprovado; reprodutibilidade das dependências externas ainda precisa da auditoria acima. Boot físico não foi inferido do CI.

### Gate 2 — boot e firstboot

Objetivo: cartão novo iniciar e configurar a base sem intervenção técnica avançada.

- [x] boot inicial observado no aparelho (relato do usuário, Run #8, 2026-10-24);
- [ ] ScreenFiles documentadas e funcionais;
- [ ] parser seguro de `BMO-FIRSTBOOT.txt`;
- [ ] usuário/senhas configurados;
- [ ] timezone/locale/hostname aplicados;
- [ ] `BMO-IP.txt` criado;
- [ ] `BMO-STATUS.txt` criado;
- [ ] logs sanitizados;
- [ ] firstboot idempotente.

Evidência parcial do Gate 2: CP-BOOT-001 em VALIDATING; TF2 deve ficar fora durante o primeiro boot. Status detalhado, firstboot e reboot idempotente ainda pendentes.

### Gate 3 — rede e hardware base

Objetivo: a base reconhecer os recursos essenciais do R36S.

- [ ] NetworkManager/DHCP;
- [ ] Wi-Fi USB;
- [ ] autoconnect após reboot;
- [ ] SSH;
- [ ] gamepad;
- [ ] áudio;
- [ ] volume;
- [ ] brilho;
- [ ] USB OTG;
- [ ] HUB USB;
- [ ] Wi-Fi pelo HUB;
- [ ] TF2;
- [ ] DRM/KMS necessário ao BMO.

### Gate 4 — bootstrap público do BMO

Objetivo: instalar o BMO completo sem exigir conhecimento de Git.

- [ ] `bmo source`;
- [ ] `bmo install`;
- [ ] HTTPS público por padrão;
- [ ] SSH somente como override de desenvolvimento;
- [ ] validação de origem/protocolo;
- [ ] download de dependências externas com pin + SHA256;
- [ ] instalação idempotente/reexecutável;
- [ ] nenhum segredo embutido.

### Gate 5 — BMO completo

Objetivo: experiência funcional de uso diário.

- [ ] kiosk/frontend;
- [ ] backend/control API;
- [ ] navegação por gamepad;
- [ ] SYSTEM / CONTROL;
- [ ] teclado Wi-Fi acessível pelo gamepad: maiúsculas, minúsculas e símbolos usuais de senhas WPA; testar entrada real e navegação entre todas as teclas;
- [x] reproduzir e corrigir travamento ao usar B para sair do teclado virtual de Wi-Fi do BMO no R36S; B e SELECT validados no candidate, recuperação sem reset e promoção a produção com backup em 2026-11-14;
- [ ] Favorites X/Y;
- [ ] Fast Nav / Virtual Window / Lazy Load;
- [ ] GBA/SNES;
- [ ] PSP;
- [ ] PC STREAM / Moonlight;
- [ ] FN+SELECT sai do streaming;
- [ ] retorno ao BMO após jogos/streaming.

### Gate 6 — manutenção segura

Objetivo: atualizar sem obrigar o usuário a regravar cartão em toda mudança do BMO App.

- [ ] `bmo verify`;
- [ ] `bmo check-update`;
- [ ] `bmo update`;
- [ ] rollback;
- [ ] recuperação após falha de rede/update;
- [ ] separação clara entre versão da imagem e versão do App.

### Gate 7 — publicação pública

Objetivo: oferecer uma release que um usuário novo consiga seguir sem apoio do desenvolvedor.

- [ ] build reproduzível final;
- [ ] cartão limpo validado do zero;
- [ ] SHA256 publicado;
- [ ] auditoria de segredos;
- [ ] auditoria de licença/proveniência;
- [ ] créditos e terceiros revisados;
- [ ] export público sem histórico/blobs privados desnecessários;
- [ ] instalação pública por HTTPS validada;
- [ ] manual final testado por uma pessoa seguindo somente a documentação.

## Regra de conclusão

Uma caixa só deve ser marcada quando houver evidência correspondente em `docs/WORKLOG.md`.

Build verde, teste em desenvolvimento ou existência do código não substituem validação do gate correspondente.
