# This script must be run as an Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    break
}

# Check if Windows Defender feature is enabled
$featureName = 'Windows-Defender'
$feature = Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -eq $featureName }

if ($feature.State -eq 'Disabled') {
    Write-Output "Windows Defender is not enabled. Enabling it now..."

    # Enable Windows Defender feature
    Enable-WindowsOptionalFeature -Online -FeatureName $featureName -All -NoRestart
} else {
    Write-Output "Windows Defender is already enabled."
}

# Check if Windows Defender is in passive mode
$DefenderPassiveMode = Get-MpPreference | Select-Object -ExpandProperty DisableRealtimeMonitoring

if ($DefenderPassiveMode) {
    Write-Output "Windows Defender is already in passive mode."
} else {
    Write-Output "Windows Defender is not in passive mode. Switching to passive mode now..."

    # Setting Windows Defender to passive mode
    Set-MpPreference -DisableRealtimeMonitoring $true
}
