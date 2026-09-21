# Watches the Windows clipboard; whenever you copy text, applies FIND=REPLACE
# rules from replacements.txt and writes the result back to the clipboard.
# Edits to replacements.txt take effect on the next copy, no restart needed.

Add-Type -AssemblyName System.Windows.Forms

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$mapFile = Join-Path $scriptDir 'replacements.txt'

function Get-Replacements {
    $map = [ordered]@{}
    if (-not (Test-Path $mapFile)) { return $map }
    foreach ($line in Get-Content -Path $mapFile -Encoding UTF8) {
        $trimmed = $line.Trim()
        if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }
        $idx = $trimmed.IndexOf('=')
        if ($idx -lt 1) { continue }
        $find = $trimmed.Substring(0, $idx)
        $replace = $trimmed.Substring($idx + 1)
        if ($find -ne '') { $map[$find] = $replace }
    }
    return $map
}

Write-Host "Clipboard auto-replace running."
Write-Host "Rules file: $mapFile"
Write-Host "Edit it any time; changes apply on the next copy. Press Ctrl+C to stop."

$lastSeen = $null
$lastSet = $null

while ($true) {
    Start-Sleep -Milliseconds 500

    try {
        if (-not [System.Windows.Forms.Clipboard]::ContainsText()) { continue }
        $current = [System.Windows.Forms.Clipboard]::GetText()
    } catch {
        # Clipboard is briefly locked by another app; just retry next tick.
        continue
    }

    if ([string]::IsNullOrEmpty($current)) { continue }
    if ($current -eq $lastSeen -or $current -eq $lastSet) { continue }
    $lastSeen = $current

    $replacements = Get-Replacements
    $newText = $current
    foreach ($key in $replacements.Keys) {
        $newText = $newText.Replace($key, $replacements[$key])
    }

    if ($newText -ne $current) {
        try {
            [System.Windows.Forms.Clipboard]::SetText($newText)
            $lastSet = $newText
            Write-Host "Replaced clipboard text."
        } catch {
            continue
        }
    }
}
