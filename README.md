# PersonalLookup PowerShell Module

A PowerShell module for quickly storing, retrieving, and managing personal text snippets via a simple key-value database. Perfect for frequently accessed information like account numbers, IDs, or any text you need to access quickly.

## Background

This module was created as a PowerShell replacement for the "Need" plugin for [Wox](http://www.wox.one/) launcher, providing similar functionality directly within PowerShell. It gives you the same convenient ability to store and retrieve text snippets but with added security through encryption and deeper integration with PowerShell.

**Credits**: Inspired by the original Wox "Need" plugin (http://www.wox.one/plugin/87) by Shinao.

## Features

- Store text snippets with easy-to-remember keys
- Retrieve text directly to clipboard
- Simple command-line interface with short aliases
- **Automatic encryption of stored values using Windows DPAPI**
- Plain text storage format with encrypted values

## Commands

### Get-Need (alias: Need)

All-in-one command to retrieve or set values based on the parameters provided.

```powershell
# Retrieve a value (silently copy to clipboard)
Need iban

# Set or update a value
Need iban "CH132154646"

# Show value when retrieving and copy to clipboard
Need iban -Show

# Show value without copying to clipboard
Need iban -NoCopy -Show
```

### Get-Lookup (alias: dbget)

Retrieves a value by key and copies it to clipboard.

```powershell
# Silently copy value to clipboard
Get-Lookup iban

# Show value and copy to clipboard
dbget iban -Show

# Show value without copying to clipboard
dbget iban -NoCopy -Show
```

### Set-Lookup (alias: dbset)

Adds or updates a key-value pair.

```powershell
# Store or update a key-value pair
Set-Lookup -Key "address" -Value "123 Main Street"
dbset phone "555-123-4567"
```

### Remove-Lookup (alias: dbremove)

Removes a key-value pair from the database.

```powershell
Remove-Lookup -Key "oldkey"
dbremove temporaryinfo
```

### Show-AllLookups (alias: dbshow)

Lists all available keys in the database.

```powershell
# Show only keys
Show-AllLookups

# Show keys and values
dbshow -IncludeValues
```

### Export-LookupData

Exports the database in a format that can be transferred to another computer.

```powershell
# Export as PowerShell commands (recommended)
Export-LookupData -Path "C:\temp\mylookup_export.ps1" -AsCommands

# Export as plain text (less secure)
Export-LookupData -Path "C:\temp\mylookup_export.txt" -AsPlainText
```

### Set-LookupDbPath

Changes the location of the database file.

```powershell
Set-LookupDbPath -Path "C:\Users\Jay\OneDrive\secure\database.txt"
```

### Get-LookupDbPath

Displays the current database path and configuration status.

```powershell
Get-LookupDbPath
```

## Configuration

By default, the database is stored at:

```
$HOME\Documents\db.txt
```

You can change this location using the `Set-LookupDbPath` command. The new path will persist across PowerShell sessions and module reloads thanks to a configuration file stored at:

```
$HOME\Documents\PersonalLookup_config.json
```

## Data Format

Data is stored in a simple text file with key=encrypted value format:

```
key1=01000000d08c9ddf0115d1118c7a00c04fc297eb01000000bd5facf59ce5274499d21cf812e8b486000000000200000000001066486000006
key2=01000000d08c9ddf0115d1118c7a00c04fc297eb01000000bd5facf59ce5274499d21cf812e8b486000000000200000000001066000100002000044555
phone=01000000d08c9ddf0115d1118c7a00c04fc297eb01000000bd5facf59ce5274499d21cf812e8b48600000000020000000000106600000001000020000
```

## Security

### Encryption Details

This module automatically encrypts all stored values using Windows Data Protection API (DPAPI). Here's what this means for you:

- **User-Specific Encryption**: Values are encrypted with your Windows user account credentials. Only your Windows user account can decrypt the data.
- **Machine-Bound**: The encrypted data is tied to the specific computer where it was created. It cannot be decrypted on another computer, even with the same user account.
- **No Passwords Required**: You don't need to enter or remember any additional passwords to secure your data.
- **Transparent Usage**: Encryption and decryption happen automatically when you store or retrieve values.

### Security Considerations

- If someone gains access to your Windows user account, they can access your stored values.
- The module stores data in a plain text file, but all sensitive values are encrypted - only the keys are readable.
- Backing up your database requires copying the file to another location. Remember that the encrypted values can only be decrypted on the original computer with your user account.
- If you need to transfer your database to another computer, you'll need to re-encrypt the values on the new machine.

### Transferring to Another Computer

Since the encryption is machine and user specific, you need to export the data before transferring:

1. Use `Export-LookupData` to create an export file:

   ```powershell
   Export-LookupData -Path "C:\path\to\export.ps1" -AsCommands
   ```

2. On the new computer, after installing the module:
   ```powershell
   # Run the exported script
   . "C:\path\to\export.ps1"
   ```

This process will decrypt the values on the original machine and re-encrypt them on the new machine.

For most personal use, this level of security provides good protection for sensitive information like account numbers, IDs, and other personal data you want quick access to without storing in plain text.
