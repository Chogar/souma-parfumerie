@echo off
setlocal EnableExtensions

rem API Manager Souma Parfumerie — demarrage Windows (PC boutique)
rem Usage : scripts\start_manager_api.bat [port]

set "PORT=%~1"
if "%PORT%"=="" set "PORT=8080"

set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"
set "API=%ROOT%\api"
set "LOGDIR=%ROOT%\logs"
set "LOG=%LOGDIR%\manager_api.log"
set "PIDFILE=%LOGDIR%\manager_api.pid"

if not exist "%LOGDIR%" mkdir "%LOGDIR%"

call :log "=== Demarrage API Manager (port %PORT%) ==="

where php >nul 2>&1
if errorlevel 1 (
  call :log "ERREUR : PHP introuvable. Installez PHP 8.1+ et ajoutez-le au PATH."
  exit /b 1
)

if not exist "%API%\.env" (
  call :log "ERREUR : %API%\.env manquant. Copiez api\.env.example vers api\.env"
  exit /b 1
)

if not exist "%API%\vendor" (
  call :log "Installation des dependances Composer..."
  pushd "%API%"
  composer install --no-dev --no-interaction >> "%LOG%" 2>&1
  if errorlevel 1 (
    call :log "ERREUR : composer install a echoue"
    popd
    exit /b 1
  )
  popd
)

rem Verifier si l'API tourne deja
netstat -ano | findstr ":%PORT% " | findstr "LISTENING" >nul 2>&1
if not errorlevel 1 (
  call :log "Port %PORT% deja utilise — API probablement deja demarree."
  exit /b 0
)

rem Pause courte au demarrage Windows (PostgreSQL / Tailscale)
timeout /t 10 /nobreak >nul

:pg_ready
pushd "%API%"
call :log "Lancement php -S 0.0.0.0:%PORT% -t public"
echo %DATE% %TIME% > "%PIDFILE%"
php -S 0.0.0.0:%PORT% -t public >> "%LOG%" 2>&1
set "EXITCODE=%ERRORLEVEL%"
popd

call :log "Arret API (code %EXITCODE%)"
exit /b %EXITCODE%

:log
echo [%DATE% %TIME%] %~1
echo [%DATE% %TIME%] %~1>> "%LOG%"
exit /b 0
