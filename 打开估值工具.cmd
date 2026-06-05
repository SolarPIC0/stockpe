@echo off
setlocal
cd /d "%~dp0"

set "PORT=8765"
set "URL=http://127.0.0.1:%PORT%/tools/pe_price_slider.html?v=historyfix4"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$port=%PORT%; " ^
  "$alive=$false; " ^
  "try { $r=Invoke-WebRequest -UseBasicParsing ('http://127.0.0.1:{0}/' -f $port) -TimeoutSec 1; $alive=($r.StatusCode -eq 200) } catch { $alive=$false }; " ^
  "if (-not $alive) { Start-Process -WindowStyle Hidden -FilePath python -ArgumentList @('-m','http.server', [string]$port, '--bind','127.0.0.1') -WorkingDirectory '%~dp0'; Start-Sleep -Milliseconds 900 }; " ^
  "Start-Process '%URL%'"

endlocal
