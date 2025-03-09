[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("Major", "Minor", "Patch")]
    [string]$VersionIncrement = "Patch",
    
    [Parameter()]
    [string]$ApiKey = ""
)

# Ensure we have the API key
if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    $ApiKey = Read-Host -Prompt "Enter your PowerShell Gallery API key"
}

# Setup repository
Register-PSRepository -Default -ErrorAction SilentlyContinue
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
$null = Get-PSRepository -Name PSGallery

# Set paths
$modulePath = Join-Path $env:USERPROFILE "Documents\PowerShell\Modules\PersonalLookup"
$manifestPath = Join-Path $modulePath "PersonalLookup.psd1"

# Read current version from manifest
Write-Host "Reading current module version..." -ForegroundColor Cyan
$manifest = Import-PowerShellDataFile -Path $manifestPath
$currentVersion = [Version]$manifest.ModuleVersion
Write-Host "Current version: $currentVersion" -ForegroundColor Green

# Calculate new version based on increment type
Write-Host "Incrementing $VersionIncrement version..." -ForegroundColor Cyan
switch ($VersionIncrement) {
    "Major" { $newVersion = [Version]::new($currentVersion.Major + 1, 0, 0) }
    "Minor" { $newVersion = [Version]::new($currentVersion.Major, $currentVersion.Minor + 1, 0) }
    "Patch" { $newVersion = [Version]::new($currentVersion.Major, $currentVersion.Minor, $currentVersion.Build + 1) }
}

# Update the module manifest with new version
Write-Host "Updating module manifest with new version: $newVersion" -ForegroundColor Yellow
Update-ModuleManifest -Path $manifestPath -ModuleVersion $newVersion

# Verify the update
$updatedManifest = Import-PowerShellDataFile -Path $manifestPath
$updatedVersion = $updatedManifest.ModuleVersion
Write-Host "Module version updated from $currentVersion to $updatedVersion" -ForegroundColor Green

# Add tags to improve discoverability
Update-ModuleManifest -Path $manifestPath -Tags @('KeyValue', 'Storage', 'Clipboard', 'Security', 'Encryption', 'Productivity')

# Publish the module
Write-Host "Publishing module to PowerShell Gallery..." -ForegroundColor Cyan
Publish-Module -Path $modulePath -NuGetApiKey $ApiKey -Verbose

Write-Host "Module published successfully!" -ForegroundColor Green
Write-Host "Users can install with: Install-Module -Name PersonalLookup -Scope CurrentUser" -ForegroundColor Cyan
Write-Host "Users can update with: Update-Module -Name PersonalLookup" -ForegroundColor Cyan