#!/bin/sh
# Fetches Claude API usage stats and writes them to cache.
# Respects TTL from statusline.conf to avoid excessive API calls.
# Works on macOS, Linux, and Windows (Git Bash).
#
# Cache format:
# Line 1: five_hour.utilization (integer %)
# Line 2: seven_day.utilization (integer %)
# Line 3: five_hour.resets_at (raw ISO string)
# Line 4: seven_day.resets_at (raw ISO string)

# ── OS detection ──
case "$(uname -s)" in
  Darwin*)               _OS=mac ;;
  MINGW*|MSYS*|CYGWIN*) _OS=win ;;
  *)                     _OS=linux ;;
esac
_TMPDIR="${TMPDIR:-${TEMP:-${TMP:-/tmp}}}"
_mtime() {
  case "$_OS" in
    mac) stat -f %m "$1" 2>/dev/null || echo 0 ;;
    *)   stat -c %Y "$1" 2>/dev/null || echo 0 ;;
  esac
}

CACHE_FILE="$_TMPDIR/.claude_usage_cache"
CONF_FILE="$HOME/.claude/statusline.conf"

# --- TTL check ---
TTL=1800
if [ -f "$CONF_FILE" ]; then
  conf_ttl=$(grep '^USAGE_FETCH_TTL=' "$CONF_FILE" 2>/dev/null | cut -d= -f2)
  case "$conf_ttl" in ''|*[!0-9]*) ;; *) TTL="$conf_ttl" ;; esac
fi

if [ -f "$CACHE_FILE" ]; then
  cache_age=$(( $(date +%s) - $(_mtime "$CACHE_FILE") ))
  if [ "$cache_age" -lt "$TTL" ]; then
    exit 0
  fi
fi

# --- fetch credentials (cross-platform) ---
raw_creds=""
case "$_OS" in
  mac)
    raw_creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
    ;;
  win)
    raw_creds=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/get-credentials.ps1" 2>/dev/null)
    ;;
  *)
    raw_creds=$(secret-tool lookup service "Claude Code-credentials" 2>/dev/null)
    ;;
esac

if [ -z "$raw_creds" ]; then
  exit 0
fi

token=$(printf '%s' "$raw_creds" | grep -o 'sk-ant-oat01-[A-Za-z0-9_-]*' | head -1)
if [ -z "$token" ]; then
  exit 0
fi

# --- fetch usage (token passed via temp config to avoid process list exposure) ---
tmp_cfg=$(mktemp)
printf 'header = "authorization: Bearer %s"\n' "$token" > "$tmp_cfg"
usage_json=$(curl -s -m 10 -K "$tmp_cfg" \
  -H "accept: application/json" \
  -H "anthropic-beta: oauth-2025-04-20" \
  -H "user-agent: claude-code/2.1.11" \
  "https://api.anthropic.com/oauth/usage" 2>/dev/null)
rm -f "$tmp_cfg"

if [ -z "$usage_json" ]; then
  exit 0
fi

five_h_raw=$(printf '%s' "$usage_json" | jq -r '.five_hour.utilization // empty' 2>/dev/null)
seven_d_raw=$(printf '%s' "$usage_json" | jq -r '.seven_day.utilization // empty' 2>/dev/null)
five_h_reset=$(printf '%s' "$usage_json" | jq -r '.five_hour.resets_at // ""' 2>/dev/null)
seven_d_reset=$(printf '%s' "$usage_json" | jq -r '.seven_day.resets_at // ""' 2>/dev/null)

if [ -n "$five_h_raw" ] && [ -n "$seven_d_raw" ]; then
  five_h=$(printf "%.0f" "$five_h_raw")
  seven_d=$(printf "%.0f" "$seven_d_raw")
  printf '%s\n%s\n%s\n%s\n' "$five_h" "$seven_d" "$five_h_reset" "$seven_d_reset" > "$CACHE_FILE"
fi
