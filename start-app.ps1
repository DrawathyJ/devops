Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Starting DevOps Web Application..." -ForegroundColor Cyan
Write-Host " Local URL: http://localhost:3000" -ForegroundColor Green
Write-Host " Press Ctrl+C to stop the server at any time." -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan

Start-Process "http://localhost:3000"
python -m http.server 3000 --directory app
