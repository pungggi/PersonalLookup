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
- **Launch associated applications automatically with shortcuts**
- **Auto-clearing clipboard security (clears sensitive data after 70 seconds)**

## Installation

### Option 1: Installing from PowerShell Gallery (Recommended)

```powershell
Install-Module -Name PersonalLookup -Scope CurrentUser
```

### Option 2: Manual Installation

1. Download or clone this repository
2. Place the entire folder in one of your PowerShell module paths:
   ```powershell
   # View your PSModulePath locations
   $env:PSModulePath -split ';'
   ```
3. The recommended location is:
   ```
   $HOME\Documents\PowerShell\Modules\PersonalLookup
   ```
4. Import the module:
   ```powershell
   Import-Module PersonalLookup
   ```

To automatically load the module in all PowerShell sessions, add the Import-Module command to your PowerShell profile:

```powershell
# Open your profile for editing
notepad $PROFILE

# Add this line
Import-Module PersonalLookup
```

## Commands

### Get-Need (alias: Need)

All-in-one command to retrieve or set values based on the parameters provided.

```powershell
# Retrieve a value (silently copy to clipboard, auto-clears after 70 seconds)
Need iban

# Set or update a value
Need iban "CH132154646"

# Set a value with shortcut (will launch the app after copying to clipboard)
Need iban "CH132154646" "C:\Program Files\BankApp\bank.exe"

# Show value when retrieving and copy to clipboard
Need iban -Show

# Show value without copying to clipboard
Need iban -NoCopy -Show

# Prevent automatic clipboard clearing
Need iban -NoAutoClipboardClear
```

### Get-Lookup (alias: dbget)

Retrieves a value by key and copies it to clipboard.

```powershell
# Silently copy value to clipboard (auto-clears after 70 seconds)
Get-Lookup iban

# Show value and copy to clipboard
dbget iban -Show

# Show value without copying to clipboard
dbget iban -NoCopy -Show

# Prevent automatic clipboard clearing
dbget iban -NoAutoClipboardClear
```

### Set-Lookup (alias: dbset)

Adds or updates a key-value pair.

```powershell
# Store or update a key-value pair
Set-Lookup -Key "address" -Value "123 Main Street"
dbset phone "555-123-4567"

# Store value with a shortcut to launch after copying
dbset bankaccount "123456789" "C:\Program Files\Banking\app.exe"
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

# Show keys, values, and shortcuts
dbshow -IncludeValues -IncludeShortcuts
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
Set-LookupDbPath -Path "C:\Users\Jay\OneDrive\secure\db.txt"
```

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

## Publishing to PowerShell Gallery

To publish this module to the PowerShell Gallery, follow these steps:

### Prerequisites

1. Create a PowerShell Gallery account at [PowerShellGallery.com](https://www.powershellgallery.com/)
2. Get an API key from your PowerShell Gallery account settings
3. Ensure your module has a proper module manifest (`.psd1` file) with version information

### Prepare Your Module

1. Make sure all required fields are completed in your module manifest:
   - ModuleVersion
   - Author
   - Description
   - PowerShellVersion (minimum version required)
   - FunctionsToExport
   - Tags (for discoverability)

### Publish the Module with Automatic Version Increment

```powershell
# Register your API key (only needed once per machine)
$apiKey = "your-api-key-from-powershellgallery"
Register-PSRepository -Default
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
$null = Get-PSRepository -Name PSGallery

# Path to your module's psd1 file
$manifestPath = "C:\Users\Alessandro\Documents\PowerShell\Modules\PersonalLookup\PersonalLookup.psd1"
$modulePath = "C:\Users\Alessandro\Documents\PowerShell\Modules\PersonalLookup"

# Increment version (specify: Major, Minor, or Patch)
$versionType = "Patch" # Change to "Major" or "Minor" as needed

# Read the current module manifest
$manifest = Import-PowerShellDataFile -Path $manifestPath
$currentVersion = [Version]$manifest.ModuleVersion

# Calculate new version based on increment type
switch ($versionType) {
    "Major" { $newVersion = [Version]::new($currentVersion.Major + 1, 0, 0) }
    "Minor" { $newVersion = [Version]::new($currentVersion.Major, $currentVersion.Minor + 1, 0) }
    "Patch" { $newVersion = [Version]::new($currentVersion.Major, $currentVersion.Minor, $currentVersion.Build + 1) }
}

# Update the module manifest with new version
Update-ModuleManifest -Path $manifestPath -ModuleVersion $newVersion

Write-Host "Module version updated from $currentVersion to $newVersion"

# Publish your module with the new version
Publish-Module -Path $modulePath -NuGetApiKey $apiKey -Verbose
```

### Updating the Module

Run the script above for each new release, changing the `$versionType` parameter as needed:

- `Major` for significant changes that may break compatibility (1.0.0 → 2.0.0)
- `Minor` for new features that maintain compatibility (1.0.0 → 1.1.0)
- `Patch` for bug fixes and minor updates (1.0.0 → 1.0.1)

Users can update using:

```powershell
Update-Module -Name PersonalLookup
```

For more information, see the [PowerShell Gallery documentation](https://docs.microsoft.com/en-us/powershell/scripting/gallery/overview).
