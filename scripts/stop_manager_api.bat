@echo off
setlocal EnableExtensions

rem Arrete le serveur PHP de l'API Manager sur le port 8080 (ou port passe en argument)

set "PORT=%~1"
if "%PORT%"=="" set "PORT=8080"

echo Recherche du processus sur le port %PORT%...

for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":%PORT% " ^| findstr "LISTENING"') do (
  echo Arret PID %%P
  taskkill /PID %%P /F >nul 2>&1
)

echo Termine.
pause
