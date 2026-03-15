#!/bin/sh
# Tracks currently active tool for statusline display.
# Usage: track-tool.sh        — reads tool_name from PreToolUse hook JSON (stdin)
#        track-tool.sh clean  — removes the tool file (for Stop hook)
_TMPDIR="${TMPDIR:-${TEMP:-${TMP:-/tmp}}}"
TOOL_FILE="$_TMPDIR/.claude_current_tool"
if [ "$1" = "clean" ]; then
  rm -f "$TOOL_FILE"
else
  jq -r '.tool_name // empty' 2>/dev/null > "$TOOL_FILE"
fi
