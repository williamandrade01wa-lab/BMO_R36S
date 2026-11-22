
function Get-BmoScannedWifi{
     = @()
    try {
         = netsh wlan show networks 2>
        foreach( in ){
            if( -match '^\s*SSID\s+\d+\s*:\s*(.+)$'){
                 = [1].Trim()
                if( -and -not ( -contains )){  += @() }
            }
        }
    } catch {}
    return 
}
﻿[CmdletBinding()]
param([switch]$SelfTest,[switch]$SmokeTest,[string]$PreviewPath)
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'


$script:BmoLogPath=''
$script:BmoLogRootOverride=''
$script:BmoLogSecrets=@()
$script:BmoOperation='Inicializar'
$script:BmoOperationPath=''
function Protect-BmoLogText([string]$Text){
    foreach($secret in @($script:BmoLogSecrets | Where-Object {-not [string]::IsNullOrEmpty($_)} | Sort-Object Length -Descending)){
        $Text=$Text.Replace([string]$secret,'[REDACTED]')
    }
    return $Text
}
function Write-BmoDiagnostic([object]$Record,[string]$Step='unknown'){
    try{
        $ex=$Record.Exception
        while($null -ne $ex.InnerException){$ex=$ex.InnerException}
        $attrs='unavailable'
        if($script:BmoOperationPath){try{$attrs=[string](Get-Item -LiteralPath $script:BmoOperationPath -Force -ErrorAction Stop).Attributes}catch{}}
        $entry=[ordered]@{
            timestamp_utc=[DateTime]::UtcNow.ToString('o');product='Assistente de Preparacao BMO';version='0.2.2'
            step=$Step;operation=$script:BmoOperation;path=$script:BmoOperationPath;attributes=$attrs
            exception_type=$ex.GetType().FullName;hresult=('{0:X8}' -f $ex.HResult)
            message=[string]$ex.Message;category=[string]$Record.CategoryInfo.Category
            error_id=[string]$Record.FullyQualifiedErrorId;stack=[string]$Record.ScriptStackTrace
            powershell=[string]$PSVersionTable.PSVersion;os=[Environment]::OSVersion.VersionString
        }
        $text=Protect-BmoLogText ($entry | ConvertTo-Json -Compress -Depth 3)
        $dirs=@()
        if($script:BmoLogRootOverride){$dirs+=@($script:BmoLogRootOverride)}
        else{
            $local=[Environment]::GetFolderPath('LocalApplicationData')
            if($local){$dirs+=@(Join-Path $local 'BMO\Logs')}
            $dirs+=@((Join-Path $PSScriptRoot 'BMO-Logs'),(Join-Path ([IO.Path]::GetTempPath()) 'BMO-Logs'))
        }
        foreach($dir in $dirs){
            try{
                [void][IO.Directory]::CreateDirectory($dir)
                if(-not $script:BmoLogPath){$file=Join-Path $dir ('BMO-Assistente-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,6)+'.jsonl')}
                else{$file=$script:BmoLogPath}
                [IO.File]::AppendAllText($file,$text+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
                $script:BmoLogPath=$file;return $file
            }catch{$script:BmoLogPath=''}
        }
    }catch{}
    return ''
}
function Ensure-BmoDirectory([string]$Path){
    # New-Item -Force rejects existing drive roots on Windows PowerShell 5.1.
    if([IO.Directory]::Exists($Path)){return}
    [void][IO.Directory]::CreateDirectory($Path)
}
function Get-BmoSha256([string]$Path){
    # The FileHash cmdlet may be unavailable in the Windows PowerShell session.
    $stream=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
    $sha=[Security.Cryptography.SHA256]::Create()
    try{return [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','')}
    finally{$sha.Dispose();$stream.Dispose()}
}
function Test-BmoWritable([string]$Boot){
    $script:BmoOperation='Testar gravacao na BOOT'
    $probe=Join-Path $Boot ('.bmo-write-test-'+[guid]::NewGuid().ToString('N')+'.tmp')
    $script:BmoOperationPath=$probe;$stream=$null;$created=$false
    try{
        $stream=[IO.FileStream]::new($probe,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        $created=$true;$stream.WriteByte(0);$stream.Flush($true)
    }finally{
        if($null -ne $stream){$stream.Dispose()}
        if($created){Remove-Item -LiteralPath $probe -Force}
    }
}
trap{
    $log=Write-BmoDiagnostic $_ 'startup'
    [Console]::Error.WriteLine('Falha no Assistente BMO. Log: '+$log)
    exit 1
}

function Resolve-BmoBoot([string]$Path) {
    if([string]::IsNullOrWhiteSpace($Path)){throw 'Escolha a pasta BOOT do cartao.'}
    $root=[IO.Path]::GetFullPath($Path).TrimEnd('\')+'\'
    if(-not(Test-Path -LiteralPath $root -PathType Container)){throw 'A pasta escolhida nao existe.'}
    foreach($name in @('ScreenFiles','boot.ini')){
        if(-not(Test-Path -LiteralPath (Join-Path $root $name))){throw 'Escolha a BOOT que contem ScreenFiles e boot.ini.'}
    }
    foreach($path in @($root,(Join-Path $root 'ScreenFiles'))){
        if((Get-Item -LiteralPath $path).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Escolha pastas reais, nao atalhos.'}
    }
    return $root
}
function Get-BmoPanels([string]$Boot){
    $root=Resolve-BmoBoot $Boot
    $panels=@(Get-ChildItem -LiteralPath (Join-Path $root 'ScreenFiles') -Directory |
        Where-Object {-not($_.Attributes -band [IO.FileAttributes]::ReparsePoint)} | Sort-Object Name)
    if($panels.Count -eq 0){throw 'Nenhum painel encontrado em ScreenFiles.'}
    return $panels
}
function Assert-BmoLine([string]$Text,[string]$Label){
    if($Text.IndexOfAny([char[]]@([char]0,[char]10,[char]13)) -ge 0){throw "$Label precisa ficar em uma unica linha."}
    if($Text -cne $Text.Trim()){throw "$Label tem espacos no inicio/fim. Remova esses espacos para manter compatibilidade com a Base."}
}
function New-BmoConfig([hashtable]$Settings){
    $labels=@{SSID='Nome do Wi-Fi';WifiPassword='Senha do Wi-Fi';UserPassword='Senha do R36S'}
    foreach($key in @('SSID','WifiPassword','UserPassword')){Assert-BmoLine ([string]$Settings[$key]) $labels[$key]}
    if([string]::IsNullOrEmpty($Settings.UserPassword) -or $Settings.UserPassword -in @('__APPLIED__','CHANGE_ME')){throw 'Escolha uma senha para o R36S.'}
    if($Settings.SSH -and $Settings.UserPassword -eq 'r36s'){throw 'Para SSH, escolha uma senha diferente de r36s. Use Voltar para alterar.'}
    $wifi=$Settings.Mode -in @('wifi','open')
    if($wifi -and [string]::IsNullOrWhiteSpace($Settings.SSID)){throw 'Digite o nome do Wi-Fi.'}
    if($Settings.Mode -eq 'wifi'){
        $pw=[string]$Settings.WifiPassword
        if($pw -in @('__APPLIED__','CHANGE_ME')){throw 'Digite a senha real do Wi-Fi.'}
        if(-not(($pw.Length -ge 8 -and $pw.Length -le 63) -or $pw -match '^[0-9a-fA-F]{64}$')){
            throw 'A senha do Wi-Fi precisa ter 8 a 63 caracteres (ou 64 digitos hexadecimais).'
        }
    }
    if($Settings.Mode -notin @('wifi','open','cable','offline')){throw 'Escolha uma opcao de rede.'}
    $net=if($Settings.Mode -eq 'offline'){'no'}else{'yes'}
    $enabled=if($wifi){'yes'}else{'no'}
    $ssid=if($wifi){[string]$Settings.SSID}else{''}
    $psk=if($Settings.Mode -eq 'wifi'){[string]$Settings.WifiPassword}else{''}
    $security=if($Settings.Mode -eq 'open'){'open'}else{'wpa-psk'}
    $remote=if($Settings.SSH){'yes'}else{'no'}
    $lines=@(
        '# BMO - preparado pelo assistente do Windows',
        '# Valores literais: nao adicionar aspas.',
        '# TF2 de jogos fora durante todo o primeiro boot.',
        'USER_NAME=r36s',"USER_PASSWORD=$($Settings.UserPassword)",'ROOT_PASSWORD=LOCKED',
        'HOSTNAME=bmo-r36s','TIMEZONE=America/Sao_Paulo','LOCALE=pt_BR.UTF-8',
        "NETWORK_ENABLED=$net","WIFI_ENABLED=$enabled","WIFI_SSID=$ssid",
        "WIFI_SECURITY=$security","WIFI_PASSWORD=$psk",
        'WIFI_HIDDEN=no','WIFI_AUTOCONNECT=yes','WIFI_IPV4_MODE=dhcp',
        'WIFI_STATIC_ADDRESS=','WIFI_STATIC_GATEWAY=','WIFI_STATIC_DNS=',
        'WIRED_ENABLED=yes','WIRED_AUTOCONNECT=yes','WIRED_IPV4_MODE=dhcp',
        'WIRED_STATIC_ADDRESS=','WIRED_STATIC_GATEWAY=','WIRED_STATIC_DNS=',
        "SSH_ENABLED=$remote",'SSH_PASSWORD_AUTH=yes','SSH_PORT=22',
        'MDNS_ENABLED=yes','BMO_AUTO_INSTALL=no'
    )
    return ($lines -join [char]10)+[char]10
}
function Get-BmoCopyPlan([string]$Boot,[string]$PanelPath){
    $root=Resolve-BmoBoot $Boot
    $panel=[IO.Path]::GetFullPath($PanelPath).TrimEnd('\')
    if(-not [string]::Equals([IO.Path]::GetDirectoryName($panel),(Join-Path $root 'ScreenFiles'),[StringComparison]::OrdinalIgnoreCase)){
        throw 'Escolha um painel dentro de ScreenFiles deste cartao.'
    }
    if(-not(Test-Path -LiteralPath $panel -PathType Container)){throw 'A pasta do painel nao existe.'}
    $queue=[Collections.Generic.Queue[string]]::new();$queue.Enqueue($panel);$plan=@()
    while($queue.Count -gt 0){
        $dir=$queue.Dequeue()
        if((Get-Item -LiteralPath $dir).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Atalho nas ScreenFiles recusado.'}
        foreach($item in Get-ChildItem -LiteralPath $dir -Force){
            if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Atalho nas ScreenFiles recusado.'}
            if($item.PSIsContainer){$queue.Enqueue($item.FullName);continue}
            $relative=$item.FullName.Substring($panel.Length).TrimStart('\')
            if($relative -eq 'BMO-FIRSTBOOT.txt' -or $relative -like '.BMO-backup-*'){throw 'O painel contem nome reservado.'}
            $dest=[IO.Path]::GetFullPath((Join-Path $root $relative))
            if(-not $dest.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){throw 'Caminho fora da BOOT recusado.'}
            $check=$dest
            while($check.Length -ge $root.TrimEnd('\').Length){
                if((Test-Path -LiteralPath $check) -and ((Get-Item -LiteralPath $check).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Um destino usa atalho. Operacao recusada.'}
                $parent=[IO.Path]::GetDirectoryName($check)
                if([string]::IsNullOrEmpty($parent) -or $parent -eq $check){break}
                $check=$parent
            }
            $plan+=[pscustomobject]@{Source=$item.FullName;Dest=$dest;Relative=$relative}
        }
    }
    if($plan.Count -eq 0){throw 'A pasta do painel esta vazia.'}
    return $plan
}
function Write-BmoCard([string]$Boot,[string]$PanelPath,[hashtable]$Settings,[int]$TestFailAfter=-1){
    $script:BmoLogSecrets=@([string]$Settings.WifiPassword,[string]$Settings.UserPassword)
    $script:BmoOperation='Validar destino';$script:BmoOperationPath=$Boot
    $root=Resolve-BmoBoot $Boot;$config=New-BmoConfig $Settings
    $plan=@(Get-BmoCopyPlan $root $PanelPath);$configPath=Join-Path $root 'BMO-FIRSTBOOT.txt'
    if((Test-Path -LiteralPath $configPath) -and ((Get-Item -LiteralPath $configPath).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Configuracao usa atalho. Operacao recusada.'}
    Test-BmoWritable $root
    $backup=Join-Path $root ('.BMO-backup-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8))
    $script:BmoOperation='Criar backup';$script:BmoOperationPath=$backup
    [void](New-Item -ItemType Directory -Path $backup)
    $targets=@($plan | ForEach-Object {$_.Dest})+@($configPath);$saved=@()
    foreach($dest in $targets){
        $script:BmoOperation='Copiar arquivo para backup';$script:BmoOperationPath=$dest
        $relative=$dest.Substring($root.Length);$existed=Test-Path -LiteralPath $dest;$attributes=$null
        if($existed -and (Test-Path -LiteralPath $dest -PathType Container)){throw 'Um arquivo de destino e uma pasta. Nada foi alterado.'}
        $copy=Join-Path $backup $relative
        if($existed){
            $attributes=(Get-Item -LiteralPath $dest -Force).Attributes
            Ensure-BmoDirectory ([IO.Path]::GetDirectoryName($copy))
            Copy-Item -LiteralPath $dest -Destination $copy -Force
        }
        $saved+=[pscustomobject]@{Dest=$dest;Copy=$copy;Existed=$existed;Attributes=$attributes}
    }
    $temp=Join-Path $root ('.bmo-config-'+[guid]::NewGuid().ToString('N')+'.tmp')
    try{
        $count=0
        foreach($item in $plan){
            $script:BmoOperation='Copiar ScreenFile';$script:BmoOperationPath=$item.Dest
            Ensure-BmoDirectory ([IO.Path]::GetDirectoryName($item.Dest))
            Copy-Item -LiteralPath $item.Source -Destination $item.Dest -Force
            $script:BmoOperation='Conferir ScreenFile'
            if((Get-BmoSha256 $item.Source) -ne (Get-BmoSha256 $item.Dest)){throw 'Falha ao conferir uma ScreenFile.'}
            $count++
            if($TestFailAfter -ge 0 -and $count -ge $TestFailAfter){throw 'Falha simulada de recuperacao.'}
        }
        $script:BmoOperation='Criar configuracao temporaria';$script:BmoOperationPath=$temp
        [IO.File]::WriteAllText($temp,$config,[Text.UTF8Encoding]::new($false))
        $script:BmoOperation='Substituir BMO-FIRSTBOOT.txt';$script:BmoOperationPath=$configPath
        Copy-Item -LiteralPath $temp -Destination $configPath -Force
        $script:BmoOperation='Conferir BMO-FIRSTBOOT.txt'
        if((Get-BmoSha256 $temp) -ne (Get-BmoSha256 $configPath)){throw 'Falha ao conferir a configuracao.'}
        return [pscustomobject]@{Backup=$backup;Files=$plan.Count;Config=$configPath}
    }catch{
        $failure=$_;[void](Write-BmoDiagnostic $failure 'write-card')
        $restored=$true
        for($i=$saved.Count-1;$i -ge 0;$i--){
            try{
                $script:BmoOperation='Restaurar arquivo';$script:BmoOperationPath=$saved[$i].Dest
                if($saved[$i].Existed){
                    Copy-Item -LiteralPath $saved[$i].Copy -Destination $saved[$i].Dest -Force
                    [IO.File]::SetAttributes($saved[$i].Dest,$saved[$i].Attributes)
                }
                elseif(Test-Path -LiteralPath $saved[$i].Dest -PathType Leaf){Remove-Item -LiteralPath $saved[$i].Dest -Force}
            }catch{$restored=$false;[void](Write-BmoDiagnostic $_ 'rollback')}
        }
        $message=if($restored){'Falha ao preparar o cartao. Os arquivos anteriores foram restaurados. Use Abrir log para ver a causa.'}else{"Falha na gravacao e recuperacao incompleta. Confira o backup em $backup. Use Abrir log."}
        throw [InvalidOperationException]::new($message,$failure.Exception)
    }finally{
        if(Test-Path -LiteralPath $temp -PathType Leaf){
            try{Remove-Item -LiteralPath $temp -Force}catch{[void](Write-BmoDiagnostic $_ 'cleanup')}
        }
    }
}
function Test-BmoWizard{
    $root=Join-Path ([IO.Path]::GetTempPath()) ('BMO-wizard-test-'+[guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $root)
    $boot=Join-Path $root 'Cartao BOOT [teste]';$panel=Join-Path $boot 'ScreenFiles\Panel 4'
    [void](New-Item -ItemType Directory -Force -Path $panel)
    [IO.File]::WriteAllText((Join-Path $boot 'boot.ini'),'ORIGINAL_BOOT')
    [IO.File]::WriteAllText((Join-Path $boot 'BMO-FIRSTBOOT.txt'),'OLD_CONFIG')
    [IO.File]::WriteAllText((Join-Path $boot 'mipi-panel.dtbo'),'OLD_PANEL')
    [IO.File]::WriteAllText((Join-Path $panel 'mipi-panel.dtbo'),'NEW_PANEL')
    $script:BmoLogRootOverride=Join-Path $root 'logs'
    $s=@{Mode='wifi';SSID='Minha Rede #= exemplo';WifiPassword='senha$()#=123';UserPassword='senha teste';SSH=$true};$passed=0
    function Assert-Test($Ok,$Message){if(-not $Ok){throw "TEST FAILED: $Message"}}
    $hashFixture=Join-Path $root 'hash-abc.txt'
    [IO.File]::WriteAllText($hashFixture,'abc',[Text.Encoding]::ASCII)
    Assert-Test ((Get-BmoSha256 $hashFixture) -eq 'BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD') 'SHA256 without FileHash cmdlet';$passed++
    Assert-Test (@(Get-BmoPanels $boot).Count -eq 1) 'panel discovery';$passed++
    $config=New-BmoConfig $s
    Assert-Test ($config.Contains('WIFI_SSID=Minha Rede #= exemplo')) 'SSID literal';$passed++
    Assert-Test ($config.Contains('WIFI_PASSWORD=senha$()#=123')) 'password literal';$passed++
    Assert-Test (-not $config.Contains([string][char]13)) 'LF encoding';$passed++
    $rejected=$false;try{[void](Write-BmoCard $boot $panel $s -TestFailAfter 1)}catch{$rejected=$true}
    Assert-Test $rejected 'simulated failure';$passed++
    Assert-Test ([IO.File]::ReadAllText((Join-Path $boot 'mipi-panel.dtbo')) -eq 'OLD_PANEL') 'rollback panel';$passed++
    Assert-Test ([IO.File]::ReadAllText((Join-Path $boot 'BMO-FIRSTBOOT.txt')) -eq 'OLD_CONFIG') 'rollback config';$passed++
    $result=Write-BmoCard $boot $panel $s
    Assert-Test ([IO.File]::ReadAllText((Join-Path $panel 'mipi-panel.dtbo')) -eq 'NEW_PANEL') 'source preserved';$passed++
    Assert-Test ([IO.File]::ReadAllText((Join-Path $boot 'mipi-panel.dtbo')) -eq 'NEW_PANEL') 'panel copied';$passed++
    Assert-Test ([IO.File]::ReadAllText((Join-Path $boot 'boot.ini')) -eq 'ORIGINAL_BOOT') 'unrelated file preserved';$passed++
    Assert-Test ([IO.File]::ReadAllText((Join-Path $result.Backup 'BMO-FIRSTBOOT.txt')) -eq 'OLD_CONFIG') 'backup';$passed++
    $bytes=[IO.File]::ReadAllBytes($result.Config)
    Assert-Test (-not($bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191)) 'UTF8 no BOM';$passed++
    foreach($mode in @('open','cable','offline')){
        $m=$s.Clone();$m.Mode=$mode;$text=New-BmoConfig $m
        Assert-Test ($text.Contains('WIFI_PASSWORD='+[char]10)) 'unused password cleared'
        if($mode -eq 'offline'){Assert-Test ($text.Contains('NETWORK_ENABLED=no')) 'offline'}
        $passed++
    }
    $bad=$s.Clone();$bad.SSID='x'+[char]10+'USER_NAME=other'
    $rejected=$false;try{[void](New-BmoConfig $bad)}catch{$rejected=$true}
    Assert-Test $rejected 'newline rejected';$passed++
    $bad=$s.Clone();$bad.UserPassword='r36s';$rejected=$false;try{[void](New-BmoConfig $bad)}catch{$rejected=$true}
    Assert-Test $rejected 'SSH default password rejected';$passed++
    $rejected=$false;try{[void](Get-BmoCopyPlan $boot $root)}catch{$rejected=$true}
    Assert-Test $rejected 'outside panel rejected';$passed++
    $rejected=$false;try{[void](Resolve-BmoBoot $root)}catch{$rejected=$true}
    Assert-Test $rejected 'wrong BOOT rejected';$passed++
    $unicode=$s.Clone();$unicode.SSID='Rede Ação';$unicode.WifiPassword='abc\n#=123'
    $unicodeConfig=New-BmoConfig $unicode
    Assert-Test ($unicodeConfig.Contains('WIFI_SSID=Rede Ação')) 'Unicode SSID';$passed++
    Assert-Test ($unicodeConfig.Contains('WIFI_PASSWORD=abc\n#=123')) 'literal backslash n';$passed++
    $bad=$s.Clone();$bad.WifiPassword=' senha123 '
    $rejected=$false;try{[void](New-BmoConfig $bad)}catch{$rejected=$true}
    Assert-Test $rejected 'unsupported edge spaces rejected';$passed++
    $bad=$s.Clone();$bad.UserPassword='__APPLIED__'
    $rejected=$false;try{[void](New-BmoConfig $bad)}catch{$rejected=$true}
    Assert-Test $rejected 'reserved password rejected';$passed++
    [IO.File]::SetAttributes((Join-Path $boot 'BMO-FIRSTBOOT.txt'),[IO.FileAttributes]::ReadOnly)
    [void](Write-BmoCard $boot $panel $s)
    Assert-Test ([IO.File]::ReadAllText((Join-Path $boot 'BMO-FIRSTBOOT.txt')).Contains('USER_NAME=r36s')) 'readonly config replaced';$passed++
    $script:BmoLogSecrets=@($s.WifiPassword,$s.UserPassword)
    try{throw ('diagnostic '+$s.WifiPassword+' '+$s.UserPassword)}catch{$diagnostic=Write-BmoDiagnostic $_ 'selftest'}
    Assert-Test (Test-Path -LiteralPath $diagnostic) 'diagnostic saved';$passed++
    $logText=[IO.File]::ReadAllText($diagnostic)
    Assert-Test (-not $logText.Contains($s.WifiPassword) -and -not $logText.Contains($s.UserPassword)) 'diagnostic redacts secrets';$passed++
    Assert-Test ($logText.Contains('exception_type') -and $logText.Contains('operation')) 'diagnostic retains cause';$passed++
    $driveRoot=[IO.Path]::GetPathRoot($root)
    Ensure-BmoDirectory $driveRoot
    Assert-Test ([IO.Directory]::Exists($driveRoot)) 'existing drive root accepted';$passed++
    $nested=Join-Path $boot 'subfolder [literal]\child'
    Ensure-BmoDirectory $nested
    Assert-Test ([IO.Directory]::Exists($nested)) 'nested literal directory created';$passed++
    Ensure-BmoDirectory $nested
    Assert-Test ([IO.Directory]::Exists($nested)) 'existing directory idempotent';$passed++
    Write-Output "BMO_WIZARD_TESTS_OK=$passed"
    Write-Output "FIXTURE=$root"
}
if($SelfTest){Test-BmoWizard;return}
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$script:Wizard=@{State=@{Boot='';Panel='';Mode='wifi';SSID='';WifiPassword='';UserPassword='';SSH=$false};Step='boot';History=[Collections.Generic.List[string]]::new();Panels=@()}
$form=[Windows.Forms.Form]::new();$form.Text='BMO - Assistente de Preparacao'
$form.ClientSize=[Drawing.Size]::new(720,680);$form.StartPosition='CenterScreen';$form.FormBorderStyle='FixedDialog';$form.MaximizeBox=$false
$form.BackColor=[Drawing.Color]::FromArgb(18,25,34);$form.ForeColor=[Drawing.Color]::FromArgb(234,241,245);$form.Font=[Drawing.Font]::new('Segoe UI',10)
$title=[Windows.Forms.Label]::new();$title.Text='BMO  /  PREPARACAO DO CARTAO';$title.SetBounds(28,22,650,34);$title.Font=[Drawing.Font]::new('Segoe UI',20,[Drawing.FontStyle]::Bold);$form.Controls.Add($title)
$sub=[Windows.Forms.Label]::new();$sub.Text='Prepare o cartao com perguntas simples. Sem editar o TXT.';$sub.SetBounds(30,65,650,26);$form.Controls.Add($sub)
$chat=[Windows.Forms.TextBox]::new();$chat.Multiline=$true;$chat.ScrollBars='Vertical';$chat.WordWrap=$true;$chat.SetBounds(28,105,664,300);$chat.ReadOnly=$true;$chat.BorderStyle='None'
$chat.BackColor=[Drawing.Color]::FromArgb(27,37,49);$chat.ForeColor=$form.ForeColor;$chat.Font=[Drawing.Font]::new('Segoe UI',11);$form.Controls.Add($chat)
$prompt=[Windows.Forms.Label]::new();$prompt.SetBounds(28,424,664,51);$form.Controls.Add($prompt)
$field=[Windows.Forms.TextBox]::new();$field.SetBounds(28,482,520,30);$form.Controls.Add($field)
$choices=[Windows.Forms.ComboBox]::new();$choices.SetBounds(28,482,664,32);$choices.DropDownStyle='DropDownList';$choices.Visible=$false;$form.Controls.Add($choices)
$browse=[Windows.Forms.Button]::new();$browse.Text='Escolher BOOT...';$browse.SetBounds(558,480,134,34);$form.Controls.Add($browse)
$reveal=[Windows.Forms.CheckBox]::new();$reveal.Text='Mostrar senha';$reveal.SetBounds(28,521,180,26);$reveal.Visible=$false;$form.Controls.Add($reveal)
$errorLabel=[Windows.Forms.Label]::new();$errorLabel.SetBounds(28,550,664,44);$errorLabel.ForeColor=[Drawing.Color]::FromArgb(255,192,128);$form.Controls.Add($errorLabel)
$back=[Windows.Forms.Button]::new();$back.Text='Voltar';$back.SetBounds(28,610,100,40);$form.Controls.Add($back)
$openLog=[Windows.Forms.Button]::new();$openLog.Text='Abrir log';$openLog.SetBounds(145,610,110,40);$openLog.Visible=$false;$form.Controls.Add($openLog)
$openLog.Add_Click({if($script:BmoLogPath -and (Test-Path -LiteralPath $script:BmoLogPath)){Invoke-Item -LiteralPath $script:BmoLogPath}})
$next=[Windows.Forms.Button]::new();$next.Text='Continuar';$next.SetBounds(490,610,202,40);$next.BackColor=[Drawing.Color]::FromArgb(75,210,175);$next.ForeColor=[Drawing.Color]::FromArgb(12,31,29);$next.FlatStyle='Flat';$form.Controls.Add($next);$form.AcceptButton=$next
$script:Wizard.Ui=@{Form=$form;Chat=$chat;Prompt=$prompt;Field=$field;Choices=$choices;Browse=$browse;Reveal=$reveal;Error=$errorLabel;OpenLog=$openLog;Back=$back;Next=$next}
function Add-BmoChat([string]$Who,[string]$Text){
    $box=$script:Wizard.Ui.Chat;$nl=[Environment]::NewLine
    $box.AppendText($Who+$nl+$Text+$nl+$nl);$box.SelectionStart=$box.TextLength;$box.ScrollToCaret()
}
function Show-BmoStep([string]$Step){
    $w=$script:Wizard;$u=$w.Ui;$s=$w.State
    $w.Step=$Step;$u.Error.Text='';$u.Field.Visible=$true;$u.Field.ReadOnly=$false;$u.Reveal.Checked=$false;$u.Field.UseSystemPasswordChar=$false;$u.Reveal.Visible=$false
    $u.Choices.Visible=$false;$u.Choices.Items.Clear();$u.Browse.Visible=$false;$u.Next.Text='Continuar';$u.Back.Enabled=$w.History.Count -gt 0
    switch($Step){
        boot{$question='Onde esta a BOOT do cartao?';$hint='Escolha a pasta que contem ScreenFiles e boot.ini.';$u.Field.Text=$s.Boot;$u.Field.ReadOnly=$true;$u.Browse.Visible=$true}
        panel{
            $question='Qual ScreenFiles voce quer usar?';$hint='Escolha o painel que funciona na sua tela. O assistente nao adivinha o painel.'
            $u.Field.Visible=$false;$u.Choices.Visible=$true
            foreach($p in $w.Panels){[void]$u.Choices.Items.Add($p.Name)}
            $index=-1;for($i=0;$i -lt $w.Panels.Count;$i++){if($w.Panels[$i].FullName -eq $s.Panel){$index=$i}}
            $u.Choices.SelectedIndex=$index
        }
        network{
            $question='Como o R36S vai se conectar?';$hint='IP automatico. Para Wi-Fi, prefira 2,4 GHz; 5 GHz exige adaptador compativel.';$u.Field.Visible=$false;$u.Choices.Visible=$true
            foreach($label in @('Wi-Fi com senha','Wi-Fi sem senha (rede aberta)','Cabo / adaptador Ethernet USB','Sem rede por enquanto')){[void]$u.Choices.Items.Add($label)}
            $u.Choices.SelectedIndex=@('wifi','open','cable','offline').IndexOf($s.Mode)
        }
        ssid{$question='Qual e o nome do seu Wi-Fi?';$hint='Prefira uma rede de 2,4 GHz. Confira se o adaptador do R36S suporta 5 GHz. Digite o nome sem aspas.';$u.Field.Text=$s.SSID}
        wifiPass{$question='Qual e a senha desse Wi-Fi?';$hint='Sem aspas. Ela fica escondida e nao aparece no resumo.';$u.Field.Text=$s.WifiPassword;$u.Field.UseSystemPasswordChar=$true;$u.Reveal.Visible=$true}
        userPass{$question='Crie uma senha para entrar no R36S.';$hint='Guarde com voce. Para SSH, use uma senha diferente de r36s.';$u.Field.Text=$s.UserPassword;$u.Field.UseSystemPasswordChar=$true;$u.Reveal.Visible=$true}
        confirmPass{$question='Repita a senha do R36S.';$hint='Isso evita gravar uma senha digitada sem querer.';$u.Field.Text='';$u.Field.UseSystemPasswordChar=$true;$u.Reveal.Visible=$true}
        ssh{
            $question='Quer acessar pelo computador (SSH)?';$hint='O acesso usa o usuario r36s e a senha que voce escolheu.';$u.Field.Visible=$false;$u.Choices.Visible=$true
            [void]$u.Choices.Items.Add('Nao, manter desligado');[void]$u.Choices.Items.Add('Sim, habilitar SSH');$u.Choices.SelectedIndex=[int][bool]$s.SSH
        }
        review{
            $question='Tudo pronto para preparar o cartao?';$hint='Confira o resumo. So ao clicar em Preparar cartao os arquivos serao gravados.';$u.Field.Visible=$false;$u.Next.Text='Preparar cartao'
            $net=switch($s.Mode){wifi{'Wi-Fi com senha'}open{'Wi-Fi aberto'}cable{'Cabo / Ethernet'}offline{'Sem rede'}}
            $remote=if($s.SSH){'Ligado'}else{'Desligado'}
            Add-BmoChat 'RESUMO' (@("BOOT: $($s.Boot)","Tela: $(Split-Path -Leaf $s.Panel)","Rede: $net","Wi-Fi: $($s.SSID)","SSH: $remote",'Usuario: r36s','Senhas: escondidas','','As ScreenFiles serao COPIADAS. Originais preservados e backup dos destinos anteriores.') -join [Environment]::NewLine)
        }
        done{$question='Cartao preparado!';$hint='Remova com seguranca. Primeiro boot: TF1 conectado e TF2 de jogos FORA.';$u.Field.Visible=$false;$u.Back.Enabled=$false;$u.Next.Text='Fechar'}
    }
    $u.Prompt.Text=$question+[Environment]::NewLine+$hint;Add-BmoChat 'BMO' $question
    if($u.Field.Visible -and -not $u.Field.ReadOnly){[void]$u.Field.Focus()}
}
function Move-BmoStep([string]$Step,[string]$Answer){Add-BmoChat 'VOCE' $Answer;$script:Wizard.History.Add($script:Wizard.Step);Show-BmoStep $Step}
function Invoke-BmoNext{
    $w=$script:Wizard;$u=$w.Ui;$s=$w.State
    $script:BmoLogSecrets=@([string]$s.WifiPassword,[string]$s.UserPassword)
    if($w.Step -in @('wifiPass','userPass','confirmPass')){$script:BmoLogSecrets+=@($u.Field.Text)}
    $script:BmoOperation='Validar etapa';$script:BmoOperationPath=[string]$s.Boot
    try{
        switch($w.Step){
            boot{$root=Resolve-BmoBoot $u.Field.Text;if($root -ne $s.Boot){$s.Panel=''};$s.Boot=$root;$w.Panels=@(Get-BmoPanels $root)
                $statusFile=Join-Path $root 'BMO-STATUS.txt'
                if((Test-Path -LiteralPath $statusFile) -and ([IO.File]::ReadAllText($statusFile) -match '(?m)^FIRSTBOOT=OK')){Add-BmoChat 'BMO' 'Este cartao ja concluiu o primeiro boot. Salvar o TXT nao reaplica a configuracao automaticamente.'}
                Move-BmoStep panel $root}
            panel{
                if($u.Choices.SelectedIndex -lt 0){throw 'Escolha uma pasta de painel.'}
                $s.Panel=$w.Panels[$u.Choices.SelectedIndex].FullName;[void](Get-BmoCopyPlan $s.Boot $s.Panel)
                Move-BmoStep network (Split-Path -Leaf $s.Panel)
            }
            network{
                if($u.Choices.SelectedIndex -lt 0){throw 'Escolha uma opcao de rede.'}
                $s.Mode=@('wifi','open','cable','offline')[$u.Choices.SelectedIndex]
                if($s.Mode -in @('wifi','open')){Move-BmoStep ssid $u.Choices.Text}
                else{$s.SSID='';$s.WifiPassword='';Move-BmoStep userPass $u.Choices.Text}
            }
            ssid{
                Assert-BmoLine $u.Field.Text 'Nome do Wi-Fi'
                if([string]::IsNullOrWhiteSpace($u.Field.Text)){throw 'Digite o nome do Wi-Fi.'}
                $s.SSID=$u.Field.Text
                if($s.Mode -eq 'wifi'){Move-BmoStep wifiPass $s.SSID}else{$s.WifiPassword='';Move-BmoStep userPass $s.SSID}
            }
            wifiPass{
                $s.WifiPassword=$u.Field.Text;$validation=$s.Clone();$validation.UserPassword='validacao-temporaria';$validation.SSH=$false
                [void](New-BmoConfig $validation);Move-BmoStep userPass '(senha do Wi-Fi escondida)'
            }
            userPass{
                Assert-BmoLine $u.Field.Text 'Senha do R36S'
                if([string]::IsNullOrEmpty($u.Field.Text)){throw 'Digite a senha que deseja usar no R36S.'}
                $s.UserPassword=$u.Field.Text;Move-BmoStep confirmPass '(senha do R36S escondida)'
            }
            confirmPass{if($u.Field.Text -cne $s.UserPassword){throw 'As senhas nao sao iguais. Digite novamente.'};Move-BmoStep ssh '(senha confirmada)'}
            ssh{$s.SSH=$u.Choices.SelectedIndex -eq 1;[void](New-BmoConfig $s);Move-BmoStep review $u.Choices.Text}
            review{
                $u.Next.Enabled=$false;$u.Back.Enabled=$false
                try{$result=Write-BmoCard $s.Boot $s.Panel $s}finally{$u.Next.Enabled=$true;$u.Back.Enabled=$true}
                Add-BmoChat 'BMO' (@("ScreenFiles copiadas: $($result.Files)",'BMO-FIRSTBOOT.txt criado.',"Backup: $($result.Backup)",'','Nao e preciso colocar aspas nem editar o TXT.') -join [Environment]::NewLine)
                Show-BmoStep done
            }
            done{$u.Form.Close()}
        }
    }catch{
        $record=$_;$log=Write-BmoDiagnostic $record $w.Step
        $message=$record.Exception.Message
        if($record.Exception -is [UnauthorizedAccessException]){$message='Acesso negado ao cartao. Confira protecao contra gravacao, espaco e arquivos em uso.'}
        $u.Error.Text=$message
        if($log){$u.OpenLog.Visible=$true;Add-BmoChat 'BMO' ('Diagnostico salvo em: '+$log+' (sem senhas).')}
    }
}
$browse.Add_Click({
    $dialog=[Windows.Forms.FolderBrowserDialog]::new();$dialog.Description='Escolha a BOOT (ScreenFiles e boot.ini).';$dialog.ShowNewFolderButton=$false
    if($dialog.ShowDialog() -eq [Windows.Forms.DialogResult]::OK){$script:Wizard.Ui.Field.Text=$dialog.SelectedPath}
    $dialog.Dispose()
})
$reveal.Add_CheckedChanged({$script:Wizard.Ui.Field.UseSystemPasswordChar=-not $script:Wizard.Ui.Reveal.Checked})
$next.Add_Click({Invoke-BmoNext})
$back.Add_Click({$w=$script:Wizard;if($w.History.Count -gt 0){$last=$w.History.Count-1;$step=$w.History[$last];$w.History.RemoveAt($last);Show-BmoStep $step}})
$form.Add_FormClosed({$script:Wizard.State.UserPassword='';$script:Wizard.State.WifiPassword='';$script:Wizard.Ui.Field.Clear()})
Add-BmoChat 'BMO' 'Oi! Vou copiar as ScreenFiles e preencher a configuracao por voce. Use antes do primeiro boot. Nada sera gravado antes do resumo final.'
Show-BmoStep boot
if($SmokeTest){
    [void]$form.Show();[Windows.Forms.Application]::DoEvents()
    if($PreviewPath){
        $bitmap=[Drawing.Bitmap]::new($form.Width,$form.Height)
        $form.DrawToBitmap($bitmap,[Drawing.Rectangle]::new(0,0,$form.Width,$form.Height))
        $bitmap.Save([IO.Path]::GetFullPath($PreviewPath),[Drawing.Imaging.ImageFormat]::Png);$bitmap.Dispose()
    }
    $testRoot=Join-Path ([IO.Path]::GetTempPath()) ('BMO-ui-test-'+[guid]::NewGuid().ToString('N'))
    $testPanel=Join-Path $testRoot 'ScreenFiles\Panel 4'
    [void](New-Item -ItemType Directory -Force -Path $testPanel)
    [IO.File]::WriteAllText((Join-Path $testRoot 'boot.ini'),'BOOT')
    [IO.File]::WriteAllText((Join-Path $testPanel 'mipi-panel.dtbo'),'PANEL')
    function Assert-Ui([string]$Step){
        if($script:Wizard.Step -ne $Step -or $script:Wizard.Ui.Error.Text){
            throw "UI step failed: expected $Step; actual $($script:Wizard.Step); $($script:Wizard.Ui.Error.Text)"
        }
    }
    $field.Text=$testRoot;Invoke-BmoNext;Assert-Ui panel
    $choices.SelectedIndex=0;Invoke-BmoNext;Assert-Ui network
    $choices.SelectedIndex=0;Invoke-BmoNext;Assert-Ui ssid
    $field.Text='Rede de Exemplo';Invoke-BmoNext;Assert-Ui wifiPass
    if(-not $field.UseSystemPasswordChar){throw 'Wi-Fi password must be masked'}
    $reveal.Checked=$true
    $field.Text='senha-exemplo-123';Invoke-BmoNext;Assert-Ui userPass
    if(-not $field.UseSystemPasswordChar){throw 'Device password must be masked'}
    $field.Text='senha-r36s-exemplo';Invoke-BmoNext;Assert-Ui confirmPass
    $field.Text='senha-r36s-exemplo';Invoke-BmoNext;Assert-Ui ssh
    $choices.SelectedIndex=1;Invoke-BmoNext;Assert-Ui review
    if($chat.Text.Contains('senha-exemplo-123') -or $chat.Text.Contains('senha-r36s-exemplo')){throw 'Transcript leaked a password'}
    if(Test-Path -LiteralPath (Join-Path $testRoot 'BMO-FIRSTBOOT.txt')){throw 'Written before review confirmation'}
    Invoke-BmoNext;Assert-Ui done
    if(-not(Test-Path -LiteralPath (Join-Path $testRoot 'BMO-FIRSTBOOT.txt'))){throw 'No config after confirmation'}
    Write-Output 'BMO_WIZARD_UI_FLOW_OK: all steps, masked secrets, no early write, confirmed copy'

    Write-Output 'BMO_WIZARD_UI_CREATED_OK';$form.Dispose();return
}
[void]$form.ShowDialog();$form.Dispose()

