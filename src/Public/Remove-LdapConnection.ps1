function Remove-LdapConnection {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory,
            Position = 0,
            ValueFromPipeline = $true)]
        [System.DirectoryServices.Protocols.LdapConnection[]] $LdapConnection
        ,

        [Parameter()]
        [Switch] $Force
    )

    process {
        foreach ($l in $LdapConnection) {
            if ($l) {
                if (-not ($Force -or $PSCmdlet.ShouldProcess($l, "Close LDAP connection"))) {
                    Write-Debug "[Remove-LdapConnection] WhatIf mode or user denied prompt; not closing connection [[ $l ]"
                }
                else {
                    Write-Debug "[Remove-LdapConnection] Disposing LdapConnection [$l]"
                    $l.Dispose()
                }
            }
        }
    }
}
