#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
ENV_FILE="${SCRIPT_DIR}/UPSTREAM.env"
PROFILE_FILE="${SCRIPT_DIR}/userpatches/config-r36s-trixie-minimal.conf"
WORK_DIR="${BMO_IMAGE_WORK_DIR:-${SCRIPT_DIR}/.work}"
R36S_SRC="${WORK_DIR}/r36s-source"
ARMBIAN_SRC="${WORK_DIR}/armbian-build"
OUT_DIR="${SCRIPT_DIR}/output"

# O fork trixie-r1 referencia um fork de kernel que nao esta mais publico.
# Para uma build publica/reproduzivel, usamos a origem publica da mesma
# linhagem RK3326 e fixamos o commit exato em vez de acompanhar uma branch.
BMO_KERNEL_REPO="https://github.com/EatPrilosec/linux-stable-rk3326.git"
BMO_KERNEL_SHA="d5da60f7ee9fcafed61f1e93590eb85ca0ecd7c0"

log() {
    printf '[BMO-LINUX-BASE] %s\n' "$*"
}

die() {
    printf '[BMO-LINUX-BASE][ERRO] %s\n' "$*" >&2
    exit 1
}

[ -r "$ENV_FILE" ] || die "UPSTREAM.env nao encontrado"
# shellcheck disable=SC1090
source "$ENV_FILE"

for cmd in git cp find mkdir rm sed sha256sum; do
    command -v "$cmd" >/dev/null 2>&1 || die "comando obrigatorio ausente: $cmd"
done

[ -r "$PROFILE_FILE" ] || die "perfil minimal nao encontrado: $PROFILE_FILE"

if [ "${1:-}" = "clean" ]; then
    log "limpando area de trabalho"
    rm -rf "$WORK_DIR" "$OUT_DIR"
    log "BMO_LINUX_BASE_CLEAN_OK"
    exit 0
fi

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR" "$OUT_DIR"

log "baixando suporte R36S fixado em ${BMO_R36S_UPSTREAM_TAG}"
git clone --quiet --depth 1 --branch "$BMO_R36S_UPSTREAM_TAG" \
    "$BMO_R36S_UPSTREAM_REPO" "$R36S_SRC"

ACTUAL_R36S_SHA="$(git -C "$R36S_SRC" rev-parse HEAD)"
[ "$ACTUAL_R36S_SHA" = "$BMO_R36S_UPSTREAM_SHA" ] || \
    die "SHA R36S inesperado: $ACTUAL_R36S_SHA"

log "baixando Armbian Build fixado em ${BMO_ARMBIAN_BUILD_TAG}"
git clone --quiet --depth 1 --branch "$BMO_ARMBIAN_BUILD_TAG" \
    "$BMO_ARMBIAN_BUILD_REPO" "$ARMBIAN_SRC"

ACTUAL_ARMBIAN_SHA="$(git -C "$ARMBIAN_SRC" rev-parse HEAD)"
[ "$ACTUAL_ARMBIAN_SHA" = "$BMO_ARMBIAN_BUILD_SHA" ] || \
    die "SHA Armbian Build inesperado: $ACTUAL_ARMBIAN_SHA"

log "aplicando suporte especifico do R36S sobre o framework Armbian"
cp -a "$R36S_SRC/config/." "$ARMBIAN_SRC/config/"
mkdir -p "$ARMBIAN_SRC/userpatches"
cp -a "$R36S_SRC/userpatches/." "$ARMBIAN_SRC/userpatches/"

RK3326_FAMILY="$ARMBIAN_SRC/config/sources/families/rk3326.conf"
[ -f "$RK3326_FAMILY" ] || die "rk3326.conf nao encontrado"

log "fixando kernel RK3326 publico em ${BMO_KERNEL_SHA}"
sed -i \
    -e "s#^declare -g KERNELSOURCE=.*#declare -g KERNELSOURCE='${BMO_KERNEL_REPO}'#" \
    -e "s#^declare -g KERNELBRANCH=.*#declare -g KERNELBRANCH='commit:${BMO_KERNEL_SHA}'#" \
    "$RK3326_FAMILY"

grep -F "KERNELSOURCE='${BMO_KERNEL_REPO}'" "$RK3326_FAMILY" >/dev/null || \
    die "falha ao aplicar KERNELSOURCE publico"
grep -F "KERNELBRANCH='commit:${BMO_KERNEL_SHA}'" "$RK3326_FAMILY" >/dev/null || \
    die "falha ao fixar commit do kernel"

log "aplicando perfil BMO Trixie minimal"
cp -f "$PROFILE_FILE" "$ARMBIAN_SRC/userpatches/config-r36s-trixie-minimal.conf"

log "compilando ${BMO_IMAGE_PROFILE}"
(
    cd "$ARMBIAN_SRC"
    ./compile.sh "$BMO_IMAGE_PROFILE"
)

IMAGE="$(find "$ARMBIAN_SRC/output" -type f -name '*.img' -print -quit 2>/dev/null || true)"
[ -n "$IMAGE" ] || die "imagem .img nao encontrada apos a compilacao"

OUT_IMAGE="${OUT_DIR}/bmo-linux-base-r36s-trixie-v0.1.img"
cp -f "$IMAGE" "$OUT_IMAGE"
sha256sum "$OUT_IMAGE" > "${OUT_IMAGE}.sha256"

log "imagem: $OUT_IMAGE"
log "sha256: $(cut -d' ' -f1 "${OUT_IMAGE}.sha256")"
log "BMO_LINUX_BASE_BUILD_OK"
