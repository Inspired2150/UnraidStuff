#!/bin/bash
TAG="HardlinkScan"

log() {
  echo "$1"
  logger -t "$TAG" "$1"
}

TV="/mnt/user/data/media/tv"

log "=== TV Season Purge ==="

# Step 1: Pick random orphan file
TARGET=$(find "$TV" -type f -links 1 -print0 2>/dev/null | shuf -zn1 | tr -d '\0') || exit 1
[ -z "$TARGET" ] && { log "No orphans found"; exit 0; }

# Step 2: Print parent folder
SEASON_DIR=$(dirname "$TARGET")
log "Target: $TARGET"
log "Season: $SEASON_DIR"

# Step 3: Check orphans in season folder
SEASON_FILE_COUNT=$(find "$SEASON_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l)
SEASON_ORPHAN_COUNT=$(find "$SEASON_DIR" -maxdepth 1 -type f -links 1 2>/dev/null | wc -l)

log "Season total: $SEASON_FILE_COUNT, orphans: $SEASON_ORPHAN_COUNT"

# Delete if ALL orphans AND ≤50 files
if [ "$SEASON_ORPHAN_COUNT" -eq "$SEASON_FILE_COUNT" ] && [ "$SEASON_FILE_COUNT" -le 50 ] && [ "$SEASON_FILE_COUNT" -gt 0 ]; then
  log "=== DELETING orphan season: $SEASON_DIR ==="
  rm -rf "$SEASON_DIR"
  log "Deleted ${SEASON_FILE_COUNT} orphan files"
else
  log "Season protected (has hardlinks or >30 files)"
fi

log "=== end run ==="
