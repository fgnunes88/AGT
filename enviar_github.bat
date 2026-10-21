@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ================================================
echo   Reenviar o jogo para https://github.com/fgnunes88/AGT
echo   (envio grande: pode levar varios minutos - nao feche a janela)
echo ================================================
echo.
rem aguenta envios grandes e conexoes lentas
git config http.postBuffer 524288000
git config http.lowSpeedLimit 0
git config http.lowSpeedTime 999999
rem tira a pasta "Claude outputs" do repositorio (ela continua no seu PC)
git rm -r --cached --quiet "Claude outputs" 2>nul
git add -A
git commit -m "Remove pasta Claude outputs do repositorio" >nul 2>nul
echo Enviando... acompanhe a porcentagem abaixo.
git push -u origin main --progress
if errorlevel 1 (
  echo.
  echo O envio falhou. Copie as ultimas linhas acima e mande para o Claude.
  pause
  exit /b 1
)
echo.
echo ================================================
echo  Enviado! A branch "main" ja existe no GitHub.
echo ================================================
pause
