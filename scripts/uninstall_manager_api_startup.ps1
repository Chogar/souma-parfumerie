# Supprime le demarrage automatique de l'API Manager
# Executer en PowerShell : .\scripts\uninstall_manager_api_startup.ps1

$ErrorActionPreference = "Stop"
$TaskName = "SoumaParfumerie-ManagerAPI"

$Existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if (-not $Existing) {
  Write-Host "Aucune tache '$TaskName' trouvee."
  exit 0
}

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
Write-Host "Tache '$TaskName' supprimee." -ForegroundColor Green
Write-Host "L'API ne demarrera plus automatiquement au login."
Write-Host "Pour arreter une instance en cours, fermez le processus php.exe ou redemarrez le PC."
