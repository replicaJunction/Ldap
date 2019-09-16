
##############################################################################
# DO NOT MODIFY THIS FILE!  Modify build.settings.ps1 instead.
##############################################################################

# This is an Invoke-Build build script.
# Version 2.0.1

Set-StrictMode -Version Latest

# Default task - used if -Task is not specified via command-line
Task . Init, Build, Test, Analyze

# Initialize build variables from the BuildHelpers module
# https://github.com/RamblingCookieMonster/BuildHelpers/issues/10
. Set-BuildVariable -Path (Split-Path $PSScriptRoot -Parent) -Scope Script

# Load settings file
$settingsFile = Join-Path -Path $PSScriptRoot -ChildPath "build.settings.ps1"
if (-not (Test-Path $settingsFile)) {
    throw "Unable to load build settings from path $settingsFile"
}
. "$settingsFile"

# Initialize other variables based on BuildHelpers and settings
$ArtifactModulePath = Join-Path -Path $ArtifactPath -ChildPath $BHProjectName
$ArtifactPsm1File = Join-Path -Path $ArtifactModulePath -ChildPath "$BHProjectName.psm1"
$ArtifactManifestFile = Join-Path -Path $ArtifactModulePath -ChildPath "$BHProjectName.psd1"

##############################################################################

Task Init {
    Write-Verbose "Build system details:`n$(Get-Variable 'BH*' | Out-String)"

    if (-not (Test-Path $ArtifactPath)) {
        $null = New-Item -Path $ArtifactPath -ItemType Directory -Force
    }

    Write-Verbose "Artifact path: [[ $ArtifactPath ]]"
}

Task Clean {
    Write-Verbose "Cleaning artifact directory"
    if (Test-Path $ArtifactPath) {
        Remove-Item -Path $ArtifactPath -Recurse -Force
    }

    $null = New-Item -Path $ArtifactPath -ItemType Directory -Force
}

#region Build
##############################################################################

Task Build Init, CreateMergedModule, CopyFiles, UpdateManifestFunctions, UpdateVersion

Task CreateMergedModule Init, {
    # https://evotec.xyz/powershell-single-psm1-file-versus-multi-file-modules/

    if (-not (Test-Path $ArtifactModulePath)) {
        $null = New-Item -Path $ArtifactModulePath -ItemType Directory -Force
    }

    # Create the file with UTF-8 encoding
    "" | Out-File $ArtifactPsm1File -Encoding UTF8 -Force

    Write-Verbose "Creating compiled module file at path $ArtifactPsm1File"
    Get-ChildItem -Path $BHModulePath -Filter "*.ps1" -Recurse | ForEach-Object {
        Write-Verbose "  * $($_.FullName)"
        $thisAst = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$null)
        $functions = $thisAst.EndBlock.Extent.Text + "`n"
        Write-Output $functions
    } | Add-Content $ArtifactPsm1File

    if ($ExtraModuleContent) {
        "$ExtraModuleContent".Trim() | Add-Content $ArtifactPsm1File
    }
}

Task CopyFiles 'Init', {
    Write-Verbose "Checking for extra files in output directory"
    Get-ChildItem -Path $ArtifactModulePath -File |
    Where-Object { -not (Get-ChildItem -Path $BHModulePath -Filter $_.Name ) } |
    ForEach-Object { Write-Verbose "Removing extra file $($_.Name)"; $_ } |
    Remove-Item -Force

    Write-Verbose "Copying additional files to module output directory"
    Get-ChildItem -Path $BHModulePath -File |
    Where-Object { $_.Name -ne "$BHProjectName.psm1" } |
    ForEach-Object { Write-Verbose "Copying file $($_.Name)"; $_ } |
    Copy-Item -Destination $ArtifactModulePath -Force
}

Task UpdateManifestFunctions Init, CopyFiles, CreateMergedModule, {
    $outputManifestFile = Join-Path -Path $ArtifactModulePath -ChildPath "$BHProjectName.psd1"

    # Load the version of the module from the working directory, not the compiled one
    # in the artifacts dir, because the compiled one no longer knows what's a public
    # function and what's a private one.

    $workingDirModule = Import-Module $BHPSModuleManifest -PassThru -Verbose:$false
    Set-ModuleFunctions -Name $outputManifestFile $workingDirModule.ExportedFunctions.Keys
    $workingDirModule | Remove-Module -Verbose:$false
}

Task UpdateVersion Init, CopyFiles, {
    $outputManifestFile = Join-Path -Path $ArtifactModulePath -ChildPath "$BHProjectName.psd1"
    if (-not (Test-Path $outputManifestFile)) {
        throw "Process failure: module manifest was not found at expected path [[ $outputManifestFile ]]. Ensure this file is being created properly by the CopyFiles task."
    }

    # BuildHelpers provides a BHBuildNumber variable whenever it can get one from the CI
    # environment.

    # If we're running locally, this will be 0.

    if (-not $BHBuildNumber) {
        Write-Verbose "No build number was found in the environment running the build (`$BHBuildNumber = 0). Not updating the module manifest's build version."
        return
    }

    $existingVersion = [Version] (Get-Metadata -Path $outputManifestFile)

    # If this repository doesn't use the fourth digit of a version number, then skip this step
    if ($existingVersion.Revision -eq -1) {
        Write-Verbose "Project version [$existingVersion] does not include a revision number, so it will not be updated."
        return
    }

    # If our build number has a dot in it, just remove it
    # For example, a build like 20190916.6 should become 201909166
    [int] $buildNumberInt = "$BHBuildNumber".Replace('.', '')

    $newVersion = New-Object -TypeName 'System.Version' -ArgumentList @(
        $existingVersion.Major
        $existingVersion.Minor
        $existingVersion.Build
        $buildNumberInt
    )

    Update-Metadata -Path $outputManifestFile -PropertyName 'ModuleVersion' -Value $newVersion
    Write-Verbose "Updated module version from $existingVersion to $newVersion"
}

##############################################################################
#endregion

#region Test
##############################################################################

Task Test Init, Build, RunTests, ConfirmTestsPassed

# The Test task is split into two components so that if the tests fail, the build engine
# can still produce a test results file before failing the build.

Task RunTests Init, {
    # If the module is installed to PSModulePath and we try to import it ourselves, Pester can
    # get really confused. Disabling this allows us to explicitly import the version of the
    # module we want to test.
    if (-not (Get-Variable 'PSModuleAutoLoadingPreference' -ValueOnly -Scope Global -ErrorAction SilentlyContinue)) {
        $oldModuleLoadingPreference = $null
    }
    else {
        $oldModuleLoadingPreference = $global:PSModuleAutoLoadingPreference
    }
    $global:PSModuleAutoLoadingPreference = 'None'

    Remove-Module $BHProjectName -Force -ErrorAction SilentlyContinue -Verbose:$false
    Import-Module $ArtifactManifestFile -Verbose:$false

    # Since we just disabled module auto-loading, we need to import Pester ourselves
    Import-Module Pester -ErrorAction Stop -Verbose:$false

    $pesterParams = @{
        Path         = $TestPath
        ExcludeTag   = $ExcludeTag
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

    $global:PSModuleAutoLoadingPreference = $oldModuleLoadingPreference
}

Task ConfirmTestsPassed Init, RunTests, {
    [xml] $xml = Get-Content -Path $PesterXmlResultFile -Raw

    # Fail build if any unit tests failed
    $failures = $xml.'test-results'.failures
    Assert ($failures -eq 0) ('Failed unit tests: {0}' -f $failures)

    # Fail build if code coverage is under required amount
    if (-not $CodeCoverageMinimum -or $CodeCoverageMinimum -le 0) {
        Write-Verbose "Code coverage is not enabled"
    }
    else {
        $json = Get-Content -Path $PesterJsonResultFile -Raw | ConvertFrom-Json

        $overallCoverage = [Math]::Round(($json.CodeCoverage.NumberOfCommandsExecuted /
                $json.CodeCoverage.NumberOfCommandsAnalyzed), 4)

        Assert ($overallCoverage -gt $CodeCoverageMinimum) ('Build requirement of {0:P2} code coverage was not met (analyzed coverage: {1:P2}' -f
            $overallCoverage, $CodeCoverageMinimum)
    }
}

##############################################################################
#endregion

#region Analyze
##############################################################################

# We analyze the "compiled" path, because analyzing the workspace path would give us warnings
# that we shouldn't use * in the FunctionsToExport key in the module manifest (.psd1 file).

Task Analyze -If { $EnableAnalyze } Init, Build, {
    $scriptAnalyzerParams = @{
        Path    = "$ArtifactModulePath"
        Recurse = $true
        Verbose = $false
    }

    if ($ScriptAnalysisSettingsFile) {
        $scriptAnalyzerParams['Settings'] = $ScriptAnalysisSettingsFile
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
        $terminatingItems = $scriptAnalysis | Where-Object { 'Error', 'Warning' -contains $_.Severity }
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

##############################################################################
#endregion

#region Build help with PlatyPS
##############################################################################

Task BuildHelp -If { $EnableBuildHelp } Init, Build, {
    Import-Module $ArtifactManifestFile -Verbose:$false

    if (-not (Test-Path $DocumentationPath)) {
        $null = New-Item -Path $DocumentationPath -ItemType Directory -Force

        $defaultLanguageDir = Join-Path -Path $DocumentationPath -ChildPath 'en-US'
        New-MarkdownHelp -Module $BHProjectName -OutputFolder $defaultLanguageDir
    }

    $languages = Get-ChildItem "$DocumentationPath" | Select-Object -ExpandProperty Name
    foreach ($lang in $languages) {
        $null = Update-MarkdownHelp -Path (Join-Path -Path $DocumentationPath -ChildPath $lang)
        Write-Verbose "Generating help for language [[ $lang ]]"
        $null = New-ExternalHelp -Path (Join-Path -Path $DocumentationPath -ChildPath $lang) -OutputPath (Join-Path -Path $ArtifactModulePath -ChildPath $lang) -Force
    }
}

##############################################################################
#endregion

#region Publish
##############################################################################

Task Publish -If { $PublishRepos.Count } Init, Build, Test, Analyze, BuildHelp, {
    Write-Verbose "Ensuring tools are present and up-to-date"

    $psGetModule = Import-Module PowerShellGet -PassThru -ErrorAction Stop -Verbose:$false
    Write-Verbose "Using PowerShell Get version $($psGetModule.Version)"

    foreach ($repo in $PublishRepos) {
        try {
            $needsApiKey = $false

            if ($repo -is [String]) {
                $repoName = "$repo"
                $branch = 'master'
            }
            elseif ($repo -is [Hashtable]) {
                $repoName = $repo.Repository

                if ($repo.NuGetApiKey) {
                    $needsApiKey = $true
                    Write-Verbose "Loading NuGet API key from variable $($repo.NuGetApiKey)"
                    $apiKey = Get-Item -Path "env:\$($repo.NuGetApiKey)" | Select-Object -ExpandProperty Value
                    if (-not $apiKey) {
                        throw "Failed to load NuGet API key from variable $($repo.NuGetApiKey)"
                    }
                }

                if ($repo.Branch) {
                    $branch = $repo.Branch
                }
                else {
                    $branch = 'master'
                }
            }
            else {
                throw "Unrecognized format for variable PublishRepos in settings file:`n`n$($repo | Out-String)"
            }

            if ($branch -and $BHBranchName -ne $branch) {
                Write-Warning "Repository $repoName is configured to publish branch $branch, and this build is for branch $BHBranchName. This build will not be published to $repoName"
                continue
            }

            $repoSourceUrl = Get-PSRepository -Name $repoName | Select-Object -ExpandProperty 'SourceLocation'
            $outputManifestFile = Join-Path -Path $ArtifactModulePath -ChildPath "$BHProjectName.psd1"
            $currentVersion = [Version] (Get-Metadata -Path $outputManifestFile)
            Write-Verbose "Checking repository $repoName to see if version $currentVersion can be published"

            $nextAvailableVersion = Get-NextNugetPackageVersion -Name $BHProjectName -PackageSourceUrl $repoSourceUrl
            if ($currentVersion -le $nextAvailableVersion) {
                throw "Cannot publish module version [$currentVersion] because the next available version to publish is [$nextAvailableVersion]"
            }
            Write-Verbose "Module version [$currentVersion] can be published (next available version: [$nextAvailableVersion])"

            $splat = @{
                Repository  = $repoName
                Path        = $ArtifactModulePath
                ErrorAction = 'Stop'
            }

            # Display the parameters before we add the API key
            Write-Verbose "Publishing module to repository $repoName with parameters:`n$($splat | Out-String)"

            if ($needsApiKey) {
                $splat['NuGetApiKey'] = $apiKey
                Write-Verbose "Using API key ending in $($apiKey.Substring($apiKey.Length - 4))"
            }

            Publish-Module @splat
        }
        catch {
            Write-Error $_
            Write-Error "Failed to publish to repo $($repo)"
        }
    }
}

##############################################################################
#endregion
