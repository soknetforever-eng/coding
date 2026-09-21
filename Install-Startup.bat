@echo off
setlocal
:: ============================================================
::  Install ClipboardAutoReplace to run at Windows login
:: ============================================================
::  Creates a shortcut to ClipboardAutoReplace.bat in your
::  personal Startup folder (the same folder "Win+R > shell:startup"
::  opens). It will then launch automatically every time you log
::  in, the same way it runs when you double-click it yourself.
::
::  Keep this file in the SAME folder as ClipboardAutoReplace.bat.
::  To remove it later, run Uninstall-Startup.bat.
:: ============================================================

set "TARGET=%~dp0ClipboardAutoReplace.bat"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "LINK=%STARTUP%\ClipboardAutoReplace.lnk"

if not exist "%TARGET%" (
    echo Could not find ClipboardAutoReplace.bat next to this installer.
    echo Make sure both files are in the same folder, then try again.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%LINK%'); $s.TargetPath='%TARGET%'; $s.WorkingDirectory='%~dp0'; $s.Save()"

if exist "%LINK%" (
    echo Done. ClipboardAutoReplace will now start automatically when you log in.
    echo Shortcut created at:
    echo   %LINK%
    echo.
    echo To stop it from starting automatically, run Uninstall-Startup.bat
    echo or delete that shortcut yourself.
) else (
    echo Something went wrong - the shortcut was not created.
)

pause
