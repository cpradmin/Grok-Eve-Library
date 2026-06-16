---
description: Set context and show recent matching log entries
---
`! bash -c '
TAG="$ARGUMENTS"
if [ -z "$TAG" ]; then
    echo "Usage: /focus <context-tag>"
    exit 1
fi
echo "$TAG" > ~/.claude/current-context
echo "Context set to: $TAG"
echo ""
LOGS="$HOME/.claude/logs"
TODAY=$(date +%F)
LOGFILE="$LOGS/session-${TODAY}.jsonl"
if [ -f "$LOGFILE" ]; then
    MATCHES=$(jq -r "select(.tag == \"$TAG\") | \"[\\(.ts)] \\(.role): \\(.content[:120])\"" "$LOGFILE" 2>/dev/null | tail -20)
    if [ -n "$MATCHES" ]; then
        echo "Recent $TAG activity:"
        echo "$MATCHES"
    else
        echo "No prior $TAG entries today."
    fi
else
    echo "No session log for today."
fi
'`
