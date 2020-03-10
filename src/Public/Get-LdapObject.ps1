function Get-LdapObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.DirectoryServices.Protocols.LdapConnection] $LdapConnection,

        [Parameter(ParameterSetName = 'DistinguishedName',
            Mandatory)]
        [String] $Identity,

        [Parameter(ParameterSetName = 'LdapFilter',
            Mandatory)]
        [Alias('Filter')]
        [String] $LdapFilter,

        [Parameter(ParameterSetName = 'LdapFilter',
            Mandatory)]
        [String] $SearchBase,

        [Parameter(ParameterSetName = 'LdapFilter')]
        [System.DirectoryServices.Protocols.SearchScope] $Scope = [System.DirectoryServices.Protocols.SearchScope]::Subtree,

        [Parameter()]
        [String[]] $Property,

        [Parameter()]
        [ValidateSet('String', 'ByteArray')]
        [String] $AttributeFormat = 'String',

        [Parameter()]
        [uint32] $TimeoutSeconds,

        # Do not attempt to clean up the LDAP output - provide the output as-is
        [Parameter()]
        [Switch] $Raw
    )

    begin {
        if ($AttributeFormat -eq 'String') {
            $attrType = [string]
        }
        else {
            $attrType = [byte[]]
        }
    }

    process {
        $request = New-Object -TypeName System.DirectoryServices.Protocols.SearchRequest

        if ($PSCmdlet.ParameterSetName -eq 'DistinguishedName') {
            $request.DistinguishedName = $Identity
        }
        else {
            $request.Filter = $LdapFilter
            $request.DistinguishedName = $SearchBase
        }

        if (-not $Property -or $Property -contains '*') {
            Write-Debug "[Get-LdapObject] Returning all properties"
        }
        else {
            foreach ($p in $Property) {
                [void] $request.Attributes.Add($p)
            }
        }

        Write-Debug "[Get-LdapObject] Sending LDAP request"
        $splat = @{
            'LdapConnection' = $LdapConnection
            'Request'        = $request
        }

        if ($TimeoutSeconds) {
            $splat['Timeout'] = [System.TimeSpan]::FromSeconds($TimeoutSeconds)
        }

        $response = Send-LdapRequest @splat

        if (-not $response) {
            Write-Verbose "No response was returned from the LDAP server."
            return
        }

        if ($response.ResultCode -eq 'Success') {
            if ($Raw) {
                Write-Output ($response.Entries)
            }
            else {
                # Convert results to a PSCustomObject.
                foreach ($e in $response.Entries) {
                    $hash = @{
                        PSTypeName        = 'LdapObject'
                        DistinguishedName = $e.DistinguishedName
                        # Controls          = $e.Controls     # Not actually sure what this is
                    }

                    # Attributes are returned as an instance of the class
                    # System.DirectoryServices.Protocols.DirectoryAttribute.
                    # Translate that to a more PowerShell-friendly format here.
                    foreach ($a in $e.Attributes.Keys | Sort-Object) {
                        # Write-Debug "[Get-LdapObject] Adding type [$a]"
                        $hash[$a] = $e.Attributes[$a].GetValues($attrType) | Expand-Collection
                    }

                    Write-Output ([PSCustomObject] $hash)
                }
                return
            }
        }

        Write-Output $response
    }
}