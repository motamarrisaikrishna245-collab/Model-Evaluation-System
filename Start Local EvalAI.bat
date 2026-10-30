@echo off
cd /d "%~dp0"
"%~dp0backend\.venv\Scripts\python.exe" "%~dp0start_evaluator.py"
pause
