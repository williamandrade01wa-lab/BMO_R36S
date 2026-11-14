# BMO Linux Base — captura da referência R36S

Esta fase existe para registrar o hardware e os componentes realmente necessários antes de gerar a imagem BMO Linux Base minimalista.

## Objetivo

Partir de uma imagem R36S funcional e levantar somente o que precisamos preservar:

```text
R36S funcional
   ↓
boot / U-Boot
kernel / DTB
ScreenFiles
input / gamepad
DRM / display
áudio
brilho
USB / OTG / HUB
Wi-Fi
systemd
pacotes essenciais
   ↓
BMO hardware baseline
   ↓
BMO Linux Base minimalista
```

## Regra de segurança

O relatório bruto é local. Ele pode conter identificadores do aparelho, nomes de interfaces e dados de logs do kernel.

Arquivos com o padrão abaixo são ignorados pelo Git:

```text
bmo-r36s-baseline-*.txt
```

Não publique o relatório bruto. Depois da análise, somente informações genéricas e necessárias ao hardware devem entrar no repositório público.

## Captura automática

No R36S, dentro do repositório BMO:

```bash
sudo bash scripts/capture-r36s-baseline.sh
```

Resultado esperado:

```text
BMO_BASELINE_CAPTURE_OK
Arquivo: .../bmo-r36s-baseline-AAAAMMDD-HHMMSS.txt
```

O script é somente leitura e coleta:

- versão do sistema e kernel;
- layout das partições;
- conteúdo estrutural da partição de boot;
- hashes de DTB/DTBO e arquivos de boot relevantes;
- ScreenFiles;
- configuração relevante do kernel;
- módulos carregados;
- Device Tree em runtime;
- DRM/display;
- backlight/brilho;
- dispositivos de input;
- USB/OTG e estado de energia;
- hardware de rede sem solicitar senhas;
- ALSA/áudio;
- bateria/temperatura;
- services/targets do systemd;
- pacotes ligados a desktop e hardware;
- regras udev relevantes;
- mensagens de kernel relacionadas a hardware.

## Mapeamento de botões

A captura automática identifica o dispositivo de input e suas capacidades, mas não substitui o teste físico botão por botão.

O mapeamento interativo será executado separadamente para registrar de forma deliberada:

```text
A / B / X / Y
L1 / R1 / L2 / R2
SELECT / START / FN
L3 / R3
D-pad
analógicos
volume
```

Nenhum mapeamento deve ser assumido apenas pelo número de `/dev/input/eventX`, pois esse número pode mudar entre boots ou builds.

## Critério para iniciar a compilação

A primeira BMO Linux Base só deve ser compilada depois que tivermos confirmado:

- qual bootloader/boot.ini preservar;
- qual DTB/DTBO é necessário;
- como ScreenFiles são aplicadas;
- dispositivo e códigos dos botões;
- driver da tela/DRM;
- caminho do backlight;
- placas/dispositivos ALSA;
- USB OTG e HUB;
- driver do adaptador Wi-Fi de referência;
- conjunto mínimo de serviços/pacotes.

A imagem final deverá ser desenhada como pública desde o início: nenhuma chave, token, senha ou dependência de repositório privado pode ser embutida nela.
