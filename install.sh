#!/bin/sh
# CC Bottomline — installer
# Usage: curl -fsSL https://raw.githubusercontent.com/DatabenderSK/cc-bottomline/main/install.sh | bash

set -e

REPO="https://raw.githubusercontent.com/DatabenderSK/cc-bottomline/main"
DEST="$HOME/.claude"

echo "Installing CC Bottomline..."

# Download scripts
mkdir -p "$DEST"
curl -fsSL "$REPO/scripts/statusline-command.sh" -o "$DEST/statusline-command.sh"
curl -fsSL "$REPO/scripts/fetch-usage.sh" -o "$DEST/fetch-usage.sh"
curl -fsSL "$REPO/scripts/track-tool.sh" -o "$DEST/track-tool.sh"

# Config — only if not exists (don't overwrite user config)
if [ ! -f "$DEST/statusline.conf" ]; then
  curl -fsSL "$REPO/scripts/statusline.conf" -o "$DEST/statusline.conf"
  echo "Created default config: ~/.claude/statusline.conf"
else
  echo "Config already exists, skipping (edit ~/.claude/statusline.conf to change theme)"
fi

chmod +x "$DEST/statusline-command.sh" "$DEST/fetch-usage.sh" "$DEST/track-tool.sh"

# Wire statusLine in settings.json
SETTINGS="$DEST/settings.json"
if [ -f "$SETTINGS" ]; then
  if command -v jq > /dev/null 2>&1; then
    tmp=$(mktemp)
    jq '.statusLine = {"type": "command", "command": "bash ~/.claude/statusline-command.sh"}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    echo "Updated ~/.claude/settings.json"
  else
    echo "Note: Install jq to auto-configure settings.json, or add manually:"
    echo '  "statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }'
  fi
else
  cat > "$SETTINGS" <<'JSONEOF'
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
JSONEOF
  echo "Created ~/.claude/settings.json"
fi

# Wire PreToolUse hook for tool tracking
if command -v jq > /dev/null 2>&1 && [ -f "$SETTINGS" ]; then
  has_hook=$(jq -r '.hooks.PreToolUse // empty' "$SETTINGS" 2>/dev/null)
  if [ -z "$has_hook" ] || [ "$has_hook" = "null" ]; then
    tmp=$(mktemp)
    jq '.hooks.PreToolUse = [{"matcher": "", "hooks": [{"type": "command", "command": "bash ~/.claude/track-tool.sh; bash ~/.claude/fetch-usage.sh > /dev/null 2>&1 &"}]}]' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  else
    echo "Note: PreToolUse hook already exists. Add manually to your existing hook:"
    echo '  bash ~/.claude/track-tool.sh; bash ~/.claude/fetch-usage.sh > /dev/null 2>&1 &'
  fi
  has_stop=$(jq -r '.hooks.Stop // empty' "$SETTINGS" 2>/dev/null)
  if [ -z "$has_stop" ] || [ "$has_stop" = "null" ]; then
    tmp=$(mktemp)
    jq '.hooks.Stop = [{"matcher": "", "hooks": [{"type": "command", "command": "rm -f /tmp/.claude_current_tool; bash ~/.claude/fetch-usage.sh > /dev/null 2>&1 &"}]}]' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  else
    echo "Note: Stop hook already exists. Add manually to your existing hook:"
    echo '  rm -f /tmp/.claude_current_tool; bash ~/.claude/fetch-usage.sh > /dev/null 2>&1 &'
  fi
fi

echo ""
echo "Done! Restart Claude Code to see your new bottomline."
echo ""
echo "Change theme:  edit ~/.claude/statusline.conf → THEME=hybrid"
echo "Available:     hybrid, default, minimal, nerd, compact, tokyo, monochrome, brackets"
echo "Preview:       https://github.com/DatabenderSK/cc-bottomline#themes"
