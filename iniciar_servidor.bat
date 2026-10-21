@echo off
chcp 65001 >nul
cd /d "%~dp0docs"
echo ================================================
echo   Servidor local do jogo (pasta docs)
echo ================================================
where python >nul 2>nul
if errorlevel 1 (
  echo O Python nao esta instalado. Baixe em https://www.python.org/downloads/
  pause
  exit /b 1
)
start "Servidor do jogo - nao feche esta janela" python -m http.server 8080
timeout /t 2 >nul
start "" http://localhost:8080
echo.
echo Jogo aberto em http://localhost:8080 (so neste PC).
echo.
where cloudflared >nul 2>nul
if errorlevel 1 (
  echo Para abrir para outras pessoas pela internet, instale o cloudflared:
  echo    winget install --id Cloudflare.cloudflared
  echo e rode este arquivo de novo.
  pause
  exit /b 0
)
echo Abrindo o tunel do Cloudflare. Procure abaixo o link
echo https://....trycloudflare.com e envie para quem vai jogar.
echo Para desligar, feche esta janela e a do servidor.
echo.
cloudflared tunnel --url http://localhost:8080
pause
