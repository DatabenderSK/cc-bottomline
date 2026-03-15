#!/bin/sh
input=$(cat)

# ══════════════════════════════════════════════════════
# Claude Code Statusline v2
# ══════════════════════════════════════════════════════

# --- defaults (overridden by config) ---
THEME=default
SHOW_MODEL=1; SHOW_FOLDER=1; SHOW_BRANCH=1; SHOW_GIT_STATUS=0
SHOW_TOOL=1; SHOW_AGENT=0; SHOW_WORKTREE=0
SHOW_CONTEXT=1; SHOW_CONTEXT_BAR=0; SHOW_CONTEXT_TOKENS=1
SHOW_USAGE_5H=1; SHOW_USAGE_7D=1; SHOW_USAGE_BAR=1; SHOW_USAGE_RESET=1
SHOW_DURATION=0; SHOW_LINES_CHANGED=0; SHOW_COST=0; SHOW_VERSION=0
BAR_WIDTH=10; USAGE_BAR_WIDTH=8; USAGE_FETCH_TTL=1800; GIT_CACHE_TTL=5

CONF_FILE="$HOME/.claude/statusline.conf"
[ -f "$CONF_FILE" ] && . "$CONF_FILE"

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

# ── ANSI codes ──
R="\033[0m"; B="\033[1m"; D="\033[2m"; S="\033[90m"

# ── color palettes per theme ──
case "$THEME" in
  hybrid)
    C_MODEL="\033[38;5;208m"             # orange (line 1 colored)
    C_FOLDER="\033[38;2;76;208;222m"     # cyan
    C_BRANCH="\033[38;2;192;103;222m"    # purple
    C_TOOL="\033[38;2;255;200;0m"        # gold
    C_GREEN="\033[38;2;134;194;126m"
    C_YELLOW="\033[38;2;229;192;100m"
    C_RED="\033[38;2;237;106;94m"
    C_MUTED="\033[38;2;139;148;158m"     # monochrome gray
    C_BAR_E="\033[38;2;48;54;61m"        # dark gray bar
    C_ADD="\033[38;2;134;194;126m"
    C_DEL="\033[38;2;237;106;94m"
    C_AGENT="\033[38;2;134;194;126m"
    # monochrome colors for line 2
    C_MONO="\033[38;2;139;148;158m"
    C_MONO_D="\033[38;2;72;79;88m"
    ;;
  tokyo)
    C_MODEL="\033[38;2;122;162;247m"     # blue
    C_FOLDER="\033[38;2;125;207;255m"    # cyan
    C_BRANCH="\033[38;2;158;206;106m"    # green
    C_TOOL="\033[38;2;224;175;104m"      # amber
    C_GREEN="\033[38;2;158;206;106m"
    C_YELLOW="\033[38;2;224;175;104m"
    C_RED="\033[38;2;247;118;142m"
    C_MUTED="\033[38;2;169;177;214m"
    C_BAR_E="\033[38;2;60;60;80m"
    C_ADD="\033[38;2;158;206;106m"
    C_DEL="\033[38;2;247;118;142m"
    C_AGENT="\033[38;2;158;206;106m"
    ;;
  nerd)
    C_MODEL="\033[38;2;137;180;250m"     # lavender
    C_FOLDER="\033[38;2;148;226;213m"    # teal
    C_BRANCH="\033[38;2;203;166;247m"    # mauve
    C_TOOL="\033[38;2;249;226;175m"      # yellow
    C_GREEN="\033[38;2;166;227;161m"
    C_YELLOW="\033[38;2;249;226;175m"
    C_RED="\033[38;2;243;139;168m"
    C_MUTED="\033[38;2;186;194;222m"
    C_BAR_E="\033[38;2;69;71;90m"
    C_ADD="\033[38;2;166;227;161m"
    C_DEL="\033[38;2;243;139;168m"
    C_AGENT="\033[38;2;148;226;213m"
    ;;
  *)
    C_MODEL="\033[38;5;208m"             # orange
    C_FOLDER="\033[38;2;76;208;222m"     # cyan
    C_BRANCH="\033[38;2;192;103;222m"    # purple
    C_TOOL="\033[38;2;255;200;0m"        # gold
    C_GREEN="\033[38;2;134;194;126m"
    C_YELLOW="\033[38;2;229;192;100m"
    C_RED="\033[38;2;237;106;94m"
    C_MUTED="\033[38;2;156;162;175m"
    C_BAR_E="\033[38;2;60;63;75m"
    C_ADD="\033[38;2;134;194;126m"
    C_DEL="\033[38;2;237;106;94m"
    C_AGENT="\033[38;2;134;194;126m"
    ;;
esac

# ── theme separators & icons ──
case "$THEME" in
  nerd)
    SEP="${S} │ ${R}"; PIPE="${S} │ ${R}"
    I_M="🤖 "; I_F="📁 "; I_BR="🌿 "; I_T="⚡ "
    I_5H="⏳ "; I_7D="📅 "; I_CTX="🧠 "; I_CO="💰 "
    I_AG="↳ "; I_DUR="⏱️  "; I_LN=""; I_WT="🌳 "
    ;;
  minimal)
    SEP="${S} · ${R}"; PIPE="${S} · ${R}"
    I_M=""; I_F=""; I_BR=""; I_T="⚡ "
    I_5H=""; I_7D=""; I_CTX=""; I_CO=""
    I_AG=""; I_DUR=""; I_LN=""; I_WT=""
    ;;
  *)
    SEP="${S} • ${R}"; PIPE="${S} | ${R}"
    I_M=""; I_F="📁 "; I_BR=""; I_T="⚡ "
    I_5H=""; I_7D=""; I_CTX=""; I_CO=""
    I_AG="↳ "; I_DUR=""; I_LN=""; I_WT=""
    ;;
esac

# ══════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════

usage_color() {
  pct="$1"
  if [ "$pct" -ge 80 ]; then printf "%s" "${C_RED}${B}"
  elif [ "$pct" -ge 60 ]; then printf "%s" "${C_YELLOW}"
  else printf "%s" "${C_GREEN}"
  fi
}

render_bar() {
  pct="$1"; w="${2:-$BAR_WIDTH}"
  filled=$(( pct * w / 100 )); [ "$filled" -gt "$w" ] && filled="$w"
  empty=$(( w - filled ))
  c=$(usage_color "$pct")
  printf "%b" "$c"
  i=0; while [ "$i" -lt "$filled" ]; do printf "█"; i=$((i+1)); done
  printf "%b" "${C_BAR_E}"
  i=0; while [ "$i" -lt "$empty" ]; do printf "░"; i=$((i+1)); done
  printf "%b" "$R"
}

compute_delta() {
  clean=$(echo "$1" | sed 's/\.[0-9]*//' | sed 's/[+-][0-9][0-9]:[0-9][0-9]$//' | sed 's/Z$//')
  case "$_OS" in
    mac) reset_epoch=$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$clean" "+%s" 2>/dev/null) ;;
    *)   reset_epoch=$(date -u -d "$clean" "+%s" 2>/dev/null) ;;
  esac
  [ -z "$reset_epoch" ] && return
  now_epoch=$(date -u "+%s"); diff=$(( reset_epoch - now_epoch ))
  [ "$diff" -le 0 ] && echo "now" && return
  days=$(( diff / 86400 )); hours=$(( (diff % 86400) / 3600 )); minutes=$(( (diff % 3600) / 60 ))
  if [ "$days" -gt 0 ]; then echo "${days}d ${hours}h"
  elif [ "$hours" -gt 0 ]; then echo "${hours}h ${minutes}m"
  else echo "${minutes}m"
  fi
}

fmt_duration() {
  ms="$1"
  [ -z "$ms" ] || [ "$ms" = "null" ] && return
  secs=$(( ms / 1000 )); mins=$(( secs / 60 )); s=$(( secs % 60 ))
  if [ "$mins" -gt 0 ]; then echo "${mins}m ${s}s"
  else echo "${s}s"
  fi
}

# ══════════════════════════════════════════════════════
# DATA EXTRACTION
# ══════════════════════════════════════════════════════

model=$(echo "$input" | jq -r '.model.display_name // ""')
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
dir_name=$(basename "$dir")

# git branch
branch=""
if [ "$SHOW_BRANCH" = "1" ] || [ "$SHOW_GIT_STATUS" = "1" ]; then
  if [ -d "${dir}/.git" ] || git -C "$dir" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null || git -C "$dir" rev-parse --short HEAD 2>/dev/null)
  fi
fi

# git status (staged/modified counts, cached)
git_staged=0; git_modified=0
if [ "$SHOW_GIT_STATUS" = "1" ] && [ -n "$branch" ]; then
  GIT_CACHE="$_TMPDIR/.claude_git_status_cache"
  stale=1
  if [ -f "$GIT_CACHE" ]; then
    age=$(( $(date +%s) - $(_mtime "$GIT_CACHE") ))
    [ "$age" -lt "$GIT_CACHE_TTL" ] && stale=0
  fi
  if [ "$stale" = "1" ]; then
    gs=$(git -C "$dir" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    gm=$(git -C "$dir" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    printf '%s\n%s\n' "$gs" "$gm" > "$GIT_CACHE"
  fi
  git_staged=$(sed -n '1p' "$GIT_CACHE")
  git_modified=$(sed -n '2p' "$GIT_CACHE")
fi

# current tool
current_tool=""
if [ "$SHOW_TOOL" = "1" ] && [ -f "$_TMPDIR/.claude_current_tool" ]; then
  current_tool=$(cat "$_TMPDIR/.claude_current_tool" 2>/dev/null)
fi

# agent
agent=""
if [ "$SHOW_AGENT" = "1" ]; then
  agent=$(echo "$input" | jq -r '.agent.name // empty' 2>/dev/null)
fi

# worktree
wt_name=""
if [ "$SHOW_WORKTREE" = "1" ]; then
  wt_name=$(echo "$input" | jq -r '.worktree.name // empty' 2>/dev/null)
fi

# usage cache
CACHE_FILE="$_TMPDIR/.claude_usage_cache"
five_h=""; seven_d=""; five_h_reset=""; seven_d_reset=""
if [ -f "$CACHE_FILE" ]; then
  five_h=$(sed -n '1p' "$CACHE_FILE")
  seven_d=$(sed -n '2p' "$CACHE_FILE")
  five_h_reset=$(sed -n '3p' "$CACHE_FILE")
  seven_d_reset=$(sed -n '4p' "$CACHE_FILE")
else
  bash ~/.claude/fetch-usage.sh > /dev/null 2>&1 &
fi

# context
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_total=$(echo "$input" | jq -r '.context_window.context_window_size // empty' 2>/dev/null)
used_int=0; ctx_str="0%"; ctx_tokens_str=""
if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  ctx_str="${used_int}%"
  if [ "$SHOW_CONTEXT_TOKENS" = "1" ]; then
    ctx_used=$(echo "$input" | jq -r '(.context_window.current_usage.cache_read_input_tokens + .context_window.current_usage.cache_creation_input_tokens + .context_window.current_usage.input_tokens + .context_window.current_usage.output_tokens) // empty' 2>/dev/null)
    if [ -n "$ctx_used" ] && [ -n "$ctx_total" ]; then
      ctx_used_k=$(( ctx_used / 1000 ))
      ctx_total_k=$(( ctx_total / 1000 ))
      ctx_tokens_str="${ctx_used_k}k/${ctx_total_k}k"
    fi
  fi
else
  if [ "$SHOW_CONTEXT_TOKENS" = "1" ] && [ -n "$ctx_total" ]; then
    ctx_total_k=$(( ctx_total / 1000 ))
    ctx_tokens_str="0k/${ctx_total_k}k"
  fi
fi

# cost
cost=""
[ "$SHOW_COST" = "1" ] && cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty' 2>/dev/null)

# duration
duration=""
[ "$SHOW_DURATION" = "1" ] && duration=$(fmt_duration "$(echo "$input" | jq -r '.cost.total_duration_ms // empty' 2>/dev/null)")

# lines changed
lines_add=""; lines_del=""
if [ "$SHOW_LINES_CHANGED" = "1" ]; then
  lines_add=$(echo "$input" | jq -r '.cost.total_lines_added // empty' 2>/dev/null)
  lines_del=$(echo "$input" | jq -r '.cost.total_lines_removed // empty' 2>/dev/null)
fi

# version
version=""
[ "$SHOW_VERSION" = "1" ] && version=$(echo "$input" | jq -r '.version // empty' 2>/dev/null)

# ══════════════════════════════════════════════════════
# OUTPUT HELPERS
# ══════════════════════════════════════════════════════

# Print model
pr_model() {
  [ "$SHOW_MODEL" = "1" ] && [ -n "$model" ] && printf "${C_MODEL}${B}${I_M}%s${R}" "$model"
}

# Print folder
pr_folder() {
  [ "$SHOW_FOLDER" = "1" ] && [ -n "$dir_name" ] && printf "%b${C_FOLDER}${B}${I_F}%s${R}" "$1" "$dir_name"
}

# Print branch + git status
pr_branch() {
  if [ "$SHOW_BRANCH" = "1" ] && [ -n "$branch" ]; then
    printf "%b${C_BRANCH}${B}${I_BR}%s${R}" "$1" "$branch"
    if [ "$SHOW_GIT_STATUS" = "1" ]; then
      [ "$git_staged" -gt 0 ] && printf " ${C_ADD}+%s${R}" "$git_staged"
      [ "$git_modified" -gt 0 ] && printf " ${C_DEL}~%s${R}" "$git_modified"
    fi
  fi
}

# Print agent
pr_agent() {
  [ "$SHOW_AGENT" = "1" ] && [ -n "$agent" ] && printf "%b${C_AGENT}${I_AG}%s${R}" "$1" "$agent"
}

# Print worktree
pr_worktree() {
  [ "$SHOW_WORKTREE" = "1" ] && [ -n "$wt_name" ] && printf "%b${C_MUTED}${I_WT}%s${R}" "$1" "$wt_name"
}

# Print tool
pr_tool() {
  [ "$SHOW_TOOL" = "1" ] && [ -n "$current_tool" ] && printf "%b${C_TOOL}${B}${I_T}%s${R}" "$1" "$current_tool"
}

# Print context (bar + %)
pr_ctx() {
  sep="$1"; has_ref="$2"
  if [ "$SHOW_CONTEXT_BAR" = "1" ]; then
    eval "[ \"\$$has_ref\" = \"1\" ]" && printf "%b" "$sep"
    bar=$(render_bar "$used_int")
    ctx_c=$(usage_color "$used_int")
    printf "%s ${ctx_c}%s${R}" "$bar" "$ctx_str"
    [ "$SHOW_CONTEXT_TOKENS" = "1" ] && [ -n "$ctx_tokens_str" ] && printf " ${D}${C_MUTED}(%s)${R}" "$ctx_tokens_str"
    eval "$has_ref=1"
  elif [ "$SHOW_CONTEXT" = "1" ]; then
    eval "[ \"\$$has_ref\" = \"1\" ]" && printf "%b" "$sep"
    ctx_c=$(usage_color "$used_int")
    printf "${ctx_c}${I_CTX}ctx %s${R}" "$ctx_str"
    [ "$SHOW_CONTEXT_TOKENS" = "1" ] && [ -n "$ctx_tokens_str" ] && printf " ${D}${C_MUTED}(%s)${R}" "$ctx_tokens_str"
    eval "$has_ref=1"
  fi
}

# Print usage limits (with optional progress bars)
pr_usage() {
  sep="$1"; has_ref="$2"
  if [ "$SHOW_USAGE_5H" = "1" ] && [ -n "$five_h" ]; then
    eval "[ \"\$$has_ref\" = \"1\" ]" && printf "%b" "$sep"
    c=$(usage_color "$five_h")
    if [ "$SHOW_USAGE_BAR" = "1" ]; then
      bar=$(render_bar "$five_h" "$USAGE_BAR_WIDTH")
      printf "${c}${I_5H}5h${R} %s ${c}%s%%${R}" "$bar" "$five_h"
    else
      printf "${c}${I_5H}5h %s%%${R}" "$five_h"
    fi
    if [ "$SHOW_USAGE_RESET" = "1" ] && [ -n "$five_h_reset" ]; then
      delta=$(compute_delta "$five_h_reset")
      [ -n "$delta" ] && printf " ${D}${C_MUTED}(%s)${R}" "$delta"
    fi
    eval "$has_ref=1"
  fi
  if [ "$SHOW_USAGE_7D" = "1" ] && [ -n "$seven_d" ]; then
    eval "[ \"\$$has_ref\" = \"1\" ]" && printf "%b" "$sep"
    c=$(usage_color "$seven_d")
    if [ "$SHOW_USAGE_BAR" = "1" ]; then
      bar=$(render_bar "$seven_d" "$USAGE_BAR_WIDTH")
      printf "${c}${I_7D}7d${R} %s ${c}%s%%${R}" "$bar" "$seven_d"
    else
      printf "${c}${I_7D}7d %s%%${R}" "$seven_d"
    fi
    if [ "$SHOW_USAGE_RESET" = "1" ] && [ -n "$seven_d_reset" ]; then
      delta=$(compute_delta "$seven_d_reset")
      [ -n "$delta" ] && printf " ${D}${C_MUTED}(%s)${R}" "$delta"
    fi
    eval "$has_ref=1"
  fi
}

# Print extras (cost, duration, lines, version)
pr_extras() {
  sep="$1"; has_ref="$2"
  if [ "$SHOW_COST" = "1" ] && [ -n "$cost" ]; then
    eval "[ \"\$$has_ref\" = \"1\" ]" && printf "%b" "$sep"
    printf "${C_MUTED}${I_CO}\$%s${R}" "$cost"
    eval "$has_ref=1"
  fi
  if [ "$SHOW_DURATION" = "1" ] && [ -n "$duration" ]; then
    eval "[ \"\$$has_ref\" = \"1\" ]" && printf "%b" "$sep"
    printf "${C_MUTED}${I_DUR}%s${R}" "$duration"
    eval "$has_ref=1"
  fi
  if [ "$SHOW_LINES_CHANGED" = "1" ]; then
    if [ -n "$lines_add" ] || [ -n "$lines_del" ]; then
      eval "[ \"\$$has_ref\" = \"1\" ]" && printf "%b" "$sep"
      [ -n "$lines_add" ] && printf "${C_ADD}+%s${R}" "$lines_add"
      [ -n "$lines_add" ] && [ -n "$lines_del" ] && printf " "
      [ -n "$lines_del" ] && printf "${C_DEL}-%s${R}" "$lines_del"
      eval "$has_ref=1"
    fi
  fi
  if [ "$SHOW_VERSION" = "1" ] && [ -n "$version" ]; then
    eval "[ \"\$$has_ref\" = \"1\" ]" && printf "%b" "$sep"
    printf "${D}${C_MUTED}v%s${R}" "$version"
    eval "$has_ref=1"
  fi
}

# ══════════════════════════════════════════════════════
# THEME LAYOUTS
# ══════════════════════════════════════════════════════

case "$THEME" in

# ─────────────── HYBRID: colored L1 + mono L2 ────
hybrid)
  # line 1: colored — model | folder • branch [| tool]
  pr_model; pr_folder "$PIPE"; pr_branch "$SEP"
  pr_agent "$SEP"; pr_worktree "$SEP"; pr_tool "$PIPE"
  # line 2: monochrome — ctx colored, limits mono (colored only on threshold)
  printf "\n"; h=0
  if [ "$SHOW_CONTEXT" = "1" ] || [ "$SHOW_CONTEXT_BAR" = "1" ]; then
    ctx_c=$(usage_color "$used_int")
    if [ "$SHOW_CONTEXT_BAR" = "1" ]; then
      bar=$(render_bar "$used_int")
      printf "%s ${ctx_c}%s${R}" "$bar" "$ctx_str"
    else
      printf "${ctx_c}ctx %s${R}" "$ctx_str"
    fi
    [ "$SHOW_CONTEXT_TOKENS" = "1" ] && [ -n "$ctx_tokens_str" ] && printf " ${C_MONO_D}(%s)${R}" "$ctx_tokens_str"
    h=1
  fi
  if [ "$SHOW_USAGE_5H" = "1" ] && [ -n "$five_h" ]; then
    [ "$h" = "1" ] && printf " ${C_MONO_D}|${R} "
    if [ "$five_h" -ge 80 ]; then uc="${C_RED}${B}"; elif [ "$five_h" -ge 60 ]; then uc="${C_YELLOW}"; else uc="${C_MONO}"; fi
    if [ "$SHOW_USAGE_BAR" = "1" ]; then
      bar=$(render_bar "$five_h" "$USAGE_BAR_WIDTH")
      printf "${uc}5h${R} %s ${uc}%s%%${R}" "$bar" "$five_h"
    else
      printf "${uc}5h %s%%${R}" "$five_h"
    fi
    [ "$SHOW_USAGE_RESET" = "1" ] && [ -n "$five_h_reset" ] && { delta=$(compute_delta "$five_h_reset"); [ -n "$delta" ] && printf " ${C_MONO_D}(%s)${R}" "$delta"; }
    h=1
  fi
  if [ "$SHOW_USAGE_7D" = "1" ] && [ -n "$seven_d" ]; then
    [ "$h" = "1" ] && printf " ${C_MONO_D}•${R} "
    if [ "$seven_d" -ge 80 ]; then uc="${C_RED}${B}"; elif [ "$seven_d" -ge 60 ]; then uc="${C_YELLOW}"; else uc="${C_MONO}"; fi
    if [ "$SHOW_USAGE_BAR" = "1" ]; then
      bar=$(render_bar "$seven_d" "$USAGE_BAR_WIDTH")
      printf "${uc}7d${R} %s ${uc}%s%%${R}" "$bar" "$seven_d"
    else
      printf "${uc}7d %s%%${R}" "$seven_d"
    fi
    [ "$SHOW_USAGE_RESET" = "1" ] && [ -n "$seven_d_reset" ] && { delta=$(compute_delta "$seven_d_reset"); [ -n "$delta" ] && printf " ${C_MONO_D}(%s)${R}" "$delta"; }
    h=1
  fi
  pr_extras " ${C_MONO_D}•${R} " "h"
  ;;

# ─────────────── MINIMAL: 1 riadok ───────────────
minimal)
  pr_model
  pr_folder "$SEP"
  pr_branch "$SEP"
  # inline bar (narrower)
  if [ "$SHOW_CONTEXT_BAR" = "1" ]; then
    printf "%b" "$SEP"
    bar=$(render_bar "$used_int" 8)
    ctx_c=$(usage_color "$used_int")
    printf "%s ${ctx_c}%s${R}" "$bar" "$ctx_str"
  fi
  h=1
  pr_usage "$SEP" "h"
  pr_tool "$SEP"
  pr_extras "$SEP" "h"
  ;;

# ─────────────── COMPACT: 2 riadky, husté ────────
compact)
  # line 1
  pr_model; pr_folder "$PIPE"; pr_branch "$SEP"
  pr_agent "$SEP"; pr_worktree "$SEP"; pr_tool "$PIPE"
  # line 2
  printf "\n"; h=0
  pr_ctx "$SEP" "h"; pr_usage "$SEP" "h"; pr_extras "$SEP" "h"
  ;;

# ─────────────── TOKYO: 3 riadky ─────────────────
tokyo)
  # line 1: folder • branch [+3 ~5]
  pr_folder ""; pr_branch "$SEP"
  pr_worktree "$SEP"
  # line 2: model [↳ agent] [⚡ tool]
  printf "\n"
  pr_model; pr_agent " "; pr_tool "$PIPE"
  # line 3: bar + limits + extras
  printf "\n"; h=0
  pr_ctx "$SEP" "h"; pr_usage "$SEP" "h"; pr_extras "$SEP" "h"
  ;;

# ─────────────── NERD: 2 riadky, emoji ───────────
nerd)
  # line 1: 🤖 model | 📁 folder • 🌿 branch [| ⚡ tool]
  pr_model; pr_folder "$PIPE"; pr_branch "$SEP"
  pr_agent "$SEP"; pr_worktree "$SEP"; pr_tool "$PIPE"
  # line 2: 🧠 bar XX% • ⏳ 5h • 📅 7d [• 💰 • ⏱️]
  printf "\n"; h=0
  pr_ctx "$SEP" "h"; pr_usage "$SEP" "h"; pr_extras "$SEP" "h"
  ;;

# ─────────────── DEFAULT: 2 riadky, čisté ────────
*)
  # line 1: model | folder • branch [↳ agent] [| ⚡ tool]
  pr_model; pr_folder "$PIPE"; pr_branch "$SEP"
  pr_agent "$SEP"; pr_worktree "$SEP"; pr_tool "$PIPE"
  # line 2: bar XX% (tokens) | 5h XX% (reset) • 7d XX% | extras
  printf "\n"; h=0
  pr_ctx "$PIPE" "h"; pr_usage "$PIPE" "h"; pr_extras "$SEP" "h"
  ;;

esac
