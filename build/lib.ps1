# Invoke-Build library
# v0.1
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