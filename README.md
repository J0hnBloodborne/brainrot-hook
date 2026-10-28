# brainrot-hook

Opens Instagram Reels in Chrome while Claude Code or Codex works on your prompt, and switches back when the response is done. Windows only.

When you submit a prompt, the hook saves the window you are in and the front tab of each Chrome window. It then switches to an open Instagram tab, or opens Reels in a new tab if none is open. When the agent stops, it restores those tabs and focuses your original window.

It does nothing until you turn it on.

## Install

1. Put `brainrot.ps1` and `brainrot.cmd` in a folder on your `PATH` (for example `%USERPROFILE%\.local\bin`).
2. Add the hooks below, with the path changed to where you put `brainrot.ps1`.

### Claude Code

In `~/.claude/settings.json`:

```json
"hooks": {
  "UserPromptSubmit": [
    { "hooks": [{ "type": "command", "async": true,
      "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:/path/to/brainrot.ps1\" hook" }] }
  ],
  "Stop": [
    { "hooks": [{ "type": "command", "async": true,
      "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:/path/to/brainrot.ps1\" back" }] }
  ]
}
```

### Codex

Codex hooks are experimental. Turn them on in `~/.codex/config.toml`:

```toml
[features]
codex_hooks = true
```

Then create `~/.codex/hooks.json` with the same `UserPromptSubmit` and `Stop` entries as above (use `"timeout": 15` instead of `"async": true`).

## Usage

```
brainrot on       arm it
brainrot off      disarm it
brainrot status   show state
```

In Git Bash, type `brainrot.cmd on`.

## Notes

- Any Chrome tab with "Instagram" in its title counts as open Reels.
- Tabs are read through Windows UI Automation, so hidden tabs are found too.
- Windows can block background programs from taking focus. If that happens, the taskbar button flashes instead.
- Reels can start muted until you click the page once, because of Chrome's autoplay rule.
