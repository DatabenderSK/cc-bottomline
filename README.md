# CC Bottomline

Configurable status line for [Claude Code](https://code.claude.com) with **11 themes**, color-coded thresholds, and modular design.

See your model, project, git branch, context window, and API usage limits — all at a glance.

```
Opus 4.6 (1M) | 📁 my-app • main | ⚡ Bash
ctx 8% (82k/1000k) | 5h ██░░░░░░ 28% (3h 14m) • 7d █░░░░░░░ 12% (5d 8h)
```

When limits get high, colors change automatically:

```
ctx 45% (450k/1000k) | 5h ██████░░ 72% (1h 38m) • 7d ███████░ 85% (19h)
                        ~~~~~~ yellow              ~~~~~~~ red bold
```

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/DatabenderSK/cc-bottomline/main/install.sh | bash
```

Or manually: copy `scripts/` files to `~/.claude/` and add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

**Requirements:** `jq` (for JSON parsing), macOS or Linux.

## Themes

Change theme in `~/.claude/statusline.conf`:

```sh
THEME=hybrid
```

Restart Claude Code to apply. [Preview all themes →](preview/index.html)

### Hybrid *(default)*

Colored first line, monochrome second line. Colors appear only when thresholds are exceeded.

```
Opus 4.6 (1M) | 📁 LAB • main | ⚡ Bash           ← colored
ctx 8% (82k/1000k) | 5h ██░░░░░░ 28% (3h) • 7d █░░░░░░░ 12%   ← monochrome
```

### Monochrome

All gray. Color only appears when limits are high.

```
Opus 4.6 (1M) | 📁 LAB • main | ⚡ Bash
ctx 8% (82k/1000k) | 5h ██░░░░░░ 28% (3h) • 7d █░░░░░░░ 12%
```

### Brackets

Single line, tmux-inspired.

```
[Opus] [📁 LAB] [main] [ctx 8%] [5h 28%] [7d 12%]
```

### Minimal

Single line, no icons, just the essentials.

```
Opus 4.6 (1M) · LAB · main · ctx 8% · 5h 28% · 7d 12%
```

### Default

Full colors on both lines with progress bars.

```
Opus 4.6 (1M) | 📁 LAB • main | ⚡ Bash
ctx 8% (82k/1000k) | 5h ██░░░░░░ 28% (3h) | 7d █░░░░░░░ 12% (5d)
```

### Nerd

Emoji icons on every module. Catppuccin color palette.

```
🤖 Opus 4.6 (1M) │ 📁 LAB │ 🌿 main │ ⚡ Bash
🧠 ctx 8% (82k/1000k) │ ⏳ 5h ██░░░░░░ 28% │ 📅 7d █░░░░░░░ 12%
```

### Compact

Two lines, dense, no reset times.

```
Opus 4.6 (1M) | 📁 LAB • main | ⚡ Bash
ctx 8% • 5h ██░░░░ 28% • 7d █░░░░░ 12%
```

### Tokyo Night

Three lines, Tokyo Night color palette.

```
📁 LAB • main
Opus 4.6 (1M) | ⚡ Bash
ctx 8% (82k/1000k) • 5h ██░░░░░░ 28% (3h) • 7d █░░░░░░░ 12% (5d)
```

More themes in the [HTML preview](preview/index.html): Cyberpunk, Material, Clean.

## Modules

Toggle any module in `~/.claude/statusline.conf`:

```sh
# Line 1 — identity
SHOW_MODEL=1              # model name (Opus 4.6, Sonnet, ...)
SHOW_FOLDER=1             # 📁 project folder
SHOW_BRANCH=1             # git branch
SHOW_GIT_STATUS=0         # staged/modified counts (+3 ~5)
SHOW_TOOL=1               # current tool (⚡ Bash, Read, ...)
SHOW_AGENT=0              # sub-agent name
SHOW_WORKTREE=0           # worktree info

# Line 2 — metrics
SHOW_CONTEXT=1            # context window %
SHOW_CONTEXT_BAR=0        # visual progress bar for context
SHOW_CONTEXT_TOKENS=1     # tokens (234k/1000k)
SHOW_USAGE_5H=1           # 5-hour API limit
SHOW_USAGE_7D=1           # 7-day API limit
SHOW_USAGE_BAR=1          # progress bars for limits ████░░░░
SHOW_USAGE_RESET=1        # time until reset (3h 24m)
SHOW_DURATION=0           # session duration (7m 3s)
SHOW_LINES_CHANGED=0      # lines added/removed (+156 -23)
SHOW_COST=0               # session cost ($X.XX)
SHOW_VERSION=0            # Claude Code version
```

## Color thresholds

Usage and context automatically change color:

| Range | Color |
|-------|-------|
| 0–59% | Green (or gray in hybrid/monochrome) |
| 60–79% | Yellow |
| 80%+ | Red bold |

## Usage fetch

API limits (5h/7d) are fetched from the Anthropic API and cached. The fetch interval is configurable:

```sh
USAGE_FETCH_TTL=1800   # 1800 = 30 min (default), 3600 = 1 hour
```

The script reads your Claude Code credentials from the macOS keychain. No API key needed.

## Files

| File | Purpose |
|------|---------|
| `statusline-command.sh` | Main statusline script (receives JSON via stdin) |
| `statusline.conf` | Configuration (themes, modules, intervals) |
| `fetch-usage.sh` | Fetches 5h/7d API usage limits |
| `track-tool.sh` | Tracks currently active tool |

## Uninstall

Remove the files and the `statusLine` entry from settings:

```sh
rm ~/.claude/statusline-command.sh ~/.claude/statusline.conf
rm ~/.claude/fetch-usage.sh ~/.claude/track-tool.sh
```

Then remove `"statusLine"` from `~/.claude/settings.json`.

## License

MIT

## Credits

Inspired by [cship](https://github.com/stephenleo/cship) and the [Claude Code statusline API](https://code.claude.com/docs/en/statusline).
