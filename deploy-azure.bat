@echo off
title Azure Automated Deployment
echo ========================================================
echo  Deploying Web Application to Microsoft Azure...
echo ========================================================
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy-azure.ps1"
pause

