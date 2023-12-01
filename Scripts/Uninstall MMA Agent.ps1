$AzureVMs = Get-AzVM
foreach ($VM in $AzureVMs) {
    try {
        $extensions = Get-AzVMExtension -ResourceGroupName $VM.ResourceGroupName -VMName $VM.Name
        $found = $false

        foreach ($extension in $extensions) {
            if ($extension.Name -eq "MicrosoftMonitoringAgent") {
                Write-Host "MicrosoftMonitoringAgent is Installed in" $VM.Name -ForegroundColor Cyan
                Remove-AzVMExtension -ResourceGroupName $VM.ResourceGroupName -VMName $VM.Name -Name "MicrosoftMonitoringAgent" -Force 
                break
            } elseif ($extension.Name -eq "OMSAgentForLinux") {
                Write-Host "OMSAgentForLinux is Installed in" $VM.Name -ForegroundColor Cyan
                Remove-AzVMExtension -ResourceGroupName $VM.ResourceGroupName -VMName $VM.Name -Name "OMSAgentForLinux" -Force 
                $found = $true
                break
            }
        }

        if (-not $found) {
            Write-Host "MicrosoftMonitoringAgent or OMSAgentForLinux is Not Installed in" $VM.Name -ForegroundColor Red
        }
    } catch {
        Write-Host "Error processing VM $($VM.Name): $_" -ForegroundColor Red
    }
}

