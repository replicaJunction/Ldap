

##############################################################################
# DO NOT MODIFY THIS FILE!  Modify build.settings.ps1 instead.
##############################################################################

# This is an Invoke-Build build script.
# Version 1.6.0

# $ProjectRoot = Split-Path $PSScriptRoot -Parent
# $ProjectName = Split-Path $ProjectRoot -Leaf

Set-StrictMode -Version Latest

task . Init, Analyze, Test, Build, Install
task AzureDevOps Init, Analyze, Test, Build, Publish

# https://github.com/RamblingCookieMonster/BuildHelpers/issues/10
# Set-BuildEnvironment -Path (Split-Path $PSScriptRoot -Parent)
. Set-BuildVariable -Path (Split-Path $PSScriptRoot -Parent) -Scope Script

# Load Settings file
$settingsFile = "$PSScriptRoot\build.settings.ps1"
if (-not (Test-Path $settingsFile)) {
    throw "Unable to locate settings file at path $settingsFile"
}
. "$settingsFile"

# Load library file
$libFile = "$PSScriptRoot\lib.ps1"
if (-not (Test-Path $libFile)) {
    throw "Unable to locate module library file at path $libFile"
}
. "$libFile"

# Init other variables based on Settings

# Path where the compiled module will be placed
$OutputPath = "$ArtifactPath\$BHProjectName"

########################################################################

task InstallDependencies {
    if (-not (Get-Module PSDepend -ErrorAction SilentlyContinue) -and -not (Import-Module PSDepend)) {
        Install-Module -Name PSDepend -Scope CurrentUser -Force
    }

    assert (Get-Module PSDepend) ("PSDepend module could not be found.")

    Invoke-PSDepend -Path "$PSScriptRoot\Requirements.psd1" -Install -Force
}

########################################################################

task Init {
    Write-Verbose "Build system details:`n$(Get-Variable 'BH*' | Out-String)"

    if (-not (Test-Path $ArtifactPath)) {
        New-Item -Path $ArtifactPath -ItemType Directory -Force | Out-Null
    }
}

task Clean Init, {
    if (Test-Path -Path $OutputPath) {
        Remove-Item -Path "$OutputPath/*" -Recurse -Force
    }

    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

#region Analyze
########################################################################

task Analyze Init, {
    if (-not $EnableAnalyze) {
        Write-Verbose "Script analysis is not enabled."
        return
    }

    $scriptAnalyzerParams = @{
        Path     = "$BHModulePath"
        Recurse  = $true
        Settings = "$BHProjectPath\PSScriptAnalyzerSettings.psd1"
        Verbose  = $false
    }

    Write-Verbose "Parameters for Invoke-ScriptAnalyzer:`n$($scriptAnalyzerParams | Out-String)"
    $scriptAnalysis = Invoke-ScriptAnalyzer @scriptAnalyzerParams
    $scriptAnalysis | ConvertTo-Json | Out-File "$ArtifactPath\ScriptAnalysis.json" -Force

    # We want to show all rules, but only fail the build if there are
    # errors or warnings
    if (-not $scriptAnalysis) {
        Write-Verbose "Invoke-ScriptAnalyzer returned no hits - everything is good!"
    }
    else {
        $scriptAnalysis | Format-Table -AutoSize
        $terminatingItems = $scriptAnalysis | Where-Object {'Error', 'Warning' -contains $_.Severity}
        if ($terminatingItems) {
            if (@($terminatingItems).Count -gt 1) {
                $msg = "PSScriptAnalyzer found $($terminatingItems.Count) failing rules."
            }
            else {
                $msg = 'PSScriptAnalyzer found 1 failing rule.'
            }

            throw $msg
        }
    }
}

########################################################################
#endregion

#region Test
########################################################################

# Test task is split in two so that if tasks fail, the engine can produce
# a test results file before failing the build
task Test Init, RunTests, ConfirmTestsPassed

task RunTests Init, {
    $pesterParams = @{
        Path         = $TestPath
        PassThru     = $true
        OutputFile   = $PesterXmlResultFile
        OutputFormat = "NUnitXml"
    }

    if ($CodeCoverageMinimum -and $CodeCoverageMinimum -gt 0) {
        $pesterParams['CodeCoverage'] = @(Get-ChildItem -Path $BHModulePath -Filter '*.ps1' -Recurse | Select-Object -ExpandProperty FullName)
    }

    Write-Verbose "Parameters for Invoke-Pester:`n$($pesterParams | Out-String)"
    $testResults = Invoke-Pester @pesterParams
    $testResults | ConvertTo-Json -Depth 5 | Out-File $PesterJsonResultFile -Force

    # If running in a CI environment, publish tests results here
    if ($BHBuildSystem -eq 'AppVeyor') {
        Write-Verbose "Publishing Pester results"
        Add-TestResultToAppveyor $PesterXmlResultFile
    }
}

task ConfirmTestsPassed Init, RunTests, {
    [xml] $xml = Get-Content -Path $PesterXmlResultFile -Raw

    # Fail build if any unit tests failed
    $failures = $xml.'test-results'.failures
    assert ($failures -eq 0) ('Failed unit tests: {0}' -f $failures)

    # Fail build if code coverage is under required amount
    if (-not $CodeCoverageMinimum -or $CodeCoverageMinimum -le 0) {
        Write-Verbose "Code coverage is not enabled"
    }
    else {
        $json = Get-Content -Path $PesterJsonResultFile -Raw | ConvertFrom-Json

        $overallCoverage = [Math]::Round(($json.CodeCoverage.NumberOfCommandsExecuted /
                $json.CodeCoverage.NumberOfCommandsAnalyzed), 4)

        assert ($overallCoverage -gt $CodeCoverageMinimum) ('Build requirement of {0:P2} code coverage was not met (analyzed coverage: {1:P2}' -f
            $overallCoverage, $CodeCoverageMinimum)
    }
}

########################################################################
#endregion

#region Build
########################################################################

task Build Init, UpdateManifestVersion, CopyFiles, UpdateManifestFunctions, CommitNewManifest

task UpdateManifestVersion Init, {
    # Get manifest contents and look for the current build number
    $manifestContent = (Get-Content $BHPSModuleManifest -Raw).Trim()
    if ($manifestContent -notmatch '(?<=ModuleVersion\s+=\s+'')(?<ModuleVersion>.*)(?='')') {
        throw "Module version was not found in manifest file $BHPSModuleManifest"
    }
    $script:ModuleVersion = [Version] ($Matches.ModuleVersion)

    # For writing, we need to reference variables with the script: prefix.
    # For reading, this prefix isn't necessary.

    if ($BHBuildNumber -gt 0) {
        Write-Verbose "Using build number $BHBuildNumber from CI"
        $script:BuildNumber = $BHBuildNumber
    }
    else {
        $script:BuildNumber = $ModuleVersion.Revision + 1
        Write-Verbose "Using build number $BuildNumber from existing manifest"
    }

    $newVersion = New-Object -TypeName System.Version -ArgumentList $ModuleVersion.Major, $ModuleVersion.Minor, $ModuleVersion.Build, $BuildNumber

    Write-Verbose "Updating module manifest version from $ModuleVersion to $newVersion"
    Update-Metadata -Path $BHPSModuleManifest -PropertyName ModuleVersion -Value $newVersion
}

task CopyFiles Init, Clean, {
    # Copy items to release folder
    # Get-ChildItem $BHModulePath | Copy-Item -Destination $OutputPath -Recurse -Force

    Copy-Item -Path (Join-Path $BHModulePath "$BHProjectName.psd1") -Destination $OutputPath -Force
    foreach ($f in $ExtraFilesToCopy) {
        Write-Verbose "Copying file [[ $f ]]"
        Copy-Item -Path (Join-Path $BHModulePath $f) -Destination $OutputPath -Force
    }

    $splat = @{
        ModuleSource       = $BHModulePath
        Directory          = $FoldersToCompile
        OutputFile         = Join-Path -Path $OutputPath -ChildPath "$BHProjectName.psm1"
        ExtraModuleContent = $ExtraModuleContent
        Verbose            = $VerbosePreference
    }

    Merge-Module @splat
}

task UpdateManifestFunctions Init, CopyFiles, {
    $outputManifestFile = Join-Path $OutputPath "$BHProjectName.psd1"

    # Load the version of the module from the working directory, not the compiled one
    # in the artifacts dir, because the compiled one no longer knows what's a public
    # function and what's a private one.

    $workingDirModule = Import-Module $BHPSModuleManifest -PassThru
    Set-ModuleFunctions -Name $outputManifestFile $workingDirModule.ExportedFunctions.Keys
    $workingDirModule | Remove-Module
}

task CommitNewManifest {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warning "git.exe could not be found; not committing changes to the module manifest file"
        return
    }

    git add (Join-Path $BHModulePath "$BHProjectName.psd1")
    git commit --amend --no-edit --quiet
}

########################################################################
#endregion

#region platyPS - Build Help
########################################################################

task CreateHelp {
    Import-Module -Name "$BHPSModuleManifest" -Force
    $splat = @{
        Module         = $BHProjectName
        OutputFolder   = "$BHProjectPath\docs\en-US"
        Locale         = "en-US"
        WithModulePage = $true
        Force          = $true
    }

    New-MarkdownHelp @splat
}

task BuildHelp Init, Build, {
    if (-not $EnableBuildHelp) {
        Write-Verbose "Building help via platyPS is not enabled."
        return
    }

    Import-Module -Name "$OutputPath\$BHProjectName.psd1"
    $languages = Get-ChildItem "$BHProjectPath\docs" | Select-Object -ExpandProperty Name
    foreach ($lang in $languages) {
        Update-MarkdownHelp -Path "$BHProjectPath\docs\$lang" | Out-Null
        Write-Verbose "Generating help for language [[ $lang ]]"
        New-ExternalHelp -Path "$BHProjectPath\docs\$lang" -OutputPath "$OutputPath\$lang" -Force | Out-Null
    }
}

########################################################################
#endregion

#region Install / Publish
########################################################################

task Install Init, Analyze, Test, Build, BuildHelp, {
    foreach ($path in $InstallPaths) {
        $thisModulePath = Join-Path -Path $path -ChildPath $BHProjectName
        if (Test-Path $thisModulePath) {
            Remove-Item -Path $thisModulePath -Recurse -Force
        }
        New-Item -Path $thisModulePath -ItemType Directory | Out-Null

        Write-Verbose "Installing to path [[ $path ]]"

        Get-ChildItem $OutputPath | Copy-Item -Destination $thisModulePath -Recurse -Force
    }
}

task Publish Init, Analyze, Test, Build, BuildHelp, {
    if (-not $PublishRepos) {
        Write-Verbose "No repositories were defined in the `$PublishRepos variable in settings file [[ $settingsFile ]]."
        Write-Verbose "To publish the module, define one or more repositories here."
    }

    foreach ($repo in $PublishRepos) {
        try {
            $repoName = $repo.Repository
            $splat = @{
                repository  = $repoName
                Path        = $OutputPath
                ErrorAction = 'Stop'
            }

            if ($repo.Branch -and $BHBranchName -ne $repo.Branch) {
                Write-Warning "Repository $repoName is configured to only publish branch $($repo.Branch), and this build is for branch $BHBranchName. Module will not be published."
                return
            }

            # Display the parameters before we add the API key, for security
            Write-Verbose "Publishing module to repository $repoName with params:`n$($splat | Out-String)"

            if ($repo.NuGetApiKey) {
                Write-Verbose "Reading key for repo $repoName"
                $repoKey = Get-ApiKey -ErrorAction Stop
                $splat['NuGetApiKey'] = $repoKey
            }

            Publish-Module @splat
        }
        catch {
            Write-Error "Failed to publish to repo ${repo}: $_"
        }
    }
}

########################################################################
#endregion
