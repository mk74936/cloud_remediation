param (
    [string]$ResourceGroupName
)

Write-Output "Connecting to Azure..."
Connect-AzAccount -Identity

$vmList = Get-AzVM -ResourceGroupName $ResourceGroupName

foreach ($vm in $vmList) {
    Write-Output "Tagging VM: $($vm.Name)"
    $tags = $vm.Tags
    if (-not $tags) {
        $tags = @{}
    }
    $tags["Compliance"] = "NonCompliant"
    $tags["LastChecked"] = (Get-Date).ToString("s")

    Set-AzResource -ResourceId $vm.Id -Tag $tags -Force
}
