@echo off
setlocal
cd /d "%~dp0"
if exist "tools\Godot_v4.5.1-stable_win64.exe" (
  set "APPDATA=%~dp0tools"
  start "Vector Flight Lab" "tools\Godot_v4.5.1-stable_win64.exe" --path "%~dp0."
  exit /b 0
)
where godot >nul 2>nul
if %errorlevel% equ 0 (
  start "Vector Flight Lab" godot --path "%~dp0."
  exit /b 0
)
echo Open project.godot in Godot 4.5 or later, then press F6 or F5.
pause
