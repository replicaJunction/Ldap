[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
$SuppressImportModule = $true
. $PSScriptRoot\_Init.ps1

Describe 'Module Manifest Tests' {
    It "Passes Test-ModuleManifest (module file $BHPSModuleManifest)" {
        Test-ModuleManifest -Path $BHPSModuleManifest
        $? | Should Be $true
    }
}

