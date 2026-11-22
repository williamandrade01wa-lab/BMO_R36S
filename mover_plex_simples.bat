@echo off
set SRC=D:\Plex - FILMES
for /d %%D in ("%SRC%\*") do (
    echo Processando pasta: %%~nxD
    ssh potato "mkdir -p \"/srv/barracuda/midia/Filmes/%%~nxD\""
    for %%F in ("%%D\*") do (
        echo Copiando arquivo: %%~nxF
        scp -q "%%F" "potato:\"/srv/barracuda/midia/Filmes/%%~nxD/%%~nxF\""
    )
)
echo CONCLUIDO > C:\Users\Willi\mover_plex_done.txt
