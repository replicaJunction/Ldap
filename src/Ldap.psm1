Set-StrictMode -Version Latest

# Get public and private function definition files.
$Public = @( Get-ChildItem $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )
# $ArgumentCompleters = Get-ChildItem -Path "$PSScriptRoot\Scripts\*.ArgumentCompleters.ps1"

# Dot source the files
foreach ($import in @($Public + $Private)) {
    try {
        . $import.fullname
    }
    catch {
        Write-Error "Failed to import function $($import.fullname): $_"
    }
}

# Export the public functions
Export-ModuleMember -Function ($Public | Select-Object -ExpandProperty Basename)
