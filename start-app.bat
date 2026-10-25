@echo off
title DevOps Web Application Server
echo ========================================================
echo  Starting DevOps Web Application...
echo  Local URL: http://localhost:3000
echo  Press Ctrl+C in this terminal window to stop the server
echo ========================================================
start http://localhost:3000
python -m http.server 3000 --directory app
pause
