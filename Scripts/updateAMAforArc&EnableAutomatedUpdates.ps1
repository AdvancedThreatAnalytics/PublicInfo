Install-Module Az.ConnectedMachine
connect-azaccount

# Define the target versions for the extensions check here for version number https://learn.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-extension-versions
$targetVersionWindows = "1.29"
$targetVersionLinux = "1.32.2"

# Get all available Azure contexts
$contexts = Get-AzContext -ListAvailable

# Loop through each context
foreach ($context in $contexts) {
    # Set the current context
    Set-AzContext -SubscriptionId $context.Subscription.Id

    # Get all Azure Arc VMs in the current subscription that are connected
    $arcVMs = Get-AzConnectedMachine | Where-Object { $_.Status -eq "Connected" }

    # Loop through each Azure Arc VM and update the extensions
    foreach ($vm in $arcVMs) {
        # Define the target for Windows and Linux extensions
        $targetWindows = @{"Microsoft.Azure.Monitor.AzureMonitorWindowsAgent" = @{"targetVersion" = $targetVersionWindows}}
        $targetLinux = @{"Microsoft.Azure.Monitor.AzureMonitorLinuxAgent" = @{"targetVersion" = $targetVersionLinux}}

        # Check the OS type and update the appropriate extension
        if ($vm.OsType -eq "Windows") {
            Update-AzConnectedExtension -ResourceGroupName $vm.ResourceGroupName -MachineName $vm.Name -ExtensionTarget $targetWindows
            Write-Output "Updated AzureMonitorWindowsAgent for VM $($vm.Name) in subscription $($context.Subscription.Id)"

            # Enable automatic updates for Windows VM
            Update-AzConnectedMachineExtension -ResourceGroupName $vm.ResourceGroupName -MachineName $vm.Name -Name "AzureMonitorWindowsAgent" -EnableAutomaticUpgrade
            Write-Output "Enabled automatic updates for AzureMonitorWindowsAgent on VM $($vm.Name)"
        } elseif ($vm.OsType -eq "Linux") {
            Update-AzConnectedExtension -ResourceGroupName $vm.ResourceGroupName -MachineName $vm.Name -ExtensionTarget $targetLinux
            Write-Output "Updated AzureMonitorLinuxAgent for VM $($vm.Name) in subscription $($context.Subscription.Id)"

            # Enable automatic updates for Linux VM
            Update-AzConnectedMachineExtension -ResourceGroupName $vm.ResourceGroupName -MachineName $vm.Name -Name "AzureMonitorLinuxAgent" -EnableAutomaticUpgrade
            Write-Output "Enabled automatic updates for AzureMonitorLinuxAgent on VM $($vm.Name)"
        }
    }
}
