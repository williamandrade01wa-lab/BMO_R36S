#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="${1:-}"
CONTRACT="${2:-$SCRIPT_DIR/image-contract.tsv}"
FAILURES=0
CHECKS=0
LOOP=""
BOOT_MNT=""
ROOT_MNT=""
BOOT_READY=0
ROOT_READY=0

good() {
  CHECKS=$((CHECKS + 1))
  printf 'OK: %s\n' "$*"
}

fail() {
  CHECKS=$((CHECKS + 1))
  FAILURES=$((FAILURES + 1))
  printf 'FAIL: %s\n' "$*" >&2
}

cleanup() {
  [[ -n "$BOOT_MNT" ]] && sudo umount "$BOOT_MNT" 2>/dev/null || true
  [[ -n "$ROOT_MNT" ]] && sudo umount "$ROOT_MNT" 2>/dev/null || true
  [[ -n "$LOOP" ]] && sudo losetup -d "$LOOP" 2>/dev/null || true
  [[ -n "$BOOT_MNT" ]] && rmdir "$BOOT_MNT" 2>/dev/null || true
  [[ -n "$ROOT_MNT" ]] && rmdir "$ROOT_MNT" 2>/dev/null || true
}
trap cleanup EXIT

finish() {
  echo
  echo "============================================================"
  echo "IMAGE_VALIDATION_CHECKS=$CHECKS"
  echo "IMAGE_VALIDATION_FAILURES=$FAILURES"
  if (( FAILURES > 0 )); then
    echo "BMO_IMAGE_VALIDATION_FAILED count=$FAILURES" >&2
    echo "============================================================"
    exit 1
  fi
  echo "BMO_IMAGE_CONTENTS_OK"
  echo "============================================================"
  exit 0
}

echo "============================================================"
echo " BMO IMAGE VALIDATION"
echo "============================================================"
echo "IMAGE=${IMAGE:-<unset>}"
echo "CONTRACT=$CONTRACT"

if [[ -z "$IMAGE" ]]; then fail "image path argument is required"; finish; fi
if [[ ! -f "$IMAGE" ]]; then fail "image not found: $IMAGE"; finish; fi
if [[ ! -s "$IMAGE" ]]; then fail "image is empty: $IMAGE"; finish; fi
if [[ ! -f "$CONTRACT" ]]; then fail "contract not found: $CONTRACT"; finish; fi

good "image exists and is non-empty"
good "contract exists"

BOOT_MNT="$(mktemp -d)"
ROOT_MNT="$(mktemp -d)"
if LOOP="$(sudo losetup --find --show --partscan "$IMAGE" 2>&1)"; then
  good "loop device attached: $LOOP"
else
  fail "unable to attach image with losetup: $LOOP"
  LOOP=""
  finish
fi

sudo udevadm settle 2>/dev/null || true
sleep 1

echo
echo "=== BLOCK LAYOUT ==="
lsblk -f "$LOOP" || true

BOOT_PART="$(lsblk -lnpo NAME,FSTYPE "$LOOP" 2>/dev/null | awk '$2 ~ /^(vfat|fat|fat16|fat32)$/ {print $1; exit}' || true)"
ROOT_PART="$(lsblk -lnpo NAME,FSTYPE "$LOOP" 2>/dev/null | awk '$2 == "ext4" {print $1; exit}' || true)"

if [[ -n "$BOOT_PART" ]]; then good "FAT boot partition detected: $BOOT_PART"; else fail "FAT boot partition not found"; fi
if [[ -n "$ROOT_PART" ]]; then good "ext4 root partition detected: $ROOT_PART"; else fail "ext4 root partition not found"; fi

if [[ -n "$BOOT_PART" ]]; then
  if sudo mount -o ro "$BOOT_PART" "$BOOT_MNT"; then BOOT_READY=1; good "boot partition mounted read-only"; else fail "failed to mount boot partition read-only: $BOOT_PART"; fi
fi
if [[ -n "$ROOT_PART" ]]; then
  if sudo mount -o ro "$ROOT_PART" "$ROOT_MNT"; then ROOT_READY=1; good "root partition mounted read-only"; else fail "failed to mount root partition read-only: $ROOT_PART"; fi
fi

echo
echo "=== CONTRACT CHECKS ==="
line_no=0
entries=0
while IFS= read -r line || [[ -n "$line" ]]; do
  line_no=$((line_no + 1))
  [[ -z "$line" || "$line" == \#* ]] && continue
  IFS=$'\t' read -r partition kind source_path image_path extra <<< "$line"
  entries=$((entries + 1))

  if [[ -n "${extra:-}" || -z "${partition:-}" || -z "${kind:-}" || -z "${image_path:-}" ]]; then
    fail "invalid contract row at line $line_no"
    continue
  fi

  case "$partition" in
    boot)
      if (( BOOT_READY == 0 )); then echo "SKIP: $partition:$image_path (partition unavailable)"; continue; fi
      target="$BOOT_MNT$image_path"
      ;;
    root)
      if (( ROOT_READY == 0 )); then echo "SKIP: $partition:$image_path (partition unavailable)"; continue; fi
      target="$ROOT_MNT$image_path"
      ;;
    *)
      fail "invalid partition '$partition' at contract line $line_no"
      continue
      ;;
  esac

  case "$kind" in
    file)
      if [[ -f "$target" ]]; then
        good "$partition file: $image_path"
      else
        fail "$partition missing file: $image_path (source=$source_path)"
        ls -ld "$(dirname "$target")" 2>/dev/null || true
      fi
      ;;
    exec)
      if [[ -f "$target" && -x "$target" ]]; then
        good "$partition executable: $image_path"
      elif [[ -e "$target" ]]; then
        fail "$partition not executable file: $image_path (source=$source_path)"
        ls -l "$target" 2>/dev/null || true
      else
        fail "$partition missing executable: $image_path (source=$source_path)"
        ls -ld "$(dirname "$target")" 2>/dev/null || true
      fi
      ;;
    *) fail "invalid kind '$kind' at contract line $line_no" ;;
  esac
done < "$CONTRACT"

[[ "$entries" -gt 0 ]] && good "processed $entries contract entries" || fail "contract has no validation entries"

if (( FAILURES > 0 )); then
  echo
  echo "=== TARGETED DIAGNOSTICS ==="
  if (( BOOT_READY == 1 )); then
    echo "-- BOOT files (depth <= 2) --"
    find "$BOOT_MNT" -maxdepth 2 -type f -printf '%P\n' 2>/dev/null | sort | head -200 || true
  fi
  if (( ROOT_READY == 1 )); then
    for path in /usr/local/bin /usr/local/sbin /etc/bmo /etc/NetworkManager/conf.d /etc/netplan /etc/udev/rules.d; do
      echo "-- ROOT$path --"
      ls -la "$ROOT_MNT$path" 2>/dev/null || true
    done
  fi
fi

finish
