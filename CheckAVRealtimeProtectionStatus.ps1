# Import the Active Directory and ThreadJob modules
Import-Module ActiveDirectory
Import-Module ThreadJob

# Specify the OUs to search in
$ous = @("OU=Domain Controllers,DC=contoso,DC=com","OU=Servers,DC=contoso,DC=com")

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
        # Get the Defender status
        $defenderStatus = Invoke-Command -ComputerName $computer -ScriptBlock {
            try {
                $defender = Get-MpComputerStatus
                return $defender.RealTimeProtectionEnabled.ToString()
            } 
            catch {
                return $null
            }
        } -ErrorAction SilentlyContinue

        # Define the status
        $status = switch ($defenderStatus) {
            "True" { "Enabled" }
            "False" { "Disabled" }
            $null { "Error or No Defender" }
        }

        # Add the status to the results
        return New-Object -TypeName PSObject -Property @{
            ComputerName = $computer
            Status = $status
        }
    } else {
        # Add an error to the results
        return New-Object -TypeName PSObject -Property @{
            ComputerName = $computer
            Status = "Unreachable"
        }
    }
}

# Launch jobs
$jobs = $computers | ForEach-Object { Start-ThreadJob -ScriptBlock $scriptBlock -ArgumentList $_ }

# Gather results
$results = $jobs | Receive-Job -Wait -AutoRemoveJob

# Export the results to the CSV file
$results | Export-Csv -Path $output -NoTypeInformation
