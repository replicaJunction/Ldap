

###############################################################################
# Customize these properties and tasks for your module.
###############################################################################

# Settings for build script version 2.0.1

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

# Additional files which should be copied - config files, etc.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$ExtraFilesToCopy = @()

# Any additional logic that needs to be in the module file
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$ExtraModuleContent = 'Set-StrictMode -Version Latest'

# Directory where build artifacts will be placed, including the "compiled" module and report files.
# Note - if you change this, you may want to change the path in the .gitignore file as well.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$ArtifactPath = "$BHProjectPath\Artifacts"

# Path(s) where the module will be installed when running the Install task.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$InstallPaths = @()


####################
# Script analysis
####################

# Set to false to disable use of PSScriptAnalyzer to analyze for best practices.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$EnableAnalyze = $true

# Path to a custom .psd1 file for script analyzer settings. Set to $null to use default settings.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$ScriptAnalysisSettingsFile = $null


####################
# Pester settings
####################

# Root directory where tests are found
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$TestPath = "$BHProjectPath\test"

# Exclude any tests with these tags when running
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$ExcludeTag = @(
    'Integration'
)

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

# Documentation path for the project
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$DocumentationPath = "$BHProjectPath\docs"


#####################
# Publish settings
#####################

# Repository(/ies) where the module should be published.
# If set to null or an empty array, the publish step will be skipped.
# Note that these repos must already exist on the system - this script
# will not create them.

# There are two formats that can be used for these values:
#
# 1. String value
# If a simple string is provided, it will be assumed to be the name of the repository.
# Code will only be published on the master branch.
#
# 2. Hashtable
#
# @{
#     Repository  = 'PSGallery'
#     NuGetApiKey = 'env:NuGetApiKey'
#     Branch      = 'master'
# }

[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$PublishRepos = @(
    @{
        Repository  = 'PSGallery'
        NuGetApiKey = 'env:PSGalleryApiKey'
        Branch      = 'master'
    }
)

########################################################################

# To define a code hook, use -Before or -After and specify the task
# name. You can add a task that runs before or after any named task
# in the build script.

# task PreInstall -Before Install {
#     Write-Host 'Pre-install task!'
# }

# task PostInstall -After Install {
#     Write-Host 'Post-install task!'
# }
