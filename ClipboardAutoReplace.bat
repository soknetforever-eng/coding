@echo off
setlocal
:: ============================================================
::  Clipboard Auto-Replace  (single file, Windows)
:: ============================================================
::  HOW TO USE
::   1. Edit the rules below, one per line, as FIND=REPLACE
::      (lines starting with "::" are treated as comments/rules,
::      everything else in this file is left alone).
::   2. Save this file, then double-click it to start watching
::      your clipboard.
::   3. Copy (Ctrl+C) anything containing FIND text, then Paste
::      (Ctrl+V) and you'll get the REPLACE version instead.
::   4. Editing the rules requires closing and re-running this
::      file to pick up the changes.
::   5. Close this window (or press Ctrl+C in it) to stop.
::
:: RULES START
:: 8888=TTTTT
:: 9999=TTTTT
:: 7777=TTTTT
:: 6666=TTTTT
:: 1111=TTTTT
:: 2222=TTTTT
:: 3333=TTTTT
:: 4444=TTTTT
:: 5555=TTTTT
:: RULES END
:: ============================================================

powershell -NoProfile -ExecutionPolicy Bypass -Sta -Command "$path='%~f0'; $lines=Get-Content -LiteralPath $path -Encoding UTF8; $inRules=$false; $map=[ordered]@{}; foreach($l in $lines){ $t=$l.Trim(); if($t -eq ':: RULES START'){ $inRules=$true; continue }; if($t -eq ':: RULES END'){ $inRules=$false; continue }; if($inRules){ if($t.StartsWith('::')){ $t=$t.Substring(2).Trim() }; if($t -eq ''){ continue }; $idx=$t.IndexOf('='); if($idx -lt 1){ continue }; $find=$t.Substring(0,$idx); $repl=$t.Substring($idx+1); if($find -ne ''){ $map[$find]=$repl } } }; Add-Type -AssemblyName System.Windows.Forms; Write-Host ('Clipboard auto-replace running with ' + $map.Count + ' rule(s) from this file.'); Write-Host 'Edit the rules and re-run this file to pick up changes. Press Ctrl+C to stop.'; $lastSeen=$null; $lastSet=$null; while($true){ Start-Sleep -Milliseconds 500; try{ if(-not [System.Windows.Forms.Clipboard]::ContainsText()){ continue }; $cur=[System.Windows.Forms.Clipboard]::GetText() } catch { continue }; if([string]::IsNullOrEmpty($cur)){ continue }; if($cur -eq $lastSeen -or $cur -eq $lastSet){ continue }; $lastSeen=$cur; $new=$cur; foreach($k in $map.Keys){ $new=$new.Replace($k,$map[$k]) }; if($new -ne $cur){ try{ [System.Windows.Forms.Clipboard]::SetText($new); $lastSet=$new; Write-Host 'Replaced clipboard text.' } catch { continue } } } }"

pause
