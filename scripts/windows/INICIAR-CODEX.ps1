[CmdletBinding()]
param(
    [string]$RepositoryPath,
    [ValidateSet('geral','visual','imagem','infra')][string]$Area='geral',
    [switch]$Refresh,
    [switch]$StartCodex,
    [switch]$NoClipboard,
    [switch]$SelfTest
)
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$script:RequiredDocs=@('AGENTS.md','docs/USER-REQUIREMENTS.md','docs/PROJECT-CONTINUITY.md','docs/ENVIRONMENT.md','docs/WORKLOG.md','docs/ROADMAP.md','docs/PROJECT-STRUCTURE.md','docs/CHECKPOINTS.md','docs/HANDOFF.md')

function Read-BmoGit([string]$Root,[string[]]$GitArgs){
    try{
        $lines=@(& git -C $Root @GitArgs 2>$null)
        if($LASTEXITCODE -ne 0){return $null}
        return ($lines -join [Environment]::NewLine).Trim()
    }catch{return $null}
}
function Get-BmoGitState([string]$Root,[switch]$SkipGit){
    $state=[ordered]@{is_git=$false;branch='sem checkout Git';head='nao confirmado';status='nao consultado'}
    if($SkipGit -or -not(Test-Path -LiteralPath (Join-Path $Root '.git')) -or -not(Get-Command git -ErrorAction SilentlyContinue)){return [pscustomobject]$state}
    $head=Read-BmoGit $Root @('rev-parse','HEAD')
    if($head){
        $state.is_git=$true;$state.head=$head
        $branch=Read-BmoGit $Root @('branch','--show-current')
        $state.branch=if($branch){$branch}else{'HEAD destacado'}
        $status=Read-BmoGit $Root @('status','--short')
        $state.status=if($status){$status}else{'working tree limpo'}
    }
    return [pscustomobject]$state
}
function New-BmoContext([string]$Root,[string]$Focus,[switch]$SkipGit){
    $resolved=[IO.Path]::GetFullPath($Root)
    foreach($name in $script:RequiredDocs){
        if(-not(Test-Path -LiteralPath (Join-Path $resolved $name) -PathType Leaf)){throw "Documento obrigatorio ausente: $name. Use um clone atualizado ou o pacote completo de contexto."}
    }
    $state=Get-BmoGitState $resolved -SkipGit:$SkipGit
    $ref=if($Focus -eq 'imagem'){'feat/bmo-linux-base-v1'}else{'main'}
    $folder=Join-Path $resolved '.bmo-context'
    [void][IO.Directory]::CreateDirectory($folder)
    $builder=[Text.StringBuilder]::new()
    [void]$builder.AppendLine('# Contexto local do BMO')
    [void]$builder.AppendLine('Snapshot auxiliar; os documentos versionados continuam sendo a fonte da verdade.')
    [void]$builder.AppendLine('UTC='+[DateTime]::UtcNow.ToString('o'))
    [void]$builder.AppendLine('Area='+$Focus)
    [void]$builder.AppendLine('Branch sugerida='+$ref)
    [void]$builder.AppendLine('Branch observada='+$state.branch)
    [void]$builder.AppendLine('HEAD observado='+$state.head)
    [void]$builder.AppendLine('Estado local='+$state.status)
    foreach($name in $script:RequiredDocs){
        $body=[IO.File]::ReadAllText((Join-Path $resolved $name))
        if($name -eq 'docs/WORKLOG.md'){
            $lines=$body -split '\r?\n'
            $body=($lines | Select-Object -Last 140) -join [Environment]::NewLine
            $body='Ultimas 140 linhas; consulte o arquivo completo para historico.'+[Environment]::NewLine+$body
        }
        [void]$builder.AppendLine();[void]$builder.AppendLine('## '+$name);[void]$builder.AppendLine($body)
    }
    $context=Join-Path $folder 'CONTEXTO-ATUAL.md'
    [IO.File]::WriteAllText($context,$builder.ToString(),[Text.UTF8Encoding]::new($false))
    $prompt=@"
Continue BMO R36S, repositorio williamandrade01wa-lab/BMO_R36S. Area: $Focus.
Leia AGENTS.md, docs/USER-REQUIREMENTS.md, PROJECT-CONTINUITY, ENVIRONMENT,
WORKLOG, ROADMAP, PROJECT-STRUCTURE, CHECKPOINTS e HANDOFF em docs.
Contexto local auxiliar: $context
Confirme Git/HEAD/CI e alteracoes locais antes de editar; branch de referencia: $ref.
Use checkout/branch isolado e preserve o trabalho de outras conversas.
O Git e a memoria permanente: registre cada etapa significativa antes de avancar,
atualize a continuidade da area sem apagar outras frentes e deixe proximo passo exato.
A PureLight v0.1.0-beta ja foi gerada/verificada; teste fisico pendente e sem Release.
Confira manifesto em docs/releases; nao repita build nem publique sem necessidade/autorizacao.
Priorize GitHub/PC e economize Potato. Nunca grave credenciais/ROMs/saves no Git.
Continue o ponto atual documentado ou a tarefa especifica que o usuario informar.
"@
    $promptPath=Join-Path $folder 'PROMPT-INICIAL.txt'
    [IO.File]::WriteAllText($promptPath,$prompt,[Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{Root=$resolved;Context=$context;PromptPath=$promptPath;Prompt=$prompt;Git=$state;Reference=$ref}
}
function Test-BmoInitializer{
    $root=Join-Path ([IO.Path]::GetTempPath()) ('BMO-context-test-'+[guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($root)
    foreach($name in $script:RequiredDocs){
        $path=Join-Path $root $name
        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path))
        [IO.File]::WriteAllText($path,'Documento publico '+$name,[Text.UTF8Encoding]::new($false))
    }
    [IO.File]::WriteAllText((Join-Path $root '.env'),'PRIVATE_SENTINEL_DO_NOT_INCLUDE')
    $result=New-BmoContext $root 'imagem' -SkipGit
    if(-not(Test-Path -LiteralPath $result.Context)){throw 'Context file missing'}
    if(-not(Test-Path -LiteralPath $result.PromptPath)){throw 'Prompt file missing'}
    $context=[IO.File]::ReadAllText($result.Context)
    foreach($name in $script:RequiredDocs){if(-not $context.Contains($name)){throw "Missing document: $name"}}
    if($context.Contains('PRIVATE_SENTINEL_DO_NOT_INCLUDE')){throw 'Private file leaked'}
    if($result.Reference -ne 'feat/bmo-linux-base-v1'){throw 'Wrong image reference'}
    if($result.Git.is_git){throw 'Unexpected Git state'}
    if(-not $result.Prompt.Contains('O Git e a memoria permanente')){throw 'Memory rule missing'}
    $visual=New-BmoContext $root 'visual' -SkipGit
    if($visual.Reference -ne 'main'){throw 'Wrong visual reference'}
    if(Get-Command git -ErrorAction SilentlyContinue){
        & git -C $root init -b main --quiet
        if($LASTEXITCODE -ne 0){throw 'Fixture Git init failed'}
        & git -C $root add -- AGENTS.md docs
        if($LASTEXITCODE -ne 0){throw 'Fixture Git add failed'}
        & git -C $root -c user.name=BmoTest -c user.email=bmo-test@example.invalid commit --quiet -m fixture
        if($LASTEXITCODE -ne 0){throw 'Fixture Git commit failed'}
        $gitResult=New-BmoContext $root 'geral'
        if(-not $gitResult.Git.is_git -or $gitResult.Git.branch -ne 'main'){throw 'Git discovery failed'}
        if($gitResult.Git.head -notmatch '^[0-9a-f]{40,64}$'){throw 'Git HEAD invalid'}
        if([IO.File]::ReadAllText($gitResult.Context).Contains('PRIVATE_SENTINEL_DO_NOT_INCLUDE')){throw 'Private content leaked with Git metadata'}
    }
    Remove-Item -LiteralPath (Join-Path $root 'docs/HANDOFF.md')
    $rejected=$false
    try{[void](New-BmoContext $root 'geral' -SkipGit)}catch{$rejected=$true}
    if(-not $rejected){throw 'Missing required document accepted'}
    Write-Output 'BMO_CODEX_INITIALIZER_SELFTEST_OK'
    Write-Output ('FIXTURE='+$root)
}
if($SelfTest){Test-BmoInitializer;return}
try{
    if(-not $RepositoryPath){$RepositoryPath=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))}
    if($Refresh){
        if(-not(Test-Path -LiteralPath (Join-Path $RepositoryPath '.git'))){throw '-Refresh exige um clone Git.'}
        & git -C $RepositoryPath fetch origin *> $null
        if($LASTEXITCODE -ne 0){throw 'Git fetch falhou. Confira autenticacao/conexao no PC; nenhum arquivo de trabalho foi trocado.'}
    }
    $result=New-BmoContext $RepositoryPath $Area
    Write-Host 'BMO / INICIAR CODEX'
    Write-Host ('Area: '+$Area+' | Branch sugerida: '+$result.Reference)
    Write-Host ('Branch local: '+$result.Git.branch)
    Write-Host ('Contexto: '+$result.Context)
    Write-Host ('Prompt: '+$result.PromptPath)
    if(-not $NoClipboard){
        try{Set-Clipboard -Value $result.Prompt;Write-Host 'Prompt copiado. Cole no novo chat com o projeto aberto.'}catch{Write-Host 'Clipboard indisponivel; abra PROMPT-INICIAL.txt e copie o conteudo.'}
    }
    if($StartCodex){
        if(-not $result.Git.is_git){throw 'Para abrir o CLI, use -RepositoryPath apontando para um clone Git atualizado. O contexto foi preparado normalmente.'}
        $command=Get-Command codex -ErrorAction SilentlyContinue
        if(-not $command){throw 'Codex CLI nao encontrado. O prompt esta pronto para usar no desktop.'}
        & $command.Source -C $result.Root --worktree $result.Prompt
        exit $LASTEXITCODE
    }
    Write-Host 'Para iniciar o CLI em worktree: INICIAR-CODEX.cmd -StartCodex -Area visual'
}catch{
    Write-Error ('Falha no inicializador BMO: '+$_.Exception.Message)
    exit 1
}
