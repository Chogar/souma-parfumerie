# Installe le demarrage automatique de l'API Manager au login Windows
# Executer en PowerShell :  .\scripts\install_manager_api_startup.ps1
# Desinstallation :        .\scripts\uninstall_manager_api_startup.ps1

$ErrorActionPreference = "Stop"

$TaskName = "SoumaParfumerie-ManagerAPI"
$Root = Split-Path -Parent $PSScriptRoot
$VbsPath = Join-Path $PSScriptRoot "start_manager_api_hidden.vbs"
$BatPath = Join-Path $PSScriptRoot "start_manager_api.bat"
$LogDir = Join-Path $Root "logs"

if (-not (Test-Path $BatPath)) {
  Write-Error "Fichier introuvable : $BatPath"
}

if (-not (Test-Path (Join-Path $Root "api\.env"))) {
  Write-Warning "api\.env absent — configurez la base avant le premier demarrage."
}

if (-not (Test-Path $LogDir)) {
  New-Item -ItemType Directory -Path $LogDir | Out-Null
}

$Action = New-ScheduledTaskAction `
  -Execute "wscript.exe" `
  -Argument "`"$VbsPath`"" `
  -WorkingDirectory $Root

# 1 minute apres la connexion (PostgreSQL + Tailscale ont le temps de demarrer)
$Trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME -Delay (New-TimeSpan -Seconds 60)

$Settings = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -StartWhenAvailable `
  -RestartCount 5 `
  -RestartInterval (New-TimeSpan -Minutes 2) `
  -ExecutionTimeLimit ([TimeSpan]::Zero)

$Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

$Existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($Existing) {
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

Register-ScheduledTask `
  -TaskName $TaskName `
  -Action $Action `
  -Trigger $Trigger `
  -Settings $Settings `
  -Principal $Principal `
  -Description "API Manager Souma Parfumerie — portail distant (telephone / PC)" | Out-Null

Write-Host ""
Write-Host "Tache planifiee installee : $TaskName" -ForegroundColor Green
Write-Host "  Demarrage : 1 min apres la connexion Windows"
Write-Host "  Portail   : http://127.0.0.1:8080/manager/"
Write-Host "  Logs      : $LogDir\manager_api.log"
Write-Host ""
Write-Host "Test immediat (optionnel) :"
Write-Host "  wscript.exe `"$VbsPath`""
Write-Host ""
