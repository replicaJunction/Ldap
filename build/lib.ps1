# Invoke-Build library
# v0.2
function Merge-Module {
    [CmdletBinding()]
    param(
        [Parameter()]
        [String] $ModuleSource
        ,

        [Parameter()]
        [String[]] $Directory = @('Public', 'Private')
        ,

        [Parameter()]
        [String] $OutputFile
        ,

        [Parameter()]
        [AllowEmptyString()]
        [String] $ExtraModuleContent
    )

    end {
        # https://evotec.xyz/powershell-single-psm1-file-versus-multi-file-modules/

        foreach ($dir in $Directory) {
            $currentFiles = @(Get-ChildItem "$ModuleSource\$dir\*.ps1" -ErrorAction SilentlyContinue)
            foreach ($file in $currentFiles) {
                $thisAst = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$null)
                $functions = $thisAst.EndBlock.Extent.Text + "`n"
                $functions | Add-Content -Path $OutputFile
            }
        }

        if ($ExtraModuleContent) {
            $ExtraModuleContent.Trim() | Add-Content -Path $OutputFile
        }
    }
}

function Set-ApiKey {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0
        )]
        [String] $ApiKey
        ,

        [Parameter()]
        [DateTime] $Expires
        ,

        [Parameter()]
        [String] $OutPath
    )

    if (-not $Expires) {
        $Expires = [DateTime]::Today.AddDays(365)
        Write-Verbose "Expiration date set to $($Expires)"
    }

    if (-not $OutPath) {
        $OutPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts\apiKey.json'
    }

    Write-Verbose "Writing API key to file $outPath"
    [PSCustomObject]@{
        ApiKey = $ApiKey.Trim()
        Expires = $Expires
    } | ConvertTo-Json | Out-File $OutPath -Force
}

function Get-ApiKey {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(
            Position = 0
        )]
        [String] $FilePath
    )

    if (-not $FilePath -and (Get-Variable BHBuildSystem) -and $BHBuildSystem -eq 'VSTS') {
        Write-Verbose "Get-ApiKey -FilePath was not specified and using VSTS; checking for secure file"
        if (Test-Path $env:DOWNLOADSECUREFILE_SECUREFILEPATH) {
            Write-Verbose "Secure file was found at path $env:DOWNLOADSECUREFILE_SECUREFILEPATH"
            $FilePath = $env:DOWNLOADSECUREFILE_SECUREFILEPATH
        }
        else {
            Write-Verbose "Secure file was not found"
        }
    }

    if (-not $FilePath) {
        $FilePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts/apiKey.json'
    }

    Write-Verbose "Reading API key from file $FilePath"
    $keyData = Get-Content $FilePath -Raw | ConvertFrom-Json
    if ($keyData.Expires -lt (Get-Date)) {
        throw "API key is expired! Create or regenerate your API key at https://www.powershellgallery.com/account/apikeys"
    }

    Write-Output $keyData.ApiKey
}