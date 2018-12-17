# Dot source this script in any Pester test script that requires the module to be imported.

$ProjectRoot = Split-Path $PSScriptRoot -Parent
if ($env:BHProjectName) {
    $ProjectName = $env:BHProjectName
}
else {
    $ProjectName = Split-Path $ProjectRoot -Leaf
}

$RootModuleFile = "$ProjectRoot\src\$ProjectName.psm1"
$ModuleManifestFile = "$ProjectRoot\src\$ProjectName.psd1"

if (-not $SuppressImportModule -and -not (Get-Module -Name $ProjectName -ErrorAction SilentlyContinue)) {
    Write-Host "Importing module [[ $RootModuleFile ]]" -ForegroundColor Cyan
    Get-Module -Name $ProjectName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $RootModuleFile -Scope Global -Force
}
