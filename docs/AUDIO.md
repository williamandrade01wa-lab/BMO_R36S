# Áudio BMO — sons e comparação entre cartões

## Conteúdo preservado em 2026-10-25

Os 12 WAV foram copiados, sem conversão, de `/opt/bmo-sounds` do cartão original do usuário (R36S, SSH 192.168.1.28). O usuário confirmou que apertar os botões muda a carinha e reproduz o efeito correspondente. A confirmação se refere a esse uso real do BMO.

Os arquivos versionados ficam em `assets/sounds/`; o destino de instalação é `/opt/bmo-sounds/`. `SHA256SUMS` contém hashes individuais e `manifest.json` registra tamanho/formato de cada WAV. Total: **2183032 bytes (2,08 MiB)**. Todos os WAV têm PCM de 16 bits; o inventário preserva os parâmetros originais.

- `angry.wav`: 115244 bytes
- `error.wav`: 120044 bytes
- `happy.wav`: 120044 bytes
- `laugh.wav`: 115244 bytes
- `love.wav`: 134444 bytes
- `sad.wav`: 144044 bytes
- `shocked.wav`: 100844 bytes
- `sleep.wav`: 862550 bytes
- `success.wav`: 129644 bytes
- `talking.wav`: 110442 bytes
- `thinking.wav`: 134444 bytes
- `wink.wav`: 96044 bytes

O instalador sandbox `install/bmo-install.sh` verifica o manifest antes de copiar os sons. O instalador legado também copia e confere os arquivos. O builder Light inclui a pequena pasta no payload local, sem baixar esses efeitos de serviços externos nem instalar pacotes extras só para armazená-los. Os pacotes de áudio continuam sendo dependências do BMO.

## Comparação observada

| Item | Ready sem som relatado | Cartão original com sons das carinhas |
| --- | --- | --- |
| Kernel | 6.12.32-lts-rk3326 | 6.12.74-lts-rk3326 |
| Codec | rk817_int | rk817_int |
| DTB kernel | SHA fcd325ee957987c8c2fb68d3098594bc58a22fb93ed7c8febe399ce5a6527c98 | Idêntico |
| Painel DTBO | SHA 846ee139c96f0c121116234c63025b97cf3f4f947147e6761185ab965f4b77f3 | Idêntico |
| Headphones Jack | on sem fone | Também on sem fone |
| Playback Mux | HP inicial; SPK testado sem resolver | HP |
| PulseAudio | 17.0 | 17.0 |
| /opt/bmo-sounds | Pasta ausente | 12 WAV preservados |

O DT decompilado só difere nos endereços de initrd em `chosen`, não nas rotas de áudio. O indicador de fone não prova falha de detecção neste aparelho, pois o original funciona com o mesmo estado. Não inverter GPIO nem forçar SPK permanentemente com base nesse indicador.

Os testes remotos de voz (paplay) e success pela API não foram ouvidos pelo usuário nem no original. A API retornou ok, mas isso não comprova reprodução audível, pois apenas lança o player. Esses testes não permitem atribuir o problema ao kernel. O usuário confirma os sons das carinhas via botões físicos no original.

## Validação e próximo teste

Os 12 hashes locais coincidem com sha256sum no aparelho original; arquivos WAV e ZIP foram verificados. Três scripts alterados passaram bash -n sem execução no cartão original. Não foram alterados mixer, volume, kernel, DTB ou serviços do original para essa coleta; a única configuração foi o cadastro da chave SSH autorizado pelo usuário.

Falta aplicar os sons à Ready, retornar ao mesmo perfil HP do original e testar as carinhas com os botões físicos. Se continuar sem som, comparar os caminhos do player/API e só depois investigar kernel/driver. **R36S_REQUIRED=YES.** As imagens já geradas não recebem estes arquivos automaticamente; requerem patch no cartão ou nova montagem. Não declarar áudio da Ready/Light corrigido antes da confirmação física.

Baselines completos, somente para engenharia no PC: work/audio-comparison/ready-20261025 e original-20261025. Nenhuma senha/ROM foi incluída nos arquivos versionados.
