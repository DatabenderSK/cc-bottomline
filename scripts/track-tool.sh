#!/bin/sh
# Reads PreToolUse hook JSON from stdin, writes tool_name to temp file.
jq -r '.tool_name // empty' 2>/dev/null > /tmp/.claude_current_tool
