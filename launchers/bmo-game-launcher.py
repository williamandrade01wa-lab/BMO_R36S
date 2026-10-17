#!/usr/bin/env python3

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

# BMO_SD2_GBA_SNES_V1
# BMO_PSP_STANDALONE_V1

SYSTEMS = {
    # BMO_GBA_ZIP_V1
    "gba": {
        "name": "GAME BOY ADVANCE",

        "rom_dirs": [
            Path("/mnt/bmo-sd2/EASYROMS/gba"),
            Path("/home/r36s/ROMs/gba"),
        ],

        "extensions": {
            ".gba",
            ".zip"
        },

        "core": Path(
            "/usr/lib/aarch64-linux-gnu/libretro/mgba_libretro.so"
        ),
    },

    "snes": {
        "name": "SUPER NINTENDO",

        "rom_dirs": [
            Path("/mnt/bmo-sd2/EASYROMS/sfc"),
        ],

        "extensions": {
            ".sfc",
            ".smc"
        },

        "recursive": True,

        "core": Path(
            "/usr/lib/aarch64-linux-gnu/libretro/snes9x_libretro.so"
        ),
    },

    "psp": {
        "name": "PLAYSTATION PORTABLE",

        "rom_dirs": [
            Path("/mnt/bmo-sd2/EASYROMS/psp"),
        ],

        "extensions": {
            ".iso",
            ".cso",
            ".pbp"
        },

        # Para PSP este campo representa o executavel standalone.
        # Mantemos a chave para preservar resolve_game().
        "core": Path(
            "/opt/src/ppsspp/build-bmo/PPSSPPSDL"
        ),
    },
}

DISPLAY = ":0"
XAUTHORITY = "/home/r36s/.Xauthority"


def fail(message, code=1):
    print(json.dumps({
        "ok": False,
        "error": message,
    }, ensure_ascii=False))
    raise SystemExit(code)


def system_info(system_id):
    system = SYSTEMS.get(system_id)

    if not system:
        fail("Sistema nao permitido", 10)

    return system


# BMO_MULTI_ROM_DIR_V1
# BMO_RECURSIVE_ROMS_V1
# BMO_SNES_SFC_DIR_V1

def available_rom_dirs(system_id):
    """
    Retorna todos os diretorios disponiveis em ordem de prioridade.

    SD2 continua sendo o primeiro.
    Local funciona como fallback sem ser ocultado pelo SD2.
    """

    system = system_info(system_id)

    sd2_device = Path(
        "/dev/disk/by-uuid/1A31-13A4"
    )

    sd2_present = sd2_device.exists()

    result = []

    for rom_dir in system["rom_dirs"]:

        if (
            str(rom_dir).startswith("/mnt/bmo-sd2/")
            and
            not sd2_present
        ):
            continue

        try:
            if rom_dir.is_dir():
                result.append(rom_dir)
        except OSError:
            continue

    return result


def active_rom_dir(system_id):
    """
    Compatibilidade com codigo anterior.
    Retorna o primeiro diretorio disponivel.
    """

    dirs = available_rom_dirs(system_id)

    return dirs[0] if dirs else None


def list_games(system_id):
    system = system_info(system_id)

    recursive = bool(
        system.get("recursive", False)
    )

    games_by_file = {}

    for rom_dir in available_rom_dirs(system_id):

        try:
            iterator = (
                rom_dir.rglob("*")
                if recursive
                else rom_dir.iterdir()
            )

            for item in iterator:

                try:
                    if not item.is_file():
                        continue
                except OSError:
                    continue

                if (
                    item.suffix.lower()
                    not in system["extensions"]
                ):
                    continue

                try:
                    relative = (
                        item.relative_to(rom_dir)
                        .as_posix()
                    )
                except ValueError:
                    continue

                # Primeiro diretorio continua tendo prioridade.
                if relative in games_by_file:
                    continue

                try:
                    size = item.stat().st_size
                except OSError:
                    size = 0

                games_by_file[relative] = {
                    "id": relative,
                    "name": item.stem,
                    "file": relative,
                    "size": size,
                }

        except OSError:
            continue

    games = sorted(
        games_by_file.values(),
        key=lambda g: g["file"].casefold()
    )

    return {
        "ok": True,
        "system": system_id,
        "system_name": system["name"],
        "count": len(games),
        "games": games,
    }


def safe_relative_game_id(game_id):
    if not isinstance(game_id, str):
        fail("Nome de ROM invalido", 20)

    if not game_id:
        fail("Nome de ROM invalido", 20)

    if "\\" in game_id:
        fail("Nome de ROM invalido", 20)

    rel = Path(game_id)

    if rel.is_absolute():
        fail("Nome de ROM invalido", 20)

    if any(
        part in ("", ".", "..")
        for part in rel.parts
    ):
        fail("Nome de ROM invalido", 20)

    return rel


def resolve_game(system_id, game_id):
    system = system_info(system_id)

    rel = safe_relative_game_id(game_id)

    if (
        len(rel.parts) > 1
        and
        not system.get("recursive", False)
    ):
        fail(
            "Subdiretorio nao permitido para este sistema",
            20
        )

    if (
        rel.suffix.lower()
        not in system["extensions"]
    ):
        fail("Extensao de ROM nao permitida", 23)

    rom = None

    for rom_dir in available_rom_dirs(system_id):

        try:
            base = rom_dir.resolve()
            candidate = (base / rel).resolve()

            candidate.relative_to(base)

        except (OSError, ValueError):
            continue

        try:
            if candidate.is_file():
                rom = candidate
                break
        except OSError:
            continue

    if rom is None:
        fail("ROM nao encontrada", 22)

    runner = system["core"]

    if not runner.is_file():
        fail(
            "Core/executavel nao encontrado",
            24
        )

    return system, rom, runner


def dry_run(system_id, game_id):
    system, rom, runner = resolve_game(
        system_id,
        game_id
    )

    if system_id == "psp":
        command = [
            str(runner),
            str(rom),
        ]
        backend = "ppsspp"
    else:
        command = [
            "/usr/bin/retroarch",
            "-L",
            str(runner),
            str(rom),
        ]
        backend = "retroarch"

    return {
        "ok": True,
        "dry_run": True,
        "system": system_id,
        "system_name": system["name"],
        "rom": str(rom),
        "backend": backend,
        "core": str(runner),
        "command": command,
    }


# ============================================================
# BMO_GAME_SAVE_LAYERS_V1
# ============================================================

SD2_UUID_PATH = Path(
    "/dev/disk/by-uuid/1A31-13A4"
)

SD2_ROOT = Path(
    "/mnt/bmo-sd2/EASYROMS"
)

LOCAL_SAVE_ROOT = Path(
    "/home/r36s/.config/retroarch/saves"
)

LOCAL_STATE_ROOT = Path(
    "/home/r36s/.config/retroarch/states"
)


def sync_tree_newest(source, destination):
    """
    Copia arquivos ausentes ou mais novos.
    Nunca apaga arquivos do destino.
    """

    if not source.is_dir():
        return

    destination.mkdir(
        parents=True,
        exist_ok=True
    )

    for src in source.rglob("*"):

        if not src.is_file():
            continue

        relative = src.relative_to(source)

        dst = destination / relative

        dst.parent.mkdir(
            parents=True,
            exist_ok=True
        )

        copy = False

        if not dst.exists():
            copy = True

        else:
            try:
                if (
                    src.stat().st_mtime
                    >
                    dst.stat().st_mtime + 1
                ):
                    copy = True
            except OSError:
                pass

        if copy:

            import shutil

            shutil.copy2(
                src,
                dst
            )


def game_storage():
    """
    SD2 e primario quando o dispositivo realmente existe.

    Se estiver ausente ou der erro:
    armazenamento local.
    """

    local_saves = LOCAL_SAVE_ROOT
    local_states = LOCAL_STATE_ROOT

    local_saves.mkdir(
        parents=True,
        exist_ok=True
    )

    local_states.mkdir(
        parents=True,
        exist_ok=True
    )

    if not SD2_UUID_PATH.exists():

        return {
            "mode": "local",
            "saves": local_saves,
            "states": local_states,
        }

    try:

        sd_saves = (
            SD2_ROOT /
            "saves"
        )

        sd_states = (
            SD2_ROOT /
            "states"
        )

        sd_saves.mkdir(
            parents=True,
            exist_ok=True
        )

        sd_states.mkdir(
            parents=True,
            exist_ok=True
        )

        # Local -> SD2 antes de abrir o jogo.
        # Assim um save criado sem o cartao nao some
        # quando o SD2 volta.
        sync_tree_newest(
            local_saves,
            sd_saves
        )

        sync_tree_newest(
            local_states,
            sd_states
        )

        return {
            "mode": "sd2",
            "saves": sd_saves,
            "states": sd_states,
        }

    except OSError:

        return {
            "mode": "local",
            "saves": local_saves,
            "states": local_states,
        }


def write_runtime_config(storage):
    """
    Override temporario usado somente nesta execucao.
    Nao altera os diretorios permanentes do retroarch.cfg.
    """

    path = Path(
        f"/tmp/bmo-retroarch-{os.getpid()}.cfg"
    )

    content = (
        'savefile_directory = "'
        + str(storage["saves"])
        + '"\n'
        +
        'savestate_directory = "'
        + str(storage["states"])
        + '"\n'
    )

    path.write_text(content)

    return path



# ============================================================
# BMO_PSP_SAVE_LAYER_V1
# ============================================================

PSP_BIN = Path(
    "/opt/src/ppsspp/build-bmo/PPSSPPSDL"
)

PSP_BUILD_DIR = Path(
    "/opt/src/ppsspp/build-bmo"
)

PSP_LOCAL_ROOT = Path(
    "/home/r36s/.config/ppsspp/PSP"
)

PSP_LOCAL_SAVES = (
    PSP_LOCAL_ROOT /
    "SAVEDATA"
)

PSP_LOCAL_STATES = (
    PSP_LOCAL_ROOT /
    "PPSSPP_STATE"
)

PSP_SD_SAVES = (
    SD2_ROOT /
    "saves" /
    "psp" /
    "SAVEDATA"
)

PSP_SD_STATES = (
    SD2_ROOT /
    "states" /
    "psp" /
    "PPSSPP_STATE"
)


def psp_storage_prepare():
    """
    PPSSPP trabalha sempre no armazenamento local.

    Se SD2 estiver presente:
      SD2 -> local (recupera arquivos mais novos)
      local -> SD2 (completa o espelho)

    SYSTEM, configuracao, idioma e controles nao sao alterados.
    """

    PSP_LOCAL_SAVES.mkdir(
        parents=True,
        exist_ok=True
    )

    PSP_LOCAL_STATES.mkdir(
        parents=True,
        exist_ok=True
    )

    storage = {
        "mode": "local",
        "saves": PSP_LOCAL_SAVES,
        "states": PSP_LOCAL_STATES,
    }

    if not SD2_UUID_PATH.exists():
        return storage

    try:
        PSP_SD_SAVES.mkdir(
            parents=True,
            exist_ok=True
        )

        PSP_SD_STATES.mkdir(
            parents=True,
            exist_ok=True
        )

        # Recupera primeiro eventuais dados mais novos do SD2.
        sync_tree_newest(
            PSP_SD_SAVES,
            PSP_LOCAL_SAVES
        )

        sync_tree_newest(
            PSP_SD_STATES,
            PSP_LOCAL_STATES
        )

        # E garante que o SD2 possua tudo que existe localmente.
        sync_tree_newest(
            PSP_LOCAL_SAVES,
            PSP_SD_SAVES
        )

        sync_tree_newest(
            PSP_LOCAL_STATES,
            PSP_SD_STATES
        )

        storage["mode"] = "local+sd2"

    except OSError:
        pass

    return storage


def psp_storage_finish():
    """
    Depois do PPSSPP fechar, o local e a fonte ativa.
    Espelha novos saves/states para o SD2 quando disponivel.
    """

    if not SD2_UUID_PATH.exists():
        return

    try:
        PSP_SD_SAVES.mkdir(
            parents=True,
            exist_ok=True
        )

        PSP_SD_STATES.mkdir(
            parents=True,
            exist_ok=True
        )

        sync_tree_newest(
            PSP_LOCAL_SAVES,
            PSP_SD_SAVES
        )

        sync_tree_newest(
            PSP_LOCAL_STATES,
            PSP_SD_STATES
        )

    except OSError:
        pass


def launch_psp(system_id, game_id):
    system, rom, executable = resolve_game(
        system_id,
        game_id
    )

    if executable != PSP_BIN:
        fail("Executavel PSP invalido", 25)

    storage = psp_storage_prepare()

    env = os.environ.copy()
    env["DISPLAY"] = DISPLAY
    env["XAUTHORITY"] = XAUTHORITY
    env["HOME"] = "/home/r36s"
    env["USER"] = "r36s"
    env["LOGNAME"] = "r36s"
    env["XDG_RUNTIME_DIR"] = "/run/user/1000"
    env["PULSE_SERVER"] = (
        "unix:/run/user/1000/pulse/native"
    )

    kiosk_stopped = False
    cursor_proc = None
    hwkeys_proc = None

    try:
        subprocess.run(
            [
                "/usr/bin/systemctl",
                "stop",
                "bmo-kiosk.service"
            ],
            check=True,
        )

        kiosk_stopped = True
        time.sleep(2)

        check_x = subprocess.run(
            [
                "/usr/bin/systemctl",
                "is-active",
                "--quiet",
                "bmo-xorg.service"
            ]
        )

        if check_x.returncode != 0:
            raise RuntimeError(
                "Xorg nao esta ativo"
            )

        unclutter = Path("/usr/bin/unclutter")

        if unclutter.exists():
            cursor_proc = subprocess.Popen(
                [
                    str(unclutter),
                    "-idle",
                    "0.1",
                    "-root",
                ],
                env=env,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )

        # Mantem volume e FN+volume/brightness existentes.
        # Nao altera o mapeamento FN interno do PPSSPP.
        hwkeys_proc = subprocess.Popen(
            [
                "/usr/local/bin/bmo-game-hwkeys.py",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )

        command = [
            "/usr/sbin/runuser",
            "-u",
            "r36s",
            "--",
            "/usr/bin/env",
            f"DISPLAY={DISPLAY}",
            f"XAUTHORITY={XAUTHORITY}",
            "HOME=/home/r36s",
            "USER=r36s",
            "LOGNAME=r36s",
            "XDG_RUNTIME_DIR=/run/user/1000",
            "PULSE_SERVER=unix:/run/user/1000/pulse/native",
            str(PSP_BIN),
            str(rom),
        ]

        result = subprocess.run(
            command,
            cwd=str(PSP_BUILD_DIR)
        )

        return {
            "ok": result.returncode == 0,
            "system": system_id,
            "game": rom.name,
            "backend": "ppsspp",
            "ppsspp_rc": result.returncode,
            "storage": storage["mode"],
            "save_directory": str(
                PSP_LOCAL_SAVES
            ),
            "state_directory": str(
                PSP_LOCAL_STATES
            ),
        }

    finally:
        try:
            psp_storage_finish()
        except Exception:
            pass

        if hwkeys_proc:
            try:
                hwkeys_proc.terminate()
                hwkeys_proc.wait(timeout=2)
            except Exception:
                try:
                    hwkeys_proc.kill()
                except Exception:
                    pass

        if cursor_proc:
            try:
                cursor_proc.terminate()
                cursor_proc.wait(timeout=2)
            except Exception:
                try:
                    cursor_proc.kill()
                except Exception:
                    pass

        if kiosk_stopped:
            subprocess.run(
                [
                    "/usr/bin/systemctl",
                    "start",
                    "bmo-kiosk.service"
                ],
                check=False,
            )




def launch(system_id, game_id):
    if system_id == "psp":
        return launch_psp(system_id, game_id)

    system, rom, core = resolve_game(system_id, game_id)

    storage = game_storage()
    runtime_config = write_runtime_config(
        storage
    )

    env = os.environ.copy()
    env["DISPLAY"] = DISPLAY
    env["XAUTHORITY"] = XAUTHORITY
    env["HOME"] = "/home/r36s"
    env["USER"] = "r36s"
    env["LOGNAME"] = "r36s"

    kiosk_stopped = False
    cursor_proc = None
    hwkeys_proc = None

    try:
        # Somente o Chromium/BMO para.
        subprocess.run(
            ["/usr/bin/systemctl", "stop", "bmo-kiosk.service"],
            check=True,
        )

        kiosk_stopped = True
        time.sleep(2)

        # Xorg deve continuar vivo.
        check_x = subprocess.run(
            ["/usr/bin/systemctl", "is-active", "--quiet",
             "bmo-xorg.service"]
        )

        if check_x.returncode != 0:
            raise RuntimeError("Xorg nao esta ativo")

        # Esconde o cursor durante o jogo.
        unclutter = Path("/usr/bin/unclutter")

        if unclutter.exists():
            cursor_proc = subprocess.Popen(
                [
                    str(unclutter),
                    "-idle",
                    "0.1",
                    "-root",
                ],
                env=env,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )

        # Hotkeys fisicas durante o jogo.
        hwkeys_proc = subprocess.Popen(
            [
                "/usr/local/bin/bmo-game-hwkeys.py",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )

        # RetroArch executa como usuario r36s.
        command = [
            "/usr/sbin/runuser",
            "-u",
            "r36s",
            "--",
            "/usr/bin/env",
            f"DISPLAY={DISPLAY}",
            f"XAUTHORITY={XAUTHORITY}",
            "HOME=/home/r36s",
            "XDG_RUNTIME_DIR=/run/user/1000",
            "PULSE_SERVER=unix:/run/user/1000/pulse/native",
            "/usr/bin/retroarch",
            "-L",
            str(core),
            str(rom),
        ]

        result = subprocess.run(command)

        return {
            "ok": result.returncode == 0,
            "system": system_id,
            "game": rom.name,
            "retroarch_rc": result.returncode,
            "storage": storage["mode"],
            "save_directory": str(
                storage["saves"]
            ),
            "state_directory": str(
                storage["states"]
            ),
        }

    finally:

        try:

            if (
                "storage" in locals()
                and
                storage.get("mode") == "sd2"
            ):

                sync_tree_newest(
                    storage["saves"],
                    LOCAL_SAVE_ROOT
                )

                sync_tree_newest(
                    storage["states"],
                    LOCAL_STATE_ROOT
                )

        except Exception:
            pass


        try:

            if (
                "runtime_config" in locals()
                and
                runtime_config.exists()
            ):
                runtime_config.unlink()

        except Exception:
            pass


        if hwkeys_proc:
            try:
                hwkeys_proc.terminate()
                hwkeys_proc.wait(timeout=2)
            except Exception:
                try:
                    hwkeys_proc.kill()
                except Exception:
                    pass

        if cursor_proc:
            try:
                cursor_proc.terminate()
                cursor_proc.wait(timeout=2)
            except Exception:
                try:
                    cursor_proc.kill()
                except Exception:
                    pass

        if kiosk_stopped:
            subprocess.run(
                ["/usr/bin/systemctl", "start", "bmo-kiosk.service"],
                check=False,
            )


def main():
    parser = argparse.ArgumentParser(
        description="BMO native game launcher"
    )

    sub = parser.add_subparsers(
        dest="action",
        required=True
    )

    p_systems = sub.add_parser("systems")

    p_list = sub.add_parser("list")
    p_list.add_argument("system")

    p_dry = sub.add_parser("dry-run")
    p_dry.add_argument("system")
    p_dry.add_argument("game")

    p_launch = sub.add_parser("launch")
    p_launch.add_argument("system")
    p_launch.add_argument("game")

    args = parser.parse_args()

    if args.action == "systems":
        print(json.dumps({
            "ok": True,
            "systems": [
                {
                    "id": system_id,
                    "name": data["name"],
                }
                for system_id, data in SYSTEMS.items()
            ]
        }, ensure_ascii=False, indent=2))
        return

    if args.action == "list":
        print(json.dumps(
            list_games(args.system),
            ensure_ascii=False,
            indent=2
        ))
        return

    if args.action == "dry-run":
        print(json.dumps(
            dry_run(args.system, args.game),
            ensure_ascii=False,
            indent=2
        ))
        return

    if args.action == "launch":
        result = launch(
            args.system,
            args.game
        )

        print(json.dumps(
            result,
            ensure_ascii=False,
            indent=2
        ))

        raise SystemExit(
            0 if result["ok"] else 30
        )


if __name__ == "__main__":
    main()
