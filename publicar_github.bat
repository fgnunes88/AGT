@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ================================================
echo   Publicar "Arthur, O Guardiao dos Tubaroes"
echo   no GitHub: https://github.com/fgnunes88/AGT
echo ================================================
echo.
where git >nul 2>nul
if errorlevel 1 (
  echo O Git nao esta instalado. Baixe em https://git-scm.com/download/win
  pause
  exit /b 1
)
if not exist ".git" (
  git init -b main
  git remote add origin https://github.com/fgnunes88/AGT.git
)
git config user.name >nul 2>nul || git config user.name "fgnunes88"
git config user.email >nul 2>nul || git config user.email "fgnunes.eu@gmail.com"
git add -A
git commit -m "Atualiza o jogo Arthur, O Guardiao dos Tubaroes" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
echo.
echo Enviando para o GitHub (pode abrir uma janela para fazer login)...
git push -u origin main
if errorlevel 1 (
  echo.
  echo O repositorio no GitHub ja tinha arquivos. Juntando e tentando de novo...
  git pull origin main --allow-unrelated-histories --no-rebase -X ours --no-edit
  git push -u origin main
)
echo.
echo ================================================
echo  Pronto! Falta so ativar o site (uma vez apenas):
echo  GitHub ^> repositorio AGT ^> Settings ^> Pages
echo  Source: Deploy from a branch / Branch: main / Pasta: /docs ^> Save
echo.
echo  Em 1 a 2 minutos o jogo estara em:
echo  https://fgnunes88.github.io/AGT/
echo ================================================
pause
