@echo off
:: Pro -> Home in-place edition switcher (Windows 11)
:: Version: 2025-08-21
:: Requires: mounted Windows 11 Home ISO
:: Run this file as Administrator

:: --- Elevate to Administrator (UAC) ---
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

setlocal EnableExtensions EnableDelayedExpansion

echo.
echo ===============================================================
echo   Windows 11 Pro -> Home (in-place) Edition Switcher
echo   This will tweak registry so Setup allows "Keep files and apps"
echo ===============================================================
echo.

:: --- Backup current edition registry keys ---
set "TS=%DATE:~-4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
set "TS=%TS: =0%"
set "BKP=%TEMP%\win11_edition_backup_%TS%.reg"
echo [1/4] Backing up registry to: %BKP%
reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" "%BKP%" /y >nul 2>&1

:: --- Set edition to Home ---
echo [2/4] Setting Edition to Home...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v EditionID /t REG_SZ /d Core /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName /t REG_SZ /d "Windows 11 Home" /f >nul
:: Best-effort extra fields (ignored if not present)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CompositionEditionID /t REG_SZ /d Core /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v EditionSku /t REG_DWORD /d 100 /f >nul 2>&1

:: --- Find Windows setup on mounted media ---
echo [3/4] Looking for setup.exe on mounted ISO...
set "SETUP="
for %%D in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\setup.exe" (
        if exist "%%D:\sources\install.wim" set "SETUP=%%D:\setup.exe"
        if exist "%%D:\sources\install.esd" set "SETUP=%%D:\setup.exe"
    )
)

if not defined SETUP (
    echo.
    echo   Could not find Windows 11 setup on mounted media.
    echo   -> Mount a Windows 11 Home ISO, then run this script again.
    echo   You can also run setup.exe manually afterwards.
    echo.
    echo   Registry backup is here: %BKP%
    pause
    exit /b 1
)

:: --- Launch setup (no /auto to let you confirm "Keep files and apps") ---
echo [4/4] Launching Windows 11 Setup from: %SETUP%
echo     When prompted, choose "Keep personal files and apps".
start "" "%SETUP%"

echo.
echo === Next steps ===============================================
echo 1) Complete the in-place upgrade to Windows 11 Home.
echo 2) After reboot, activate with a valid Windows 11 Home license.
echo    (Optional generic key to switch edition only, NOT for activation):
echo        slmgr /ipk YTMG3-N6DKC-DKB77-7M9GH-8HVX7
echo 3) If you encounter issues, restore the registry backup:
echo        reg import "%BKP%"
echo ===============================================================
echo.
pause
