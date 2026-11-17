@echo off
setlocal
cd /d "%~dp0"
if exist "tools\Godot_v4.5.1-stable_win64.exe" (
  set "APPDATA=%~dp0tools"
  start "Vector Flight Lab" "tools\Godot_v4.5.1-stable_win64.exe" --path "%~dp0." --rendering-method gl_compatibility
  exit /b 0
)
where godot >nul 2>nul
if %errorlevel% equ 0 (
  start "Vector Flight Lab" godot --path "%~dp0." --rendering-method gl_compatibility
  exit /b 0
)
echo Install Godot 4.5+ or put godot on PATH, then run this launcher again.
pause
