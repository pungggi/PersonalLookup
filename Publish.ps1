$apiKey = ""
Register-PSRepository -Default
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
$null = Get-PSRepository -Name PSGallery

$modulePath = Join-Path $env:USERPROFILE "Documents\PowerShell\Modules\PersonalLookup"
Publish-Module -Path $modulePath -NuGetApiKey $apiKey -Verbose