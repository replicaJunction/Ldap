function Get-LdapConnection {
    [CmdletBinding()]
    [OutputType([System.DirectoryServices.Protocols.LdapDirectoryIdentifier])]
    param(
        [Parameter(Mandatory)]
        [String] $Server,

        # LDAP port to use. Default is 389 for LDAP or 636 for LDAPS
        [Parameter()]
        [Int] $Port,

        # Do not use SSL
        [Parameter()]
        [Switch] $NoSsl,

        # Ignore certificate validation (use with self-signed certs)
        [Parameter()]
        [Switch] $IgnoreCertificate,

        # Version of the LDAP protocol to use
        [Parameter()]
        [Int] $ProtocolVersion,

        # Specify how the LDAP library follows referrals
        [Parameter()]
        [System.DirectoryServices.ReferralChasingOption] $ReferralChasing,

        [Parameter()]
        [PSCredential] [System.Management.Automation.Credential()] $Credential,

        [Parameter()]
        [System.DirectoryServices.Protocols.AuthType] $AuthType
    )

    process {
        $ldapIdentifier = New-Object -TypeName System.DirectoryServices.Protocols.LdapDirectoryIdentifier -ArgumentList $Server, $Port

        if ($Credential) {
            Write-Debug "[Get-LdapConnection] Creating authenticated LdapConnection for user $($Credential.UserName)"
            $ldap = New-Object -TypeName System.DirectoryServices.Protocols.LdapConnection -ArgumentList $ldapIdentifier, ($Credential.GetNetworkCredential())
            if (-not $AuthType) {
                Write-Debug "[Get-LdapConnection] AuthType was not specified; defaulting to Basic"
                $AuthType = [System.DirectoryServices.Protocols.AuthType]::Basic
            }
        }
        else {
            Write-Debug "[Get-LdapConnection] Creating anonymous LdapConnection"
            $ldap = New-Object -TypeName System.DirectoryServices.Protocols.LdapConnection -ArgumentList $ldapIdentifier
            if (-not $AuthType) {
                Write-Debug "[Get-LdapConnection] AuthType was not specified; defaulting to Anonymous"
                $AuthType = [System.DirectoryServices.Protocols.AuthType]::Anonymous
            }
        }

        $ldap.AuthType = $AuthType

        if ($NoSsl) {
            Write-Debug "[Get-LdapConnection] NoSsl was sent; not setting SSL"
        }
        else {
            $ldap.SessionOptions.SecureSocketLayer = $true
        }

        if ($IgnoreCertificate) {
            $ldap.SessionOptions.VerifyServerCertificate = { $true }
        }

        if ($ProtocolVersion) {
            $ldap.SessionOptions.ProtocolVersion = $ProtocolVersion
        }

        if ($ReferralChasing) {
            $ldap.SessionOptions.ReferralChasing = $ReferralChasing
        }

        Write-Output $ldap
    }
}