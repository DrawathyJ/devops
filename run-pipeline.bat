@echo off
title DevOps Local Pipeline Simulation
echo ========================================================
echo  Running Local Pipeline Simulation...
echo ========================================================
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-pipeline.ps1"
echo.
pause

