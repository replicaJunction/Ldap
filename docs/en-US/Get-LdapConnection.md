---
external help file: Ldap-help.xml
Module Name: Ldap
online version:
schema: 2.0.0
---

# Get-LdapConnection

## SYNOPSIS
Returns a new LdapConnection object

## SYNTAX

```
Get-LdapConnection [-Server] <String> [[-Port] <Int32>] [-NoSsl] [-IgnoreCertificate]
 [[-Credential] <PSCredential>] [[-AuthType] <AuthType>] [<CommonParameters>]
```

## DESCRIPTION
This function returns a new LdapConnection object, which can be used to query LDAP.

This function does not actually bind to LDAP - binding is done either with the .Bind() method on the output object, or automatically when running a query with the output object.

Be sure to close the LdapConnection object after querying! This can be done with the Remove-LdapConnection function by calling .Dispose() on the object.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LdapConnection -Server 'example.local' -Port 636
```

This example returns a new LdapConnection object with the provided server and port, using anonymous access.

### Example 2
```powershell
PS C:\> Get-LdapConnection -Server 'example.local' -Port 636 -Credential (Get-Credential)
```

This example returns a new LdapConnection object with the provided server and port using basic authentication, using credentials provided by Get-Credential.

## PARAMETERS

### -AuthType
Type of LDAP authentication to use. If not specified, defaults are Anonymous if no credentials are provided, or Basic if credentials are provided.

```yaml
Type: AuthType
Parameter Sets: (All)
Aliases:
Accepted values: Anonymous, Basic, Negotiate, Ntlm, Digest, Sicily, Dpa, Msn, External, Kerberos

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Credentials to use to connect to LDAP. Note that in most cases, a fully-qualified name is required (such as "cn=User,ou=Example,dc=local") rather than just a common name.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IgnoreCertificate
Do not validate the SSL certificate from the LDAP server.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoSsl
Do not attempt to use SSL encryption.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Port
Port to be used to connect to LDAP.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Server
FQDN of the LDAP server to connect to.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.DirectoryServices.Protocols.LdapDirectoryIdentifier

## NOTES

## RELATED LINKS

[Remove-LdapConnection]()
