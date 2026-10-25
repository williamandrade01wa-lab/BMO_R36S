#!/usr/bin/env bash
# Shrink only an unmounted regular MBR image; never a physical card.
set -euo pipefail
IMAGE="$(realpath -e "$1")";MARGIN_MIB="${2:-128}";LOOP="";OWNED_LOOP="${3:-}"
[ "$EUID" -eq 0 ] && [ -f "$IMAGE" ] && [ ! -b "$IMAGE" ] || exit 1
[[ "$MARGIN_MIB" =~ ^[0-9]+$ ]] && [ "$MARGIN_MIB" -ge 16 ] && [ "$MARGIN_MIB" -le 1024 ]
if [ -n "$OWNED_LOOP" ];then
    [[ "$OWNED_LOOP" =~ ^/dev/loop[0-9]+$ ]] || exit 1
    BACKING="$(losetup --list --noheadings --output BACK-FILE "$OWNED_LOOP")"
    [ "$(realpath -e "$BACKING")" = "$IMAGE" ] || exit 1
    for DEV in "$OWNED_LOOP" "$OWNED_LOOP"p1 "$OWNED_LOOP"p2;do
        [ -z "$(findmnt -rn -S "$DEV")" ] || { echo 'owned image still mounted' >&2;exit 1; }
    done
    LOOP="$OWNED_LOOP"
else
    [ -z "$(losetup -j "$IMAGE")" ] || { echo 'image already attached' >&2;exit 1; }
fi
trap '[ -z "$LOOP" ] || losetup -d "$LOOP"' EXIT
read -r START FIRST_START < <(sfdisk --json "$IMAGE" | python3 -c 'import json,sys;p=json.load(sys.stdin)["partitiontable"]["partitions"];assert len(p)==2 and p[1]["type"].lower()=="83";print(p[1]["start"],p[0]["start"])')
prefix_hash(){
    python3 - "$IMAGE" "$FIRST_START" <<'PY'
import sys,hashlib
with open(sys.argv[1],"rb") as f:
 b=f.read(int(sys.argv[2])*512)
assert b[510:512]==b"\x55\xaa"
b=b[:462]+bytes(16)+b[478:]
print(hashlib.sha256(b).hexdigest())
PY
}
PREFIX="$(prefix_hash)"
if [ -z "$LOOP" ];then LOOP="$(losetup --find --show --partscan "$IMAGE")";udevadm settle;fi
PART="$LOOP"p2
if e2fsck -pf "$PART";then :;else [ "$?" -le 1 ];fi
resize2fs -M "$PART"
BLOCKS="$(dumpe2fs -h "$PART" 2>/dev/null | awk '/^Block count:/ {print $3}')"
BS="$(dumpe2fs -h "$PART" 2>/dev/null | awk '/^Block size:/ {print $3}')"
FINAL_BLOCKS="$(( ((BLOCKS*BS+MARGIN_MIB*1024*1024+4194303)/4194304)*4194304/BS ))"
resize2fs "$PART" "$FINAL_BLOCKS"
if e2fsck -pf "$PART";then :;else [ "$?" -le 1 ];fi
zerofree "$PART"
losetup -d "$LOOP";LOOP=""
SECTORS="$((FINAL_BLOCKS*BS/512))"
printf 'start=%s,size=%s,type=83\n' "$START" "$SECTORS" | sfdisk --no-reread --force -N 2 "$IMAGE"
truncate -s "$(((START+SECTORS)*512))" "$IMAGE"
[ "$(prefix_hash)" = "$PREFIX" ] || { echo 'boot prefix changed' >&2;exit 1; }
echo "BMO_LIGHT_MINIMIZE_OK bytes=$(stat -c %s "$IMAGE")"
