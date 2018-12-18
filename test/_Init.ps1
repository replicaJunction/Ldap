# Dot source this script in any Pester test script that requires the module to be imported.

if (-not $SuppressImportModule) {
    Write-Host "Importing module [[ $env:BHPSModuleManifest ]]" -ForegroundColor Cyan
    Get-Module -Name $env:BHProjectName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $env:BHPSModuleManifest -Scope Global -Force
}
