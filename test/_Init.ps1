# Dot source this script in any Pester test script that requires the module to be imported.

if (-not $SuppressImportModule) {
    Write-Host "Importing module [[ $BHPSModuleManifest ]]" -ForegroundColor Cyan
    Get-Module -Name $BHProjectName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $BHPSModuleManifest -Scope Global -Force
}
