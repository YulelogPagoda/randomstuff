# Import the Active Directory and ThreadJob modules
Import-Module ActiveDirectory
Import-Module ThreadJob

# Specify the OUs to search in
$ous = @("OU=YourOU1,DC=YourDomain,DC=com", "OU=YourOU2,DC=YourDomain,DC=com")

# Initialize an array for storing computer names
$computers = @()

# Get the list of computers in each OU
foreach ($ou in $ous) {
    $computers += Get-ADComputer -SearchBase $ou -Filter * | Select-Object -ExpandProperty Name
}

# Output CSV
$output = "C:\temp\DefenderStatus.csv"

# Create script block for ThreadJob
$scriptBlock = {
    param ($computer)

    # Test if we can connect to the computer
    if (Test-Connection -ComputerName $computer -Count 2 -Quiet) {
        # Get the Operating System and Defender status
        $info = Invoke-Command -ComputerName $computer -ScriptBlock {
            try {
                $os = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption
                $defender = Get-MpComputerStatus
                return @{
                    OS = $os
                    RealTimeProtectionEnabled = $defender.RealTimeProtectionEnabled.ToString()
                    SignatureVersion = $defender.AntispywareSignatureVersion
                }
            } 
            catch {
                return $null
            }
        } -ErrorAction SilentlyContinue

        # Define the status
        $status = switch ($info.RealTimeProtectionEnabled) {
            "True" { "Enabled" }
            "False" { "Disabled" }
            $null { "Error or No Defender" }
        }

        # Add the status to the results
        return New-Object -TypeName PSObject -Property @{
            ComputerName = $computer
            OS = $info.OS
            Status = $status
            SignatureVersion = $info.SignatureVersion
        }
    } else {
        # Add an error to the results
        return New-Object -TypeName PSObject -Property @{
            ComputerName = $computer
            Status = "Unreachable"
            OS = "Unreachable"
            SignatureVersion = "Unreachable"
        }
    }
}

# Initialize progress bar
$progressCount = 0
$progressTotal = $computers.Count

# Initialize results array
$results = @()

# Launch jobs
$jobs = $computers | ForEach-Object {
    $job = Start-ThreadJob -ScriptBlock $scriptBlock -ArgumentList $_
    # Wait for each job to complete, then add its result to the results array and update the progress bar
    $results += Receive-Job -Job $job -Wait
    Remove-Job -Job $job
    $progressCount++
    Write-Progress -Activity 'Checking Defender status' -Status "$progressCount of $progressTotal computers checked" -PercentComplete (($progressCount / $progressTotal) * 100)
}

# Export the results to the CSV file
$results | Export-Csv -Path $output -NoTypeInformation

# Complete progress bar
Write-Progress -Activity 'Checking Defender status' -Completed
