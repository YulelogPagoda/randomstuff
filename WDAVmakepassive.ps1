# Import the necessary module
Import-Module ActiveDirectory

# Define the Organizational Unit
$ou = 'OU=Computers,DC=domain,DC=com'

# Get all the computers in the OU
$computers = Get-ADComputer -Filter * -SearchBase $ou | Select-Object -ExpandProperty Name

# Initialize the progress counter
$counter = 0

foreach ($computer in $computers) {
    # Start a job for each computer
    Start-Job -ScriptBlock {
        param($computer)

        # Establish a session with the remote computer
        $session = New-PSSession -ComputerName $computer

        # Define the script block to run on the remote computer
        $scriptBlock = {
            # Check if Windows Defender feature is enabled
            $featureName = 'Windows-Defender'
            $feature = Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -eq $featureName }

            if ($feature.State -eq 'Disabled') {
                # Enable Windows Defender feature
                Enable-WindowsOptionalFeature -Online -FeatureName $featureName -All -NoRestart
            }

            # Check if Windows Defender is in passive mode
            $DefenderPassiveMode = Get-MpPreference | Select-Object -ExpandProperty DisableRealtimeMonitoring

            if (-not $DefenderPassiveMode) {
                # Setting Windows Defender to passive mode
                Set-MpPreference -DisableRealtimeMonitoring $true
            }
        }

        # Run the script block on the remote computer
        Invoke-Command -Session $session -ScriptBlock $scriptBlock

        # Close the session
        Remove-PSSession -Session $session
    } -ArgumentList $computer | Out-Null

    # Update the progress bar
    $counter++
    Write-Progress -Activity "Processing Computers" -Status "$counter of $($computers.Count) processed" -PercentComplete (($counter / $computers.Count) * 100)
}

# Wait for all jobs to complete
while (Get-Job -State 'Running') {
    Start-Sleep -Seconds 1
}

# Display the results
Get-Job | Receive-Job

# Clean up the jobs
Remove-Job -State Completed
