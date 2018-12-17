# This script can be run from within a CI environment to automatically
# resolve all build dependencies before kicking off the "main" Invoke-Build
# script.

function InstallAndImportModule([String] $ModuleName) {
    if (-not (Get-Module $ModuleName -ErrorAction SilentlyContinue) -and -not (Import-Module $ModuleName -ErrorAction SilentlyContinue)) {
        Install-Module -Name $ModuleName -Scope CurrentUser -Force -ErrorAction Stop
        Import-Module -Name $ModuleName -Global -Force -ErrorAction Stop
    }
}

try {
    InstallAndImportModule 'PSDepend'
}
catch {
    throw "Unable to install PSDepend. Script cannot continue."
}

Invoke-PSDepend -Path "$PSScriptRoot\Requirements.psd1" -Install -Force
Invoke-Build -File "$PSScriptRoot\UsbRemovable.build.ps1" -Task .

