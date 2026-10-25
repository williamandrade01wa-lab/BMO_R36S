# BMO Ready 1.0.0-beta.1 — build privado

Esta receita reutiliza a BMO Linux Base da Run #9 e instala todos os componentes no arquivo da imagem antes do primeiro boot. Não executa instalação no sistema da Potato nem nos cartões físicos.

## Entradas verificadas

- Base: Run 40118103143, artifact 12571667623.
- ZIP SHA256: `b496baa785145fb4a2b222e08121d669b3e0f8ff8f7658039a8272eb77981e88`.
- Base .img.xz SHA256: `e32988972ecd085078f430d6988e7bca10b1e551c317773a22235e49c51cc3ee`.
- Base .img SHA256: `33e250518619c9cfecc2a846fa9a68e4bc213a5f1731d93cd07cffcaa61e9996`.
- Runtime PPSSPP SHA256: `1af91efd8374a2c164e5f2ffa37b3d65980b825a207cbb09c688b2997088c5ad`.

O builder exige hashes exatos, host aarch64, workdir novo, saída nova e ao menos 16 GB livres. Estende somente a partição ext4 da cópia de imagem para 12 GiB, preservando FAT e UUIDs/fstab. Nenhum /dev/mmcblk físico é usado como destino do builder.

## Construção

```bash
sudo bash install/build-beta-image.sh \
  --base-raw /caminho/base-run9.img \
  --ppsspp-runtime /caminho/runtime-ppsspp.tar.gz \
  --output-dir /caminho/saidas \
  --work-dir /caminho/work-novo
```

Rodar por systemd-run/tmux para sobreviver à queda de SSH. A receita instala pacotes em chroot com policy-rc.d impedindo serviços, sem bind do /run do host. Não executar o instalador do App com destino /.

## Conteúdo

- BMO frontend/backend/launchers auditados;
- Chromium, Xorg, utilitários X11 e D-Bus;
- RetroArch e cores GBA/SNES, PPSSPP runtime pinado e Moonlight pinado;
- PulseAudio com user manager persistente para o socket esperado pelos launchers;
- firstboot automático antes dos dez serviços BMO;
- assistente Windows e configuração simples na FAT;
- TF2 opcional exFAT/FAT com EASYROMS, excluindo o dispositivo do sistema e sem formatar.

A fase 40 antiga continua validada em staging vazio. Só os arquivos resultantes são aplicados ao alvo; fstab e symlinks existentes são preservados. A fase 50 habilita as units específicas, sem exigir contagens globais da imagem.

## Primeiro boot

1. Gravar em cartão extra de 16 GB ou maior.
2. Rodar ABRIR-BMO.cmd na BOOT e escolher painel/rede/senha/SSH.
3. TF2 fora durante a configuração inicial.
4. Ligar; configurar automaticamente, mostrar resumo e abrir BMO.
5. Possível reboot para expandir cartão; depois desligar antes de reinserir TF2.

Não é necessário executar bmo install. Os pacotes já estão instalados. Pareamento de streaming continua sendo configuração pessoal, não pode ser embutido na imagem.

## Validação e limites

Antes da compressão: manifestos, executáveis, dependências PPSSPP, units/habilitação, firstboot, ausência de ROMs e credenciais. Saída inclui .img.xz, SHA256, manifesto e inventário de pacotes.

Testes de integração em fixture preservam fstab e serviço existente. Verificação de conteúdo e systemd offline não comprovam boot/hardware físico. O candidato só pode ser promovido após testar tela, gamepad, áudio, brilho, TF2, jogos, Moonlight e retorno ao BMO. Base original, main e cartão em produção permanecem preservados.
