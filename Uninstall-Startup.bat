@echo off
setlocal
:: ============================================================
::  Remove ClipboardAutoReplace from Windows login startup
:: ============================================================
::  Deletes the startup shortcut created by Install-Startup.bat.
::  This does not stop a copy that's already running - close its
::  taskbar window (or end powershell.exe in Task Manager) too.
:: ============================================================

set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "LINK=%STARTUP%\ClipboardAutoReplace.lnk"

if exist "%LINK%" (
    del "%LINK%"
    echo Removed startup shortcut:
    echo   %LINK%
    echo ClipboardAutoReplace will no longer start automatically at login.
) else (
    echo No startup shortcut found - nothing to remove.
)

pause
