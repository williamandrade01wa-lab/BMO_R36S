# Estrutura do App

- frontend/: produção index.html e candidate index.bmo-next.html; evoluir visual preservando os contratos.
- backend/, launchers/, scripts/runtime/, configs/, systemd/: funções existentes do aparelho.
- assets/sounds/: 12 WAV preservados, inventário e SHA256.
- assets/boot/: logo BMP versionada e hash; instalação de boot separada do update HTML.
- deploy/r36s/: helper restrito e sudoers usados pelo update.
- scripts/update-visual.py e BMO-Atualizar-Visual.cmd: atualização do frontend a partir do Git no PC.
- scripts/validate-app.py, tests/ e .github/workflows/app-checks.yml: verificações da beta.
- install/system/chromium/: política de tradução já aplicada no aparelho de teste.
- docs/: estado, evidência, limitações e fluxo de update.
- VERSION: versão do App, independente da imagem Linux.

Não armazenar credenciais, ROMs, saves, chaves ou backups no Git. A imagem experimental/Light permanece em feat/bmo-linux-base-v1.
