#!/bin/bash
TAG="HardlinkScan"

log() {
  echo "$1"
  logger -t "$TAG" "$1"
}

TV="/mnt/user/data/media/tv"
TORRENTS="/mnt/user/data/torrents"

log "=== start run ==="

log "Step1: searching random file without hardlink in TV"
TARGET=$(find "$TV" -type f -links 1 -print0 | shuf -zn1 | tr -d '\0') || exit 1
if [ -z "$TARGET" ]; then
  log "No files without hardlinks in $TV"
  exit 0
fi

SIZE=$(stat -c '%s' "$TARGET")
log "Picked: $TARGET (size=${SIZE})"

CAND_LIST=$(find "$TORRENTS" -type f -size "${SIZE}c" -print)
CAND_COUNT=$(printf "%s\n" "$CAND_LIST" | grep -c .)
log "Candidates in TORRENTS with same size: $CAND_COUNT"

if [ "$CAND_COUNT" -eq 0 ]; then
  log "No candidates found in TORRENTS - skipping $TARGET (no delete)"
  exit 0
fi

HASH=$(sha256sum "$TARGET" | awk '{print $1}')
log "TARGET sha256: $HASH"

SRC=$(
  printf "%s\n" "$CAND_LIST" \
  | head -n 20 \
  | while read -r f; do
      [ -z "$f" ] && continue
      h=$(sha256sum "$f" | awk '{print $1}')
      if [ "$h" = "$HASH" ]; then
        echo "$f"
        break
      fi
    done
)

if [ -z "$SRC" ]; then
  log "No hash match among candidates - skipping $TARGET (no delete)"
  exit 0
fi

log "Found twin: $SRC -> creating hardlink"
rm "$TARGET"
ln "$SRC" "$TARGET"
log "Hardlink created successfully"

log "=== end run ==="
