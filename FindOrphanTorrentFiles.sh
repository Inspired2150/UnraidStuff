RANDOM_FILE=$(docker exec binhex-qbittorrentvpn find /data/torrents/movies -type f -name "*.mkv" | shuf -n1 | sed 's|/data/||')
FULL_PATH="/mnt/user/data/$RANDOM_FILE"

echo "=== RANDOM FILE ==="
echo "Path: $RANDOM_FILE"

# Pre-filter hashes (movies only) + timeout
TORRENT_INFO=$(timeout 10 curl -s -u admin:aegis123 'http://192.168.0.111:8079/api/v2/torrents/info' | \
grep -F "/data/torrents/movies" -A20 | jq --arg full "/data/$RANDOM_FILE" -r '.[]? | select(.content_path == $full) | "\(.name)|\(.tracker)|\(.hash)"' | head -1 2>/dev/null)

if [ -n "$TORRENT_INFO" ]; then
  IFS='|' read -r NAME TRACKER HASH <<< "$TORRENT_INFO"
  HASH8=${HASH:0:8:-}
  echo "✓ OWNED by '$NAME' from '$TRACKER' (hash: $HASH8)"
else
  echo "**ORPHAN** - DELETING..."
  rm -v "$FULL_PATH"
fi
