[CmdletBinding()]
param(
    $virtualMachineMappingConfig = @(
        @{
            srcVirtualMachineName                            = "vm15"; 
            srcVirtualMachineResourceGroupName               = "rg1"; 
            srcVirtualMachineSubscriptionId                  = ""; 
            dstVirtualMachineName                            = "vm15" ; 
            dstVirtualMachineResourceGroupName               = "rg2"; 
            dstVirtualMachineSubscriptionId                  = ""; 
            dstVirtualMachineVirtualNetworkName              = "vnet"; 
            dstVirtualMachineVirtualNetworkResourceGroupName = "networkrg"; 
            dstVirtualMachineVirtualNetworkSubnetName        = "subnet1"
        }
    )
)

$virtualMachineMappingConfig | Sort-Object $_.srcVirtualMachineSubscriptionId  | Foreach-Object -ThrottleLimit 10 -Parallel {

    Write-Verbose "Processing VM: $($_.srcVirtualMachineName)"

    Try {
        $Context = Set-AzContext -SubscriptionId $_.srcVirtualMachineSubscriptionId 
        $VirtualMachine = Get-AzVM -ResourceGroupName $_.srcVirtualMachineResourceGroupName -Name $_.srcVirtualMachineName
    }
    catch {
        Write-Warning "$($Error[0].Exception.Message)"
        Continue
    }

    $SnapshotParameters = @{
        vmName            = $_.srcVirtualMachineName; 
        resourceGroupName = $_.srcVirtualMachineResourceGroupName; 
        subscriptionId    = $_.srcVirtualMachineSubscriptionId; 
    }

    $Snapshots = .\Create-AzVmSnapshots.ps1 @SnapshotParameters

    Write-Host $($Snapshots | Format-Table | Out-String)

    $ManagedDiskParameters = @{
        Snapshots            = $Snapshots; 
        srcResourceGroupName = $_.srcVirtualMachineResourceGroupName; 
        srcSubscriptionId    = $_.srcVirtualMachineSubscriptionId; 
        dstResourceGroupName = $_.dstVirtualMachineResourceGroupName; 
        dstSubscriptionId    = $_.dstVirtualMachineSubscriptionId; 
    }

    $Disks = .\Create-ManagedDisksFromSnapshots.ps1 @ManagedDiskParameters

    Write-Host $($Disks | Format-Table | Out-String)


    $VmFromManagedDisksParameters = [ordered]@{
        virtualMachineResourceGroupName = $_.dstVirtualMachineResourceGroupName
        virtualMachineName              = $_.dstVirtualMachineName
        virtualNetworkName              = $_.dstVirtualMachineVirtualNetworkName
        virtualNetworkResourceGroupName = $_.dstVirtualMachineVirtualNetworkResourceGroupName
        virtualNetworkSubnetName        = $_.dstVirtualMachineVirtualNetworkSubnetName
        virtualMachineSize              = $VirtualMachine.HardwareProfile.VmSize
        Location                        = $VirtualMachine.Location
        osDiskName                      = ($Disks | Where-Object { $_.type -match "osdisk" }).Name
        DataDisks                       = ($Disks | Where-Object { $_.type -match "datadisk" })
        planConfig                      = $VirtualMachine.Plan
    }

    Write-Host $($VmFromManagedDisksParameters | Format-Table | Out-String)

    Update-AzConfig -DisplayRegionIdentified $false
    .\Create-VmFromManagedDisks.ps1 @VmFromManagedDisksParameters
    Update-AzConfig -DisplayRegionIdentified $true
    
}