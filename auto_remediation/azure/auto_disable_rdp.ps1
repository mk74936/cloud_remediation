param (
    [string]$ResourceGroupName
)

# Connect to Azure (Azure Automation runbooks are system-assigned)
Write-Output "Connecting to Azure..."
Connect-AzAccount -Identity

# Get all NSGs in the resource group
$nsgs = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName

foreach ($nsg in $nsgs) {
    $rulesToRemove = @()

    foreach ($rule in $nsg.SecurityRules) {
        if ($rule.DestinationPortRange -eq "3389" -and $rule.Access -eq "Allow") {
            Write-Output "RDP rule found: $($rule.Name) in NSG: $($nsg.Name)"
            $rulesToRemove += $rule
        }
    }

    foreach ($rule in $rulesToRemove) {
        Write-Output "Removing rule: $($rule.Name)"
        Remove-AzNetworkSecurityRuleConfig -Name $rule.Name -NetworkSecurityGroup $nsg
    }

    if ($rulesToRemove.Count -gt 0) {
        Write-Output "Updating NSG: $($nsg.Name)"
        Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg
    }
}

Write-Output "RDP rule cleanup completed."
