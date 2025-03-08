#requires -Version 5.1

# Module for personal text lookup by alias
# Provides quick access to stored information via clipboard

# Default database file location
$Script:DbPath = Join-Path -Path $HOME -ChildPath "Documents\db.txt"

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
        $value = $line -replace "^$Key=", ""
        
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
    } else {
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
    
    # Check if key already exists
    $keyExists = $false
    $newContent = @()
    
    foreach ($line in $content) {
        if ($line -match "^$Key=") {
            # Replace existing key
            $newContent += "$Key=$Value"
            $keyExists = $true
        } else {
            # Keep existing line
            $newContent += $line
        }
    }
    
    # Add new key if it doesn't exist
    if (-not $keyExists) {
        $newContent += "$Key=$Value"
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
        } else {
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
                [PSCustomObject]@{
                    Key = $Matches[1]
                    Value = $Matches[2]
                }
            }
        }
    } else {
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
    } else {
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
            
            # Check if key exists
            $existingLine = $existingContent | Where-Object { $_ -match "^$key=" }
            
            if ($existingLine) {
                if ($Overwrite) {
                    if ($PSCmdlet.ShouldProcess("Key '$key'", "Replace")) {
                        # Replace existing key
                        $existingContent = $existingContent | ForEach-Object {
                            if ($_ -match "^$key=") {
                                "$key=$value"
                            } else {
                                $_
                            }
                        }
                        $replacedCount++
                    }
                } else {
                    $skippedCount++
                }
            } else {
                # Add new key
                $existingContent += "$key=$value"
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
    } else {
        Write-Output "Database path set to $Script:DbPath"
    }
}

# Export module members
Export-ModuleMember -Function Get-Lookup, Set-Lookup, Remove-Lookup, Show-AllLookups, 
                             Import-LookupData, Set-LookupDbPath -Alias dbget, dbset, dbremove, dbshow
