# Clipboard Auto-Replace (Windows)

Watches your clipboard, and whenever you copy text it runs it through a list
of find/replace rules and puts the corrected text back on the clipboard —
so pasting always gives you the saved version, not the original copy.

## Files

- `AutoReplace.ps1` — the watcher script.
- `replacements.txt` — your rules, one per line: `FIND=REPLACE`.
- `Start-AutoReplace.bat` — double-click to run with a visible console window (shows what's being replaced; close the window to stop).
- `Start-AutoReplace-Silent.vbs` — double-click to run in the background with no window.

## Setup

1. Open `replacements.txt` and add your rules, one per line:

   ```
   teh=the
   old-email@example.com=new-email@example.com
   ```

   - Lines starting with `#` are comments.
   - Matching is case-sensitive and matches anywhere in the copied text (not just whole words).
   - You can add or edit rules while the watcher is running — changes apply on your next copy, no restart needed.

2. Double-click `Start-AutoReplace.bat` (visible) or `Start-AutoReplace-Silent.vbs` (background, no window).

3. Copy (Ctrl+C) any text containing something from `replacements.txt`. Paste (Ctrl+V) — you'll get the replaced version.

## Run automatically at Windows startup (optional)

1. Press `Win+R`, type `shell:startup`, press Enter.
2. Copy `Start-AutoReplace-Silent.vbs` into that folder (or create a shortcut to it there).
3. It will now start silently every time you log in.

## Stopping it

- Visible mode: close the console window (or press Ctrl+C inside it).
- Silent mode: open Task Manager, find `powershell.exe`, and end the task — or use `taskkill /IM powershell.exe /F` (careful: this ends *all* running PowerShell processes).

## Notes

- Only plain text on the clipboard is affected; copied files/images are left alone.
- If PowerShell scripts are blocked on your machine, the `.bat` launcher already passes `-ExecutionPolicy Bypass` so it works without changing system-wide settings.
