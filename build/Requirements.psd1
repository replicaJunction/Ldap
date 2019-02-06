# PSDepend dependency file
# https://github.com/RamblingCookieMonster/PSDepend
#
# This file represents requirements for building the module.
#
# You can run this file by running the build task InstallDependencies.

@{
    BuildHelpers     = @{
        # Latest version has a bug with VSTS
        # https://github.com/RamblingCookieMonster/BuildHelpers/issues/100
        Version = '1.1.4'
        Target  = 'CurrentUser'
    }
    InvokeBuild      = @{
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
}