#!/bin/bash
# sync-to-host.sh — Deploy claude-library skills to a remote host
# Usage: ./sync-to-host.sh <user@host> [ssh-key]

set -e

HOST="${1:?Usage: $0 user@host [ssh-key]}"
KEY_OPT=""
[ -n "$2" ] && KEY_OPT="-i $2"

LIBRARY="$(dirname "$0")"
REMOTE_SKILLS="~/.claude/skills"

echo "=== Syncing claude-library to $HOST ==="

# Create remote dirs
ssh $KEY_OPT -o ConnectTimeout=5 "$HOST" "mkdir -p ~/.claude/skills"

# Sync standalone skills (the bulk of it)
echo "Syncing standalone skills..."
rsync -az --delete \
  $( [ -n "$2" ] && echo "-e 'ssh -i $2'" ) \
  "$LIBRARY/standalone/" \
  "$HOST:~/.claude/skills/" \
  --exclude='.git' \
  --info=progress2

# Sync bundle skills via symlink targets
echo "Syncing skill bundles..."
for bundle_dir in "$LIBRARY"/skills/*/; do
  bundle=$(basename "$bundle_dir")
  rsync -az \
    $( [ -n "$2" ] && echo "-e 'ssh -i $2'" ) \
    "$bundle_dir" \
    "$HOST:~/.claude/skills/$bundle/" \
    --exclude='.git' \
    --info=progress2
done

# Count remote skills
count=$(ssh $KEY_OPT "$HOST" "ls ~/.claude/skills/ | wc -l")
echo ""
echo "=== Done: $count skills on $HOST ==="
