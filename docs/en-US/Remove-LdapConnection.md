---
external help file: Ldap-help.xml
Module Name: Ldap
online version:
schema: 2.0.0
---

# Remove-LdapConnection

## SYNOPSIS
Closes a provided LdapConnection object.

## SYNTAX

```
Remove-LdapConnection [-LdapConnection] <LdapConnection[]> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function closes a provided LdapConnection object. It is a convenience function around the .Dispose() method.

## EXAMPLES

### Example 1
```powershell
PS C:\> $connection = Get-LdapConnection -Server example.com -Port 389

# Perfom any queries here

PS C:\> Remove-LdapConnection $connection
```

This example creates an LdapConnection object, then closes it again. Typically, you would run one or more queries between these two commands.

## PARAMETERS

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Never prompt for confirmation before closing the connection.

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

### -LdapConnection
One or more LdapConnection objects which should be closed.

```yaml
Type: LdapConnection[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.DirectoryServices.Protocols.LdapConnection[]

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

[Get-LdapConnection]()
