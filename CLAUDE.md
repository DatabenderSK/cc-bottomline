# CC Statusline

Vlastný konfigurovateľný statusline pre Claude Code. Zobrazuje model, projekt, git branch, kontext, API limity a ďalšie metriky.

## Tech Stack

- **Shell:** `sh` (POSIX) — hlavný statusline skript
- **Preview:** HTML + CSS — vizuálny katalóg tém
- **Config:** `.conf` (shell source) — modulárne zapínanie/vypínanie

## Štruktúra

```
scripts/           Shell skripty (statusline-command.sh, fetch-usage.sh, track-tool.sh)
themes/            Definície tém (.conf súbory pre rýchle prepínanie)
preview/           HTML preview stránka s vizuálnym katalógom dizajnov
```

## Inštalácia

Skripty sa kopírujú do `~/.claude/`. Config v `~/.claude/statusline.conf`.

## Konvencie

- Skripty musia byť POSIX `sh` kompatibilné (nie bash-only)
- Farby cez ANSI escape kódy (24-bit true color)
- Všetky moduly zapínateľné/vypínateľné cez config
- Témy menia len farby a ikony, nie logiku
