BeforeAll {
    . $PSCommandPath.Replace('test', 'src').Replace('.Tests.ps1', '.ps1')
}

Describe "Send-LdapRequest" {
    Context "-Timeout passed" {
        It "Calls SendRequest with the Request and Timeout parameters" {
            $ldap = [System.DirectoryServices.Protocols.LdapConnection]::new("fakeLdapServer")
            $request = [System.DirectoryServices.Protocols.SearchRequest]::new()
            $timeout = [System.TimeSpan]::FromSeconds(5)

            $ldap | Add-Member -MemberType ScriptMethod -Name 'SendRequest' -Force -Value {
                param($Request, $Timeout)
                return $Timeout
            }

            Send-LdapRequest -LdapConnection $ldap -Request $request -Timeout $timeout |
                Should -Be $timeout
        }
    }

    Context "-Timeout not passed" {
        It 'Calls SendRequest with the Request parameter' {
            $ldap = [System.DirectoryServices.Protocols.LdapConnection]::new("fakeLdapServer")
            $request = [System.DirectoryServices.Protocols.SearchRequest]::new()

            $ldap | Add-Member -MemberType ScriptMethod -Name 'SendRequest' -Force -Value {
                param($Request)
                return $true
            }

            Send-LdapRequest -LdapConnection $ldap -Request $request |
                Should -Be $true
        }
    }
}