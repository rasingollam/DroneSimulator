@echo off
setlocal
cd /d "%~dp0"
python android-controller\serve_apk.py
pause
