# BMO Light — instalação automática online

Decisão do usuário (2026-10-24): imagem pequena, sem Chromium/emuladores pré-instalados. Ao configurar rede pelo assistente BOOT e ligar, expandir SD e instalar automaticamente com progresso, depois abrir BMO.

## Fluxo

1. BOOT/ABRIR-BMO.cmd prepara painel, Wi-Fi, senha e SSH.
2. Serviço de firstboot configura o sistema; Armbian expande o cartão e reinicia se necessário.
3. bmo-light-install verifica payload/runtime, rede e espaço livre, instala apenas Depends e pacotes explícitos (--no-install-recommends), integra fonte auditada em staging e verifica runtime/units antes do kiosk.
4. Falha/rede ausente: status na tela e BOOT/BMO-INSTALACAO.txt, journal/log e tentativa automática em 60 s. Marcador install.done somente após verificações.
5. sudo bmo install permite iniciar uma tentativa. Sem chave/token Git do usuário ou credencial FTP na imagem.

Recomendado SD extra de 8 GB+, com TF2 fora durante todo primeiro boot. Pareamento Moonlight é pessoal.

## Conteúdo pequeno local

Interface/backend/scripts/configs/manifests acompanham o instalador para não depender do Git privado. Runtime PPSSPP validado (27.790.924 bytes compactados; SHA256 1af91efd8374a2c164e5f2ffa37b3d65980b825a207cbb09c688b2997088c5ad) acompanha a BOOT/BMO-RUN/PPSSPP.TGZ. Os pacotes grandes são baixados de repositórios APT no aparelho.

Fonte frontend/runtime mantém pins beta; sem reescrever componentes estáveis. Assets/fontes que o pacote RetroArch declara como Depends continuam necessários nessa receita. Não usar remoção arbitrária de bibliotecas nem force-depends.

## Engenharia no GitHub/PC

Workflow build-bmo-light.yml usa runner ARM64 e artifact Base9 pinado (run40118103143). Não recompila kernel, não usa Potato. Receita remove somente ferramentas de desenvolvimento de uma lista explícita, com simulação APT bloqueando remoções extras. Preserva kernel, bootloader, UUID/fstab, rede e firmware de hardware.

Após sanitizar/desmontar, minimize-image.sh aplica e2fsck/resize2fs, mantém 128 MiB de margem, zera blocos livres e corta somente o fim da imagem. Prefixo do bootloader é verificado. Partições/offsets de boot originais preservados nesta primeira Light. Expansão é independente e ocorre no cartão no primeiro boot.

CI valida fixture de redução com arquivo/UUID e guardas do instalador. Artifact core não é entregável pronto: falta injetar o runtime privado no PC, conferir hash/contrato e comprimir. Runtime/credenciais nunca entram no Git. A entrega final inclui runtime, checksum, manifesto e tamanho medido.

## Medições existentes

Ready beta1: raw12GiB, gzip2.016.381.902 bytes; root usado4.095.193.088 bytes (~3,81GiB). Base9 antes dos cortes: gzip430.645.444 bytes (~411MiB), raw2.386.558.976, root usado1.784.623.104 (~1,66GiB). Não anunciar previsão como tamanho final Light.

BMO interface/scripts<1MiB e PPSSPP expandido~59MiB; o restante é base, navegador, emuladores, gráficos/áudio, fontes e firmware. Instalar depois reduz download inicial, mas continua ocupando espaço no SD após instalar.

## FTP temporário

<ROUTER_FTP> /usb1_1_1: teste local do usuário de8MiB aprovado (leitura/gravação/SHA256/limpeza), upload3,14 e download3,12MiB/s. Manter autenticação; senha somente entrada local, não Git/imagem/log. Serve para arquivos compactados/checksums; não build. Espaço livre e limite acima4GB não medidos.

## Gate

R36S_REQUIRED=YES antes de considerar Light validada: boot/expansão/rede, progresso/retry, instalação completa, gamepad, áudio/volume/brilho, TF2, jogos, streaming e retorno. Ready beta1 e Base8/9 não provam esse novo fluxo.
