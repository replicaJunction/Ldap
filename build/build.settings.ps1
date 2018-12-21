

###############################################################################
# Customize these properties and tasks for your module.
###############################################################################

# BuildHelpers makes these variables available:
#
# BHBranchName          - Name of the Git branch being built
# BHBuildNumber         - Build number according to CI system
# BHBuildSystem         - Build system in use (ex. AppVeyor, VSTS, etc.)
# BHCommitMessage       - Git commit message
# BHModulePath          - Path to the root of the module. Usually either "$BHProjectPath\$BHProjectName" or "$BHProjectPath\src"
# BHProjectName         - Name of the project, according to either directory name or CI project name
# BHProjectPath         - Path to the root of the project
# BHPSModuleManifest    - Path to the module manifest (.psd1) file

# Source paths in the project directory which need to be compiled
$FoldersToCompile = @(
    'Public'
    'Private'
)

# Additional files which should be copied - config files, etc.
$ExtraFilesToCopy = @(
    # 'config.json'
)

# # Any additional logic that needs to be in the module file
$ExtraModuleContent = @'
Set-StrictMode -Version Latest
'@

# Directory where build artifacts will be placed, including the "compiled" module and report files.
# Note - if you change this, you may want to change the path in the .gitignore file as well.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$ArtifactPath = "$BHProjectPath\artifacts"

# Path(s) where the module will be installed when running the Install task.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$InstallPaths = @(
    "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"
)


####################
# Script analysis
####################

# Set to false to disable use of PSScriptAnalyzer to analyze for best practices.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$EnableAnalyze = $true


####################
# Pester settings
####################

# Root directory where tests are found
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$TestPath = "$BHProjectPath\test"

# Pester output file, in NUnitXml format
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$PesterXmlResultFile = "$ArtifactPath\PesterResults.xml"

# Pester output file, in JSON format. This will contain code coverage specs.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$PesterJsonResultFile = "$ArtifactPath\PesterResults.json"

# Minimm acceptable code coverage percentage. Set to 0 to disable checking
# code coverage.
# This should be expressed as a decimal - 0.12 for 12%, 0.89 for 89%, etc.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$CodeCoverageMinimum = 0.00


####################
# platyPS settings
####################

# Set to false to disable use of platyPS for building help documents.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$EnableBuildHelp = $true


#####################
# Publish settings
#####################

# Repository(/ies) where the module should be published.
# If set to null or an empty array, the publish step will be skipped.
# Note that these repos must already exist on the system - this script
# will not create them.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$PublishRepos = @(
    @{
        Repository  = 'PSGallery'
        NuGetApiKey = $true
        Branch      = 'master'
    }
)

########################################################################

# To define a code hook, use -Before or -After and specify the task
# name. You can add a task that runs before or after any named task
# in the build script.

task DisableModuleAutoImport -Before RunTests {
    Write-Host "Disabling module auto-import" -ForegroundColor Magenta
    $global:PSModuleAutoLoadingPreference = 'None'

    # Since we've disabled module import, we need to manually import Pester
    Import-Module Pester
}

task EnableModuleAutoImport -After RunTests {
    Write-Host "Re-enabling module auto-import" -ForegroundColor Magenta
    $global:PSModuleAutoLoadingPreference = $null
}

# task PreInstall -Before Install {
#     Write-Host 'Pre-install task!'
# }

# task PostInstall -After Install {
#     Write-Host 'Post-install task!'
# }
