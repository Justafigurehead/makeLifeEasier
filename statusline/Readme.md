# cute-statusline

A small, dependency-free status line for Claude Code (Windows, macOS, Linux). Needs Node 16+.

```
✿ Sonnet 5.5  ·  📁 my-repo  ·  🌿 main  ·  ♥♥♥♡♡♡♡♡ 42%  ·  ⏳ 17%
```

| Segment | Meaning |
|---------|---------|
| ✿ model | Current model |
| 📁 folder | Working directory name |
| 🌿 branch | Git branch (hidden outside a repo) |
| ♥ bar | Context window used; green, then amber at 60%, red at 85% |
| ⏳ | 5-hour rate limit used (shown only when Claude Code reports it) |

## Install

```
node install.js
```

This copies `statusline.js` to `~/.claude/` and adds a `statusLine` entry to `~/.claude/settings.json`
(backup saved as `settings.json.bak`). It refuses to overwrite an existing status line unless you pass `--force`.
Start a new Claude Code session to see it.

## Customise

Edit the colour constants and the `parts.push(...)` lines in `~/.claude/statusline.js`.
Colours are 256-colour codes picked to read on both light and dark themes.

## Uninstall

Remove the `statusLine` block from `~/.claude/settings.json` and delete `~/.claude/statusline.js`.

## Notes

- Runs on every refresh, so the git call has a 1-second timeout and takes no optional locks.
- Field names (`context_window.used_percentage`, `rate_limits.five_hour`) come from Claude Code's status line input;
  a missing field just hides that segment.
