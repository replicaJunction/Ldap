# PSDepend dependency file
# https://github.com/RamblingCookieMonster/PSDepend
#
# This file represents requirements for building the module.
#
# You can run this file by running the build task InstallDependencies.

@{
    BuildHelpers     = @{
        Version = 'latest'
        Target  = 'CurrentUser'
    }
    InvokeBuild      = @{
        Version = 'latest'
        Target  = 'CurrentUser'
    }
    Configuration    = @{
        Version = 'latest'
        Target  = 'CurrentUser'
    }
    Pester           = @{
        Version = 'latest'
        Target  = 'CurrentUser'
    }
    PSScriptAnalyzer = @{
        Version = 'latest'
        Target  = 'CurrentUser'
    }
    PlatyPS          = @{
        Version = 'latest'
        Target  = 'CurrentUser'
    }
    PowerShellGet    = @{
        Version = 'latest'
        Target  = 'CurrentUser'
    }
}