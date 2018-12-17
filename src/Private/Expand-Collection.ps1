function Expand-Collection {
    # Simple helper function to expand a collection into a PowerShell array.
    # The advantage to this is that if it's a collection with a single element,
    # PowerShell will automatically parse that as a single entry.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,
                   Position = 0,
                   ValueFromPipeline,
                   ValueFromRemainingArguments)]
        [ValidateNotNull()]
        [Object[]] $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            ForEach-Object -InputObject $i -Process { Write-Output $_ }
        }
    }
}