# PersonalLookup PowerShell Module

A PowerShell module for quickly storing, retrieving, and managing personal text snippets via a simple key-value database. Perfect for frequently accessed information like account numbers, IDs, or any text you need to access quickly.

## Features

- Store text snippets with easy-to-remember keys
- Retrieve text directly to clipboard
- Simple command-line interface with short aliases
- **Automatic encryption of stored values using Windows DPAPI**
- Plain text storage format with encrypted values

## Commands

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

### Import-LookupData

Imports key-value pairs from another file.

```powershell
# Import without overwriting existing keys
Import-LookupData -Path "C:\temp\additional_data.txt"

# Import and overwrite any existing keys
Import-LookupData -Path "C:\temp\updated_data.txt" -Overwrite
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

Data is stored in a simple text file with key=value format:

```
key1=value1
key2=value2
phone=555-123-4567
```

## Tips

- Use short, memorable keys for frequently accessed items
- For sensitive information, consider changing the database path to a more secure location
- Create a PowerShell profile entry to set your preferred database path at startup

```

```
