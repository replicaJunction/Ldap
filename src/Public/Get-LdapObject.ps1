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
        [int] $PageSize,

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

        # Declare this outside of the below If block to support Strict mode
        $pageControl = $null
        if ($PageSize) {
            $pageControl = New-Object -TypeName System.DirectoryServices.Protocols.PageResultRequestControl -ArgumentList $PageSize
            [void] $request.Controls.Add($pageControl)
        }

        Write-Debug "[Get-LdapObject] Sending LDAP request"
        $splat = @{
            'LdapConnection' = $LdapConnection
            'Request'        = $request
        }

        if ($TimeoutSeconds) {
            $splat['Timeout'] = [System.TimeSpan]::FromSeconds($TimeoutSeconds)
        }

        # Again, we need to define the variable outside the scope of the do/until loop
        # or else Strict mode will yell at us
        $hasMore = $false
        do {
            # Stop after this run unless we explicitly say otherwise
            $hasMore = $false

            # Since we are sending a SearchRequest, we will get a SearchResponse back
            [System.DirectoryServices.Protocols.SearchResponse] $response = Send-LdapRequest @splat

            if (-not $response) {
                Write-Verbose "No response was returned from the LDAP server."
            }
            elseif ($response.ResultCode -ne 'Success') {
                Write-Warning "The LDAP server returned response code $($response.ResultCode) instead of Success"
                Write-Output $response
            }
            else {
                if ($Raw) {
                    Write-Debug "[Get-LdapObject] -Raw was passed; outputting raw directory entries"
                    Write-Output ($response.Entries)
                }
                else {
                    # Convert results to a PSCustomObject.
                    $response.Entries | ForEach-Object {
                        $hash = [Ordered] @{
                            PSTypeName        = 'LdapObject'
                            DistinguishedName = $_.DistinguishedName
                        }

                        # Attributes are returned as an instance of the class
                        # System.DirectoryServices.Protocols.SearchResultAttributeCollection,
                        # which is a collection of DirctoryAttribute objects.
                        #
                        # DirectoryAttribute extends CollectionBase, which PowerShell can iterate
                        # through using ForEach-Object, but PowerShell doesn't automatically
                        # expand them the way it handles IEnumerables.
                        #
                        # The ForEach-Object here iterates through the values in the
                        # DirectoryEntry and converts them to an IEnumerable instance, which is
                        # much more PowerShell-friendly.

                        foreach ($a in $_.Attributes.Keys | Sort-Object) {
                            $hash[$a] = $_.Attributes[$a].GetValues($attrType) | ForEach-Object { $_ }
                        }

                        [PSCustomObject] $hash
                    } | Write-Output
                }

                # If we're paging, see if we need to return another page
                if ($PageSize) {
                    [System.DirectoryServices.Protocols.PageResultResponseControl] $pageResult = $response.Controls |
                        Where-Object {$_ -is [System.DirectoryServices.Protocols.PageResultResponseControl]} |
                        Select-Object -First 1   # There should only be one, but this is defensive programming

                    if (-not $pageResult) {
                        Write-Warning "No paging controls were returned from the LDAP server. Results may be incomplete."
                    }
                    elseif ($pageResult.Cookie.Length -eq 0) {
                        # Length of 0 indicates that we've returned all results
                        Write-Debug "[Get-LdapObject] Paging cookie with length of 0 returned; completed paging"
                    }
                    else {
                        # Update the page control in the request with the new paging info in the response
                        Write-Debug "[Get-LdapObject] More paging information was provided ($($pageResult.Cookie))"
                        $pageControl.Cookie = $pageResult.Cookie
                        $hasMore = $true
                    }
                }
            }
        }
        while ($hasMore)
    }
}