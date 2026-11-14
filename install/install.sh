#!/usr/bin/env bash

# BMO_INSTALLER_V1
# Pure -> BMO complete installation

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

ROOT="$(
    cd "$(dirname "${BASH_SOURCE[0]}")/.." &&
    pwd
)"

INSTALL_DIR="$ROOT/install"
RUNTIME_DIR="$INSTALL_DIR/runtime"

PP_ARCHIVE="$RUNTIME_DIR/BMO-PPSSPP-R36S-v1.20.4-runtime.tar.gz"
ML_DEB="$RUNTIME_DIR/moonlight-qt_6.2.0-1_arm64.deb"
SUMS="$RUNTIME_DIR/SHA256SUMS"


PP_BIN="/opt/src/ppsspp/build-bmo/PPSSPPSDL"

EXPECTED_PP_BIN_SHA="a69d28a61ef9da9aad675740ec96eade4a1240ffac5be79651f02457f686bba8"

CONFIG_DIR="/etc/bmo"
CONFIG="$CONFIG_DIR/bmo.conf"
VERSION_FILE="$CONFIG_DIR/version.env"

BMO_REPO_DIR="/var/lib/bmo/repo"


die() {
    echo "ERRO: $*" >&2
    exit 1
}


banner() {

    echo
    echo "============================================================"
    echo " $*"
    echo "============================================================"
}


require_root() {

    [ "$EUID" -eq 0 ] ||
        die "execute com sudo/root"
}


git_source() {

    git \
        -c safe.directory="$ROOT" \
        -C "$ROOT" \
        "$@"
}


normalize_github_origin() {

    local origin="$1"

    case "$origin" in

        git@github.com:*)
            printf '%s\n' "$origin"
            ;;

        ssh://git@github.com/*)
            printf '%s\n' "$origin"
            ;;

        https://github.com/*)
            local path

            path="${origin#https://github.com/}"

            printf 'git@github.com:%s\n' "$path"
            ;;

        github-bmo:*)
            printf 'git@github.com:%s\n' \
                "${origin#github-bmo:}"
            ;;

        *)
            printf '%s\n' ""
            ;;

    esac
}


install_packages() {

    banner "BMO INSTALL - PACKAGES"

    apt-get update

    apt-get install \
        -y \
        --no-install-recommends \
        ca-certificates \
        sudo \
        git \
        openssh-client \
        python3 \
        network-manager \
        iproute2 \
        rfkill \
        alsa-utils \
        bluez \
        xserver-xorg-core \
        xinit \
        x11-utils \
        x11-xserver-utils \
        dbus-x11 \
        unclutter \
        chromium \
        retroarch \
        libretro-mgba \
        libretro-snes9x \
        libglew2.2 \
        libopengl0 \
        libsdl2-2.0-0 \
        libsdl2-ttf-2.0-0 \
        libxss1

    echo "PACKAGES_OK"
}


ensure_user() {

    banner "BMO INSTALL - USER"

    if ! id r36s >/dev/null 2>&1; then

        if getent passwd 1000 >/dev/null 2>&1; then

            die \
                "UID 1000 ja pertence a outro usuario; instalacao nao sera automatizada"

        fi

        useradd \
            --uid 1000 \
            --create-home \
            --shell /bin/bash \
            r36s
    fi


    R36S_UID="$(
        id -u r36s
    )"

    [ "$R36S_UID" = "1000" ] ||
        die "usuario r36s precisa usar UID 1000; atual=$R36S_UID"


    for group in \
        tty \
        disk \
        dialout \
        sudo \
        audio \
        video \
        plugdev \
        games \
        users \
        systemd-journal \
        input \
        render \
        netdev \
        bluetooth
    do

        if getent group "$group" >/dev/null 2>&1; then

            usermod \
                -aG "$group" \
                r36s

        fi

    done


    install \
        -d \
        -o r36s \
        -g r36s \
        -m 0755 \
        /home/r36s/ROMs/gba \
        /home/r36s/ROMs/snes \
        /home/r36s/ROMs/psp \
        /home/r36s/.config/retroarch/saves \
        /home/r36s/.config/retroarch/states \
        /home/r36s/.config/ppsspp/PSP/SAVEDATA \
        /home/r36s/.config/ppsspp/PSP/PPSSPP_STATE \
        /home/r36s/.config/bmo


    echo "R36S_USER_OK"
}


verify_runtime_files() {

    banner "BMO INSTALL - RUNTIME VERIFY"

    [ -f "$PP_ARCHIVE" ] ||
        die "PPSSPP runtime ausente"

    [ -f "$ML_DEB" ] ||
        die "Moonlight runtime ausente"

    [ -f "$SUMS" ] ||
        die "SHA256SUMS ausente"


    (
        cd "$RUNTIME_DIR"
        sha256sum -c SHA256SUMS
    )


    echo "RUNTIME_HASHES_OK"
}


install_moonlight() {

    banner "BMO INSTALL - MOONLIGHT"

    apt-get install \
        -y \
        --no-install-recommends \
        "$ML_DEB"


    command -v moonlight-qt >/dev/null 2>&1 ||
        die "moonlight-qt nao foi instalado"


    echo "MOONLIGHT_VERSION=$(
        dpkg-query \
            -W \
            -f='${Version}' \
            moonlight-qt
    )"

    echo "MOONLIGHT_OK"
}


install_ppsspp() {

    banner "BMO INSTALL - PPSSPP"

    local tmp
    local src_bin
    local src_dir
    local new_dir

    tmp="$(
        mktemp -d
    )"

    trap 'rm -rf "$tmp"' RETURN


    python3 - \
        "$PP_ARCHIVE" <<'PY'
import sys
import tarfile
from pathlib import PurePosixPath

archive = sys.argv[1]

with tarfile.open(archive, "r:gz") as tar:

    for member in tar.getmembers():

        path = PurePosixPath(member.name)

        if path.is_absolute():
            raise SystemExit(
                f"path absoluto proibido: {member.name}"
            )

        if ".." in path.parts:
            raise SystemExit(
                f"path traversal proibido: {member.name}"
            )
PY


    tar \
        -xzf "$PP_ARCHIVE" \
        -C "$tmp"


    src_bin="$(
        find "$tmp" \
            -type f \
            -name PPSSPPSDL \
            -print \
            -quit
    )"


    [ -n "$src_bin" ] ||
        die "PPSSPPSDL nao encontrado no runtime"


    [ "$(
        sha256sum "$src_bin" |
        awk '{print $1}'
    )" = "$EXPECTED_PP_BIN_SHA" ] ||
        die "hash interno do PPSSPP invalido"


    src_dir="$(
        dirname "$src_bin"
    )"


    install \
        -d \
        -o root \
        -g root \
        -m 0755 \
        /opt/src/ppsspp


    new_dir="/opt/src/ppsspp/build-bmo.new"

    rm -rf "$new_dir"

    mkdir -p "$new_dir"

    cp -a \
        "$src_dir"/. \
        "$new_dir"/


    chown -R \
        root:root \
        "$new_dir"


    rm -rf \
        /opt/src/ppsspp/build-bmo

    mv \
        "$new_dir" \
        /opt/src/ppsspp/build-bmo


    chmod 0755 \
        "$PP_BIN"


    [ "$(
        sha256sum "$PP_BIN" |
        awk '{print $1}'
    )" = "$EXPECTED_PP_BIN_SHA" ] ||
        die "PPSSPP instalado possui hash incorreto"


    rm -rf "$tmp"
    trap - RETURN


    echo "PPSSPP_OK"
}


apply_bmo() {

    banner "BMO INSTALL - CORE"

    #
    # O instalador principal e o unico caminho autorizado para
    # instalacao real. As antigas phases Ready continuam sendo
    # ferramentas de build/sandbox e nao sao chamadas aqui.
    #

    install \
        -d \
        -o root \
        -g root \
        -m 0755 \
        /opt/bmo-ui \
        /usr/local/bin \
        /usr/local/sbin \
        /etc/default \
        /etc/udev/rules.d \
        /etc/systemd/system


    # --------------------------------------------------------
    # Frontend
    # --------------------------------------------------------

    install \
        -o root \
        -g root \
        -m 0644 \
        "$ROOT/frontend/index.html" \
        /opt/bmo-ui/index.html

    install \
        -o root \
        -g root \
        -m 0644 \
        "$ROOT/frontend/index.bmo-next.html" \
        /opt/bmo-ui/index.bmo-next.html


    cmp -s \
        /opt/bmo-ui/index.html \
        /opt/bmo-ui/index.bmo-next.html \
        || die "production e candidate divergiram"


    (
        cd "$ROOT/assets/sounds"
        sha256sum -c SHA256SUMS
    )
    local sound
    for sound in angry.wav error.wav happy.wav laugh.wav love.wav sad.wav shocked.wav sleep.wav success.wav talking.wav thinking.wav wink.wav; do
        install -D -o root -g root -m 0644 \
            "$ROOT/assets/sounds/$sound" "/opt/bmo-sounds/$sound"
        cmp -s "$ROOT/assets/sounds/$sound" "/opt/bmo-sounds/$sound" || die "som instalado divergente: $sound"
    done


    # --------------------------------------------------------
    # Runtime executavel
    # --------------------------------------------------------

    local root_files=(
        "backend/bmo-control-api.py|/usr/local/bin/bmo-control-api.py|0755"

        "launchers/bmo-game-launcher.py|/usr/local/bin/bmo-game-launcher.py|0755"
        "launchers/bmo-kiosk.sh|/usr/local/bin/bmo-kiosk.sh|0755"
        "launchers/bmo-moonlight-hotkeys.py|/usr/local/bin/bmo-moonlight-hotkeys.py|0755"
        "launchers/bmo-moonlight-launch.sh|/usr/local/bin/bmo-moonlight-launch.sh|0755"

        "scripts/runtime/bmo-game-hwkeys.py|/usr/local/bin/bmo-game-hwkeys.py|0755"
        "scripts/runtime/bmo-x-init.sh|/usr/local/bin/bmo-x-init.sh|0755"
        "scripts/runtime/bmo-usb-ip-watch.sh|/usr/local/bin/bmo-usb-ip-watch.sh|0755"
        "scripts/runtime/bmo-usb-swap-screen.sh|/usr/local/bin/bmo-usb-swap-screen.sh|0755"
        "scripts/runtime/bmo-usb-tether-auto.sh|/usr/local/bin/bmo-usb-tether-auto.sh|0755"

        "scripts/runtime/r36s-battery-api.py|/usr/local/bin/r36s-battery-api.py|0755"
        "scripts/runtime/r36s-sound-api.py|/usr/local/bin/r36s-sound-api.py|0755"
        "scripts/runtime/r36s-status-api.py|/usr/local/bin/r36s-status-api.py|0755"

        "deploy/r36s/bmo-deploy-helper|/usr/local/sbin/bmo-deploy-helper|0755"
        "deploy/r36s/bmo-kiosk.default|/etc/default/bmo-kiosk|0644"

        "install/system/chromium/bmo-kiosk.json|/etc/chromium/policies/managed/bmo-kiosk.json|0644"
        "install/system/udev/99-bmo-usb-power.rules|/etc/udev/rules.d/99-bmo-usb-power.rules|0644"
    )


    local item
    local src
    local dst
    local mode

    for item in "${root_files[@]}"; do

        IFS='|' read -r src dst mode <<< "$item"

        [ -f "$ROOT/$src" ] ||
            die "fonte ausente: $src"

        install \
            -D \
            -o root \
            -g root \
            -m "$mode" \
            "$ROOT/$src" \
            "$dst"

        cmp -s \
            "$ROOT/$src" \
            "$dst" \
            || die "copia divergente: $dst"

        echo "INSTALLED=$dst"

    done


    # --------------------------------------------------------
    # Sudo deploy helper
    # --------------------------------------------------------

    visudo \
        -cf \
        "$ROOT/deploy/r36s/bmo-deploy.sudoers" \
        >/dev/null

    install \
        -o root \
        -g root \
        -m 0440 \
        "$ROOT/deploy/r36s/bmo-deploy.sudoers" \
        /etc/sudoers.d/bmo-deploy

    visudo \
        -cf \
        /etc/sudoers.d/bmo-deploy \
        >/dev/null


    # --------------------------------------------------------
    # Config RetroArch / PPSSPP
    # --------------------------------------------------------

    install \
        -d \
        -o r36s \
        -g r36s \
        -m 0755 \
        /home/r36s/.config/retroarch \
        /home/r36s/.config/retroarch/config \
        /home/r36s/.config/retroarch/config/mGBA \
        /home/r36s/.config/ppsspp \
        /home/r36s/.config/ppsspp/PSP \
        /home/r36s/.config/ppsspp/PSP/SYSTEM


    local user_files=(
        "configs/retroarch/retroarch.cfg|/home/r36s/.config/retroarch/retroarch.cfg"
        "configs/retroarch/config/mGBA/mGBA.opt|/home/r36s/.config/retroarch/config/mGBA/mGBA.opt"

        "configs/ppsspp/PSP/SYSTEM/controls.ini|/home/r36s/.config/ppsspp/PSP/SYSTEM/controls.ini"
        "configs/ppsspp/PSP/SYSTEM/ppsspp.ini|/home/r36s/.config/ppsspp/PSP/SYSTEM/ppsspp.ini"
    )


    for item in "${user_files[@]}"; do

        IFS='|' read -r src dst <<< "$item"

        [ -f "$ROOT/$src" ] ||
            die "fonte ausente: $src"

        install \
            -D \
            -o r36s \
            -g r36s \
            -m 0644 \
            "$ROOT/$src" \
            "$dst"

        cmp -s \
            "$ROOT/$src" \
            "$dst" \
            || die "config divergente: $dst"

        echo "CONFIG_INSTALLED=$dst"

    done


    # --------------------------------------------------------
    # Systemd
    # --------------------------------------------------------

    local units=(
        bmo-control-api.service
        bmo-kiosk.service
        bmo-ui.service

        bmo-usb-ip-watch.service
        bmo-usb-swap-screen.service
        bmo-usb-tether-auto.service

        bmo-vt.service
        bmo-x-init.service
        bmo-xorg.service

        r36s-battery-api.service
        r36s-console.service
        r36s-sound-api.service
        r36s-status-api.service
    )


    local unit

    for unit in "${units[@]}"; do

        [ -f "$ROOT/systemd/$unit" ] ||
            die "unit fonte ausente: $unit"

        install \
            -o root \
            -g root \
            -m 0644 \
            "$ROOT/systemd/$unit" \
            "/etc/systemd/system/$unit"

        echo "UNIT_INSTALLED=$unit"

    done


    #
    # Nao alteramos /boot, kernel, DTB, bootloader,
    # Xorg da Pure ou /etc/fstab.
    #

    echo "PURE_BOOT_UNTOUCHED=YES"
    echo "PURE_FSTAB_UNTOUCHED=YES"
    echo "BMO_CORE_INSTALL_OK"
}

install_management() {

    banner "BMO INSTALL - MANAGEMENT"

    install \
        -o root \
        -g root \
        -m 0755 \
        "$INSTALL_DIR/bin/bmo" \
        /usr/local/bin/bmo


    install \
        -o root \
        -g root \
        -m 0755 \
        "$INSTALL_DIR/sbin/bmo-maintenance" \
        /usr/local/sbin/bmo-maintenance


    install \
        -o root \
        -g root \
        -m 0755 \
        "$INSTALL_DIR/sbin/bmo-runtime-config" \
        /usr/local/sbin/bmo-runtime-config


    install \
        -o root \
        -g root \
        -m 0755 \
        "$ROOT/launchers/bmo-moonlight-launch.sh" \
        /usr/local/bin/bmo-moonlight-launch.sh


    install \
        -o root \
        -g root \
        -m 0755 \
        "$ROOT/launchers/bmo-game-launcher.py" \
        /usr/local/bin/bmo-game-launcher.py


    visudo \
        -cf \
        "$INSTALL_DIR/sudoers/bmo-maintenance"


    install \
        -o root \
        -g root \
        -m 0440 \
        "$INSTALL_DIR/sudoers/bmo-maintenance" \
        /etc/sudoers.d/bmo-maintenance


    echo "MANAGEMENT_OK"
}


configure_device() {

    banner "BMO INSTALL - LOCAL CONFIG"

    install \
        -d \
        -o root \
        -g root \
        -m 0700 \
        "$CONFIG_DIR"


    local branch
    local commit
    local origin
    local repo_url

    commit="$(
        git_source rev-parse HEAD
    )"

    branch="$(
        git_source branch --show-current
    )"

    [ -n "$branch" ] ||
        branch="main"


    origin="$(
        git_source \
            config \
            --get remote.origin.url \
            || true
    )"


    repo_url="$(
        normalize_github_origin "$origin"
    )"


    if [ ! -f "$CONFIG" ]; then

        cat > "$CONFIG" <<EOF
# BMO device-local configuration
# Gerado pelo instalador.
# Nao e versionado.

BMO_REPO_URL=$repo_url
BMO_BRANCH=$branch
BMO_CHANNEL=stable

BMO_REPO_DIR=/var/lib/bmo/repo
BMO_GIT_KEY=/etc/bmo/github_deploy_key

BMO_MOONLIGHT_HOST=
BMO_HUB_EVENTS_URL=
EOF

        chown root:root "$CONFIG"
        chmod 0600 "$CONFIG"

    fi


    /usr/local/sbin/bmo-runtime-config


    echo "DEVICE_CONFIG_OK"
}


prepare_update_repo() {

    banner "BMO INSTALL - UPDATE REPOSITORY"

    local commit
    local origin
    local repo_url
    local tmp_repo

    commit="$(
        git_source rev-parse HEAD
    )"

    origin="$(
        git_source \
            config \
            --get remote.origin.url \
            || true
    )"

    repo_url="$(
        normalize_github_origin "$origin"
    )"


    install \
        -d \
        -o root \
        -g root \
        -m 0700 \
        /var/lib/bmo


    tmp_repo="/var/lib/bmo/repo.new"

    rm -rf "$tmp_repo"


    git clone \
        --local \
        --no-hardlinks \
        --no-checkout \
        "$ROOT" \
        "$tmp_repo"


    git \
        -C "$tmp_repo" \
        checkout \
        --detach \
        "$commit"


    if [ -n "$repo_url" ]; then

        git \
            -C "$tmp_repo" \
            remote \
            set-url \
            origin \
            "$repo_url"

    fi


    rm -rf "$BMO_REPO_DIR"

    mv \
        "$tmp_repo" \
        "$BMO_REPO_DIR"


    chown -R \
        root:root \
        "$BMO_REPO_DIR"

    chmod -R \
        go-w \
        "$BMO_REPO_DIR"


    echo "UPDATE_REPO_OK"
}


prepare_update_key() {

    banner "BMO INSTALL - UPDATE KEY"

    local key

    key="/etc/bmo/github_deploy_key"


    if [ ! -f "$key" ]; then

        ssh-keygen \
            -q \
            -t ed25519 \
            -N "" \
            -C "bmo-r36s-update" \
            -f "$key"

    fi


    chown \
        root:root \
        "$key" \
        "$key.pub"

    chmod 0600 "$key"
    chmod 0644 "$key.pub"


    echo
    echo "BMO_GITHUB_DEPLOY_KEY_PUBLIC:"
    cat "$key.pub"
    echo

    echo "UPDATE_KEY_READY_OK"
}


write_version() {

    banner "BMO INSTALL - VERSION"

    local commit
    local frontend_sha
    local branch

    commit="$(
        git_source rev-parse HEAD
    )"

    branch="$(
        git_source branch --show-current
    )"

    frontend_sha="$(
        sha256sum \
            /opt/bmo-ui/index.html |
        awk '{print $1}'
    )"


    cat > "$VERSION_FILE" <<EOF
BMO_VERSION=1.0.0
BMO_GIT_COMMIT=$commit
BMO_BRANCH=${branch:-main}
BMO_CHANNEL=stable
BMO_FRONTEND_SHA256=$frontend_sha
EOF

    chown root:root "$VERSION_FILE"
    chmod 0644 "$VERSION_FILE"

    echo "VERSION_OK"
}


enable_services() {

    banner "BMO INSTALL - SERVICES"

    systemctl daemon-reload


    local required=(
        bmo-control-api.service
        bmo-kiosk.service
        bmo-ui.service
        bmo-vt.service
        bmo-x-init.service
        bmo-xorg.service
        r36s-battery-api.service
        r36s-console.service
        r36s-sound-api.service
        r36s-status-api.service
    )


    local optional=(
        bmo-usb-ip-watch.service
        bmo-usb-swap-screen.service
        bmo-usb-tether-auto.service
    )


    local unit

    for unit in "${required[@]}"; do

        systemctl cat \
            "$unit" \
            >/dev/null \
            || die "service ausente: $unit"

        systemctl enable \
            "$unit" \
            >/dev/null

        systemctl is-enabled \
            --quiet \
            "$unit" \
            || die "service nao habilitado: $unit"

        echo "ENABLED=$unit"

    done


    for unit in "${optional[@]}"; do

        if systemctl cat \
            "$unit" \
            >/dev/null 2>&1
        then

            systemctl disable \
                "$unit" \
                >/dev/null 2>&1 \
                || true

            echo "OPTIONAL_DISABLED=$unit"

        fi

    done


    echo "SERVICES_ENABLED_OK"
}


final_verify() {

    banner "BMO INSTALL - VERIFY"

    command -v git >/dev/null
    command -v python3 >/dev/null
    command -v chromium >/dev/null
    command -v retroarch >/dev/null
    command -v moonlight-qt >/dev/null


    [ -x "$PP_BIN" ] ||
        die "PPSSPP ausente"


    [ "$(
        sha256sum "$PP_BIN" |
        awk '{print $1}'
    )" = "$EXPECTED_PP_BIN_SHA" ] ||
        die "PPSSPP hash final invalido"


    [ -f /opt/bmo-ui/index.html ] ||
        die "frontend production ausente"

    [ -f /opt/bmo-ui/index.bmo-next.html ] ||
        die "frontend candidate ausente"

    [ -f /opt/bmo-ui/bmo-runtime-config.js ] ||
        die "runtime frontend config ausente"


    [ -x /usr/local/bin/bmo ] ||
        die "CLI bmo ausente"

    [ -x /usr/local/sbin/bmo-maintenance ] ||
        die "maintenance helper ausente"


    [ -d /home/r36s/ROMs/gba ]
    [ -d /home/r36s/ROMs/snes ]
    [ -d /home/r36s/ROMs/psp ]


    if grep \
        -R \
        -n \
        -E \
        '192\.168\.[0-9]+\.[0-9]+' \
        /usr/local/bin/bmo-* \
        /opt/bmo-ui/index.html \
        /opt/bmo-ui/index.bmo-next.html \
        2>/dev/null
    then

        die "IP privado fixo encontrado na instalacao"

    fi


    echo "FINAL_VERIFY_OK"
}


main() {

    require_root

    banner "BMO R36S - INSTALL v1.0.0"

    [ "$(uname -m)" = "aarch64" ] ||
        die "arquitetura esperada: aarch64"


    [ -r /etc/os-release ] ||
        die "/etc/os-release ausente"


    . /etc/os-release


    case "${ID:-}:${ID_LIKE:-}" in
        *debian*)
            ;;
        *)
            die "base Debian/Armbian esperada"
            ;;
    esac


    verify_runtime_files

    install_packages

    ensure_user

    install_moonlight

    install_ppsspp

    apply_bmo

    install_management

    configure_device

    prepare_update_repo

    prepare_update_key

    write_version

    enable_services

    final_verify


    sync


    echo
    echo "============================================================"
    echo " BMO_INSTALL_COMPLETE_OK"
    echo "============================================================"
    echo "REBOOT_REQUIRED=YES"
    echo
    echo "A chave publica acima deve ser cadastrada"
    echo "como Deploy Key READ-ONLY no GitHub para habilitar updates."
}


main "$@"
