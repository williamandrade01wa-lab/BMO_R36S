#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
CONTRACT="${1:-$SCRIPT_DIR/image-contract.tsv}"
FAILURES=0
CHECKS=0

good() {
  CHECKS=$((CHECKS + 1))
  printf 'OK: %s\n' "$*"
}

fail() {
  CHECKS=$((CHECKS + 1))
  FAILURES=$((FAILURES + 1))
  printf 'FAIL: %s\n' "$*" >&2
}

require_file() {
  local path="$1"
  if [[ -f "$path" ]]; then good "file exists: ${path#$REPO_ROOT/}"; else fail "missing file: ${path#$REPO_ROOT/}"; fi
}

if [[ -z "$REPO_ROOT" || ! -d "$REPO_ROOT/.git" ]]; then
  echo "FAIL: unable to resolve repository root" >&2
  exit 1
fi

cd "$REPO_ROOT"
echo "============================================================"
echo " BMO LINUX BASE PREFLIGHT"
echo "============================================================"
echo "REPO_ROOT=$REPO_ROOT"
echo "CONTRACT=${CONTRACT#$REPO_ROOT/}"

REQUIRED_FILES=(
  "image/armbian/UPSTREAM.env"
  "image/armbian/build-bmo-linux-base.sh"
  "image/armbian/userpatches/config-r36s-trixie-minimal.conf"
  "image/armbian/userpatches/customize-image.sh"
  "image/armbian/ci/preflight.sh"
  "image/armbian/ci/validate-image.sh"
  "image/armbian/ci/image-contract.tsv"
)
for path in "${REQUIRED_FILES[@]}"; do require_file "$REPO_ROOT/$path"; done

if [[ -f "$CONTRACT" ]]; then
  declare -A DEST_SEEN=()
  line_no=0
  entries=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))
    [[ -z "$line" || "$line" == \#* ]] && continue
    IFS=$'\t' read -r partition kind source_path image_path extra <<< "$line"
    entries=$((entries + 1))

    if [[ -n "${extra:-}" || -z "${partition:-}" || -z "${kind:-}" || -z "${source_path:-}" || -z "${image_path:-}" ]]; then
      fail "contract line $line_no must have exactly 4 non-empty TSV columns"
      continue
    fi
    [[ "$partition" == "boot" || "$partition" == "root" ]] && good "contract line $line_no partition=$partition" || fail "contract line $line_no invalid partition: $partition"
    [[ "$kind" == "file" || "$kind" == "exec" ]] && good "contract line $line_no kind=$kind" || fail "contract line $line_no invalid kind: $kind"
    [[ "$source_path" != /* && "$source_path" != *"../"* && "$source_path" == image/armbian/userpatches/* ]] && good "contract line $line_no source path is constrained" || fail "contract line $line_no unsafe/unexpected source path: $source_path"
    [[ "$image_path" == /* && "$image_path" != *"../"* ]] && good "contract line $line_no image path is absolute" || fail "contract line $line_no invalid image path: $image_path"

    dest_key="$partition:$image_path"
    if [[ -n "${DEST_SEEN[$dest_key]:-}" ]]; then
      fail "duplicate image destination in contract: $dest_key"
    else
      DEST_SEEN[$dest_key]=1
      good "unique destination: $dest_key"
    fi

    if [[ -f "$REPO_ROOT/$source_path" ]]; then
      good "contract source exists: $source_path"
      if [[ "$kind" == "exec" ]]; then
        [[ -x "$REPO_ROOT/$source_path" ]] && good "source executable: $source_path" || fail "source is not executable: $source_path"
      fi
    else
      fail "contract source missing: $source_path"
    fi
  done < "$CONTRACT"
  [[ "$entries" -gt 0 ]] && good "contract has $entries entries" || fail "contract has no validation entries"
else
  fail "contract not found: ${CONTRACT#$REPO_ROOT/}"
fi

echo
echo "=== SHELL SYNTAX ==="
SHELL_FILES=(
  "image/armbian/build-bmo-linux-base.sh"
  "image/armbian/userpatches/config-r36s-trixie-minimal.conf"
  "image/armbian/userpatches/customize-image.sh"
  "image/armbian/ci/preflight.sh"
  "image/armbian/ci/validate-image.sh"
)
for path in "${SHELL_FILES[@]}"; do
  if [[ -f "$path" ]] && bash -n "$path"; then good "bash -n: $path"; else fail "bash syntax: $path"; fi
done

echo
echo "=== BUILD PROFILE ==="
PROFILE="image/armbian/userpatches/config-r36s-trixie-minimal.conf"
if [[ -f "$PROFILE" ]] && bash -n "$PROFILE"; then
  unset KERNEL_BTF
  # shellcheck disable=SC1090
  source "$PROFILE"
  [[ "${KERNEL_BTF:-}" == "no" ]] && good "deterministic memory profile: KERNEL_BTF=no" || fail "minimal build profile must pin KERNEL_BTF=no"
else
  fail "build profile unavailable or invalid: $PROFILE"
fi

echo
echo "=== PYTHON SYNTAX ==="
FIRSTBOOT="image/armbian/userpatches/overlay/usr/local/sbin/bmo-firstboot"
if [[ -f "$FIRSTBOOT" ]]; then
  if python3 - "$FIRSTBOOT" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
compile(p.read_text(encoding="utf-8"), str(p), "exec")
PY
  then good "python compile: $FIRSTBOOT"; else fail "python syntax: $FIRSTBOOT"; fi
else
  fail "missing Python firstboot source: $FIRSTBOOT"
fi

echo
echo "=== UPSTREAM PINS ==="
UPSTREAM="image/armbian/UPSTREAM.env"
if [[ -f "$UPSTREAM" ]]; then
  if bash -n "$UPSTREAM"; then
    # shellcheck disable=SC1090
    source "$UPSTREAM"
    REQUIRED_VARS=(
      BMO_R36S_UPSTREAM_REPO BMO_R36S_UPSTREAM_TAG BMO_R36S_UPSTREAM_SHA
      BMO_ARMBIAN_BUILD_REPO BMO_ARMBIAN_BUILD_TAG BMO_ARMBIAN_BUILD_SHA
      BMO_IMAGE_PROFILE BMO_IMAGE_RELEASE BMO_IMAGE_BOARD BMO_IMAGE_BRANCH
    )
    for name in "${REQUIRED_VARS[@]}"; do
      [[ -n "${!name:-}" ]] && good "pin set: $name" || fail "missing pin: $name"
    done
    for name in BMO_R36S_UPSTREAM_SHA BMO_ARMBIAN_BUILD_SHA; do
      value="${!name:-}"
      [[ "$value" =~ ^[0-9a-fA-F]{40}$ ]] && good "40-hex commit pin: $name" || fail "invalid 40-hex commit pin: $name=$value"
    done
    [[ "${BMO_IMAGE_BOARD:-}" == "r36s" ]] && good "board pin: r36s" || fail "unexpected board: ${BMO_IMAGE_BOARD:-<unset>}"
    [[ "${BMO_IMAGE_RELEASE:-}" == "trixie" ]] && good "release pin: trixie" || fail "unexpected release: ${BMO_IMAGE_RELEASE:-<unset>}"
  else
    fail "UPSTREAM.env shell syntax"
  fi
else
  fail "missing UPSTREAM.env"
fi

echo
echo "=== SECRET GUARD ==="
SECRET_TARGETS=("image/armbian/userpatches" "image/armbian/UPSTREAM.env" "image/armbian/build-bmo-linux-base.sh")
SECRET_PATTERN='-----BEGIN (OPENSSH |RSA |EC |DSA )?PRIVATE KEY-----|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}'
secret_hits="$(grep -RInE --exclude-dir=output -- "$SECRET_PATTERN" "${SECRET_TARGETS[@]}" 2>/dev/null || true)"
if [[ -n "$secret_hits" ]]; then
  fail "possible private key/GitHub token signature detected"
  printf '%s\n' "$secret_hits" >&2
else
  good "no private-key/GitHub-token signature in image sources"
fi

echo
echo "============================================================"
echo "PREFLIGHT_CHECKS=$CHECKS"
echo "PREFLIGHT_FAILURES=$FAILURES"
if (( FAILURES > 0 )); then
  echo "BMO_PREFLIGHT_FAILED count=$FAILURES" >&2
  exit 1
fi
echo "BMO_PREFLIGHT_OK"
echo "============================================================"
