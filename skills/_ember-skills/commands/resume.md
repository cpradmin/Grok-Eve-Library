---
description: Show recent session log entries. Usage: /resume [N] [TAG]
---
`! bash -c '
LOGS="$HOME/.claude/logs"
ARGS="$ARGUMENTS"
N=40
TAG=""

# Parse args: /resume, /resume 20, /resume ember-rag, /resume ember-rag 20
for arg in $ARGS; do
    if [[ "$arg" =~ ^[0-9]+$ ]]; then
        N="$arg"
    elif [ -n "$arg" ]; then
        TAG="$arg"
    fi
done

TODAY=$(date +%F)
LOGFILE="$LOGS/session-${TODAY}.jsonl"

if [ ! -f "$LOGFILE" ]; then
    echo "No session log for today ($TODAY)"
    exit 0
fi

if [ -n "$TAG" ]; then
    jq -r "select(.tag == \"$TAG\") | \"[\\(.ts)] [\\(.tag)] \\(.role): \\(.content[:120])\"" "$LOGFILE" 2>/dev/null | tail -n "$N"
else
    jq -r "\"[\\(.ts)] [\\(.tag)] \\(.role): \\(.content[:120])\"" "$LOGFILE" 2>/dev/null | tail -n "$N"
fi
'`
