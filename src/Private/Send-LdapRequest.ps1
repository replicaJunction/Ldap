function Send-LdapRequest {
    [CmdletBinding()]
    [OutputType([System.DirectoryServices.Protocols.DirectoryResponse])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.DirectoryServices.Protocols.LdapConnection] $LdapConnection
        ,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.DirectoryServices.Protocols.DirectoryRequest] $Request
        ,

        [Parameter()]
        [System.TimeSpan] $Timeout
    )

    end {
        if ($Timeout) {
            $LdapConnection.SendRequest($Request, $Timeout) | Write-Output
        }
        else {
            $LdapConnection.SendRequest($Request)
        }
    }
}