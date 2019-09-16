[CmdletBinding()]
param(
    [Parameter()]
    [Switch] $SkipDependencyCheck
    ,

    [Parameter()]
    [Switch] $Clean
    ,

    [Parameter()]
    [Switch] $Publish
)

if ($SkipDependencyCheck) {
    Write-Verbose "Skipping dependency check"
}
else {
    Write-Verbose "Ensuring NuGet.exe is available"
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser

    if (Get-Module 'PSDepend' -ErrorAction SilentlyContinue) {
        Write-Verbose "Module PSDepend is already available"
    }
    elseif (Import-Module 'PSDepend' -PassThru -Verbose:$false -ErrorAction SilentlyContinue) {
        Write-Verbose "Successfully imported PSDepend"
    }
    else {
        Write-Verbose "Attempting to install PSDepend"
        Install-Module 'PSDepend' -Repository PSGallery -Scope CurrentUser -Force -ErrorAction Stop

        if (-not (Import-Module 'PSDepend' -PassThru -Verbose:$false -ErrorAction SilentlyContinue)) {
            throw "Unable to import or install module PSDepend. Build script cannot continue."
        }
    }

    Write-Verbose "Checking requirements with PSDepend"
    Invoke-PSDepend -Path "$PSScriptRoot\Requirements.psd1" -Install -Force
}

if ($Clean) {
    $tasks = @('Clean', '.')
}
else {
    $tasks = @('.')
}

if ($Publish) {
    $tasks = $tasks + 'Publish'
}

Write-Verbose "Transferring control to Invoke-Build"
Invoke-Build -File "$PSScriptRoot\build.script.ps1" -Task $tasks -Verbose:$VerbosePreference
