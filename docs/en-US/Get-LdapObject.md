---
external help file: Ldap-help.xml
Module Name: Ldap
online version:
schema: 2.0.0
---

# Get-LdapObject

## SYNOPSIS
Returns one or more objects from an LDAP server.

## SYNTAX

### DistinguishedName
```
Get-LdapObject -LdapConnection <LdapConnection> -Identity <String> [-Property <String[]>]
 [-AttributeFormat <String>] [-Raw] [<CommonParameters>]
```

### LdapFilter
```
Get-LdapObject -LdapConnection <LdapConnection> -LdapFilter <String> -SearchBase <String>
 [-Scope <SearchScope>] [-Property <String[]>] [-AttributeFormat <String>] [-Raw] [<CommonParameters>]
```

## DESCRIPTION
This function returns objects from an LDAP server. It can either return a specific object via its distinguished name, or return several objects based on an LDAP query.

The required LdapConnection parameter can be obtained via the Get-LdapConnection function.

## EXAMPLES

### Example 1
```powershell
PS C:\> $connection = Get-LdapConnection -Server 'example.local' -Port 389

PS C:\> Get-LdapObject -LdapConnection $connection -Identity 'cn=User,ou=example,dc=local'
```

This example returns a specific object from the LDAP server by its distinguished name.

### Example 2
```powershell
PS C:\> $connection = Get-LdapConnection -Server 'example.local' -Port 389

PS C:\> Get-LdapObject -LdapConnection $connection -LdapFilter '(cn=User)' -SearchBase 'ou=example,dc=local'
```

This example queries the LDAP server for any objects matching the provided LDAP filter within the provided search base.

## PARAMETERS

### -AttributeFormat
Whether to return attributes as strings or as byte arrays.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: String, ByteArray

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Identity
Full distinguished name of the item to return from the LDAP server.

```yaml
Type: String
Parameter Sets: DistinguishedName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LdapConnection
An LdapConnection object created using the Get-LdapConnection function which provides details on the server to query.

```yaml
Type: LdapConnection
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LdapFilter
An LDAP filter to be used to query the server. For information on LDAP filters, see https://confluence.atlassian.com/kb/how-to-write-ldap-search-filters-792496933.html

```yaml
Type: String
Parameter Sets: LdapFilter
Aliases: Filter

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Property
Limit the properties to return on queried results. This can significantly improve processing time. If not specified, the server will return all properties.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Raw
Do not attempt to clean up the provided output objects. This will significantly affect the format of the output object, but can be useful for troubleshooting if the function is returning unexpected output.

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

### -Scope
Search scope for the LDAP search. Specify whether to only search the provided search base, search one level into sub-containers, or search the entire tree from the provided search base.

```yaml
Type: SearchScope
Parameter Sets: LdapFilter
Aliases:
Accepted values: Base, OneLevel, Subtree

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SearchBase
Base container to use for a search.

```yaml
Type: String
Parameter Sets: LdapFilter
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

[Get-LdapConnection]()
