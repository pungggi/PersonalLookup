#requires -Version 5.1

# Module for personal text lookup by alias
# Provides quick access to stored information via clipboard

# Configuration file location
$Script:ConfigPath = Join-Path -Path $HOME -ChildPath "Documents\PersonalLookup_config.json"

# Default database file location
$Script:DbPath = Join-Path -Path $HOME -ChildPath "Documents\db.txt"

# Load custom path from configuration if it exists
if (Test-Path -Path $Script:ConfigPath) {
    try {
        $config = Get-Content -Path $Script:ConfigPath -Raw | ConvertFrom-Json
        if ($config.DbPath -and (Test-Path -Path $config.DbPath)) {
            $Script:DbPath = $config.DbPath
            # Using Write-Host instead of Write-Verbose to ensure visibility
            Write-Host "PersonalLookup: Using custom database path: $Script:DbPath" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Warning "Could not read configuration file. Using default database path."
    }
}
else {
    Write-Host "PersonalLookup: Using default database path: $Script:DbPath" -ForegroundColor Gray
}

# Private encryption functions
function Protect-Value {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Value
    )
    
    if ([string]::IsNullOrEmpty($Value)) { return "" }
    
    # Encrypt the value using DPAPI via SecureString
    $encryptedValue = ConvertFrom-SecureString -SecureString (ConvertTo-SecureString -String $Value -AsPlainText -Force)
    
    return $encryptedValue
}

function Unprotect-Value {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$EncryptedValue
    )
    
    if ([string]::IsNullOrEmpty($EncryptedValue)) { return "" }
    
    try {
        # Try to decrypt - if this succeeds, it was encrypted
        $secureValue = ConvertTo-SecureString -String $EncryptedValue -ErrorAction Stop
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureValue)
        try {
            $decryptedValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
            return $decryptedValue
        }
        finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
    catch {
        # If decryption fails, assume it wasn't encrypted and return as-is
        Write-Verbose "Value doesn't appear to be encrypted or cannot be decrypted."
        return $EncryptedValue
    }
}

# Function to safely migrate existing database to encrypted format
function ConvertTo-EncryptedDatabase {
    [CmdletBinding()]
    param()
    
    # Check if database exists
    if (-not (Test-Path -Path $Script:DbPath)) {
        Write-Verbose "No database to encrypt."
        return
    }
    
    # Read existing content
    $content = Get-Content -Path $Script:DbPath
    $newContent = @()
    $encryptedCount = 0
    
    foreach ($line in $content) {
        if ($line -match "^(.+?)=(.*)$") {
            $key = $Matches[1]
            $value = $Matches[2]
            
            # Try to decrypt to check if already encrypted
            try {
                ConvertTo-SecureString -String $value -AsPlainText -Force -ErrorAction Stop
                # If we get here, it's already encrypted
                $newContent += $line
            }
            catch {
                # Value is not encrypted, so encrypt it
                $encryptedValue = Protect-Value -Value $value
                $newContent += "$key=$encryptedValue"
                $encryptedCount++
            }
        }
        else {
            # Keep lines that don't match pattern
            $newContent += $line
        }
    }
    
    if ($encryptedCount -gt 0) {
        # Write encrypted content back to file
        Set-Content -Path $Script:DbPath -Value $newContent
        Write-Verbose "Encrypted $encryptedCount values in the database."
    }
}

# Run encryption migration when module loads
ConvertTo-EncryptedDatabase

function Get-Lookup {
    <#
    .SYNOPSIS
        Retrieves a value by key and copies it to clipboard
    .DESCRIPTION
        Looks up a key in the database and copies its value to clipboard
    .PARAMETER Key
        The key to look up
    .PARAMETER NoCopy
        If specified, doesn't copy to clipboard, just displays the value
    .PARAMETER Show
        If specified, displays the value instead of just copying silently
    .EXAMPLE
        Get-Lookup iban
        # Silently copies IBAN to clipboard
    .EXAMPLE
        dbget iban -Show
        # Shows the IBAN and copies it to clipboard
    #>
    [CmdletBinding()]
    [Alias("dbget")]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Key,
        
        [Parameter()]
        [switch]$NoCopy,
        
        [Parameter()]
        [switch]$Show
    )
    
    # Ensure database file exists
    if (-not (Test-Path -Path $Script:DbPath)) {
        Write-Error "Database file not found at $Script:DbPath"
        return
    }
    
    # Read all lines from the file
    $content = Get-Content -Path $Script:DbPath
    
    # Find the line with the key
    $line = $content | Where-Object { $_ -match "^$Key=" }
    
    if ($line) {
        # Extract value (everything after the first =)
        $encryptedValue = $line -replace "^$Key=", ""
        
        # Decrypt the value
        $value = Unprotect-Value -EncryptedValue $encryptedValue
        
        # Copy to clipboard if not prohibited
        if (-not $NoCopy) {
            Set-Clipboard -Value $value
        }
        
        # Show value if requested
        if ($Show) {
            Write-Output "$value"
        }
        
        if (-not $Show) {
            Write-Output "Value for '$Key' copied to clipboard."
        }
    }
    else {
        Write-Error "Key '$Key' not found in the database."
    }
}

function Set-Lookup {
    <#
    .SYNOPSIS
        Adds or updates a key-value pair in the database
    .DESCRIPTION
        Sets a value for a key in the database, creating or updating as needed
    .PARAMETER Key
        The key to set
    .PARAMETER Value
        The value to store
    .EXAMPLE
        Set-Lookup -Key "newkey" -Value "new value to store"
    .EXAMPLE
        dbset newkey "new value to store"
    #>
    [CmdletBinding()]
    [Alias("dbset")]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Key,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Value
    )
    
    # Create the file if it doesn't exist
    if (-not (Test-Path -Path $Script:DbPath)) {
        New-Item -Path $Script:DbPath -ItemType File -Force | Out-Null
        Write-Verbose "Created new database file at $Script:DbPath"
    }
    
    # Read existing content
    $content = @()
    if (Test-Path -Path $Script:DbPath) {
        $content = Get-Content -Path $Script:DbPath
    }
    
    # Encrypt the value before storing
    $encryptedValue = Protect-Value -Value $Value
    
    # Check if key already exists
    $keyExists = $false
    $newContent = @()
    
    foreach ($line in $content) {
        if ($line -match "^$Key=") {
            # Replace existing key
            $newContent += "$Key=$encryptedValue"
            $keyExists = $true
        }
        else {
            # Keep existing line
            $newContent += $line
        }
    }
    
    # Add new key if it doesn't exist
    if (-not $keyExists) {
        $newContent += "$Key=$encryptedValue"
    }
    
    # Write back to file
    Set-Content -Path $Script:DbPath -Value $newContent
    
    Write-Output "Key '$Key' has been set successfully."
}

function Remove-Lookup {
    <#
    .SYNOPSIS
        Removes a key-value pair from the database
    .DESCRIPTION
        Deletes a key and its associated value from the database
    .PARAMETER Key
        The key to remove
    .EXAMPLE
        Remove-Lookup -Key "oldkey"
    .EXAMPLE
        dbremove oldkey
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [Alias("dbremove")]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Key
    )
    
    # Ensure database file exists
    if (-not (Test-Path -Path $Script:DbPath)) {
        Write-Error "Database file not found at $Script:DbPath"
        return
    }
    
    # Read existing content
    $content = Get-Content -Path $Script:DbPath
    
    # Check if key exists
    $keyExists = $false
    $newContent = @()
    
    foreach ($line in $content) {
        if ($line -match "^$Key=") {
            $keyExists = $true
            # Skip this line to remove it
        }
        else {
            # Keep existing line
            $newContent += $line
        }
    }
    
    if (-not $keyExists) {
        Write-Error "Key '$Key' not found in the database."
        return
    }
    
    # Confirm before removing
    if ($PSCmdlet.ShouldProcess("Key '$Key'", "Remove")) {
        # Write back to file
        Set-Content -Path $Script:DbPath -Value $newContent
        Write-Output "Key '$Key' has been removed successfully."
    }
}

function Show-AllLookups {
    <#
    .SYNOPSIS
        Shows all keys in the database
    .DESCRIPTION
        Displays a list of all keys stored in the database
    .PARAMETER IncludeValues
        If specified, shows values alongside keys
    .EXAMPLE
        Show-AllLookups
    .EXAMPLE
        dbshow -IncludeValues
    #>
    [CmdletBinding()]
    [Alias("dbshow")]
    param (
        [Parameter()]
        [switch]$IncludeValues
    )
    
    # Ensure database file exists
    if (-not (Test-Path -Path $Script:DbPath)) {
        Write-Error "Database file not found at $Script:DbPath"
        return
    }
    
    # Read all lines from the file
    $content = Get-Content -Path $Script:DbPath
    
    if ($content.Count -eq 0) {
        Write-Output "The database is empty."
        return
    }
    
    Write-Output "Available keys in database:"
    
    if ($IncludeValues) {
        # Show keys with values
        foreach ($line in $content) {
            if ($line -match "^(.+?)=(.*)$") {
                $key = $Matches[1]
                $encryptedValue = $Matches[2]
                # Decrypt the value for display
                $decryptedValue = Unprotect-Value -EncryptedValue $encryptedValue
                
                [PSCustomObject]@{
                    Key   = $key
                    Value = $decryptedValue
                }
            }
        }
    }
    else {
        # Show only keys
        foreach ($line in $content) {
            if ($line -match "^(.+?)=") {
                $Matches[1]
            }
        }
    }
}

function Import-LookupData {
    <#
    .SYNOPSIS
        Imports data from a file into the lookup database
    .DESCRIPTION
        Imports key=value pairs from a specified file into the database
    .PARAMETER Path
        Path to the file to import
    .PARAMETER Overwrite
        If specified, overwrites existing keys with imported values
    .EXAMPLE
        Import-LookupData -Path "C:\temp\newdata.txt"
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter()]
        [switch]$Overwrite
    )
    
    # Ensure import file exists
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Import file not found at $Path"
        return
    }
    
    # Read import file
    $importContent = Get-Content -Path $Path
    
    # Read existing database
    $existingContent = @()
    if (Test-Path -Path $Script:DbPath) {
        $existingContent = Get-Content -Path $Script:DbPath
    }
    else {
        New-Item -Path $Script:DbPath -ItemType File -Force | Out-Null
    }
    
    # Process import
    $addedCount = 0
    $skippedCount = 0
    $replacedCount = 0
    
    foreach ($line in $importContent) {
        if ($line -match "^(.+?)=(.*)$") {
            $key = $Matches[1]
            $value = $Matches[2]
            
            # Encrypt the value
            $encryptedValue = Protect-Value -Value $value
            
            # Check if key exists
            $existingLine = $existingContent | Where-Object { $_ -match "^$key=" }
            
            if ($existingLine) {
                if ($Overwrite) {
                    if ($PSCmdlet.ShouldProcess("Key '$key'", "Replace")) {
                        # Replace existing key
                        $existingContent = $existingContent | ForEach-Object {
                            if ($_ -match "^$key=") {
                                "$key=$encryptedValue"
                            }
                            else {
                                $_
                            }
                        }
                        $replacedCount++
                    }
                }
                else {
                    $skippedCount++
                }
            }
            else {
                # Add new key
                $existingContent += "$key=$encryptedValue"
                $addedCount++
            }
        }
    }
    
    # Write back to database
    Set-Content -Path $Script:DbPath -Value $existingContent
    
    Write-Output "Import complete: $addedCount added, $replacedCount replaced, $skippedCount skipped."
}

function Set-LookupDbPath {
    <#
    .SYNOPSIS
        Sets the path to the lookup database file
    .DESCRIPTION
        Changes the location of the database file used by all lookup commands
        and saves this configuration for future PowerShell sessions
    .PARAMETER Path
        New path for the database file
    .EXAMPLE
        Set-LookupDbPath -Path "C:\Users\MyUser\secure\mylookup.txt"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    # Store the new path
    $Script:DbPath = $Path
    
    # Create the file if it doesn't exist
    if (-not (Test-Path -Path $Script:DbPath)) {
        New-Item -Path $Script:DbPath -ItemType File -Force | Out-Null
        Write-Output "Created new database file at $Script:DbPath"
    }
    else {
        Write-Output "Database path set to $Script:DbPath"
    }
    
    # Save the path to the configuration file for persistence across sessions
    $config = @{
        DbPath = $Script:DbPath
    }
    
    $config | ConvertTo-Json | Set-Content -Path $Script:ConfigPath -Force
    Write-Output "Path saved to configuration and will persist across PowerShell sessions."
}

function Get-LookupDbPath {
    <#
    .SYNOPSIS
        Gets the current path to the lookup database file
    .DESCRIPTION
        Returns the current database file path being used by the module
    .EXAMPLE
        Get-LookupDbPath
    #>
    [CmdletBinding()]
    param()
    
    Write-Output "Current database path: $Script:DbPath"
    
    if (Test-Path -Path $Script:DbPath) {
        Write-Output "Database file exists."
    }
    else {
        Write-Output "Warning: Database file does not exist at this location!"
    }
    
    if (Test-Path -Path $Script:ConfigPath) {
        Write-Output "Configuration file exists at: $Script:ConfigPath"
    }
    else {
        Write-Output "Configuration file does not exist yet."
    }
}

# Export module members
Export-ModuleMember -Function Get-Lookup, Set-Lookup, Remove-Lookup, Show-AllLookups, 
Import-LookupData, Set-LookupDbPath, Get-LookupDbPath -Alias dbget, dbset, dbremove, dbshow
