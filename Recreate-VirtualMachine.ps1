[CmdletBinding()]
param(
    $virtualMachineMappingConfig = @(
        @{
            srcVirtualMachineName                            = "vm1"; 
            srcVirtualMachineResourceGroupName               = "rg1"; 
            srcVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineName                            = "vm1tovm2" ; 
            dstVirtualMachineResourceGroupName               = "rg2"; 
            dstVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineVirtualNetworkName              = "vnet"; 
            dstVirtualMachineVirtualNetworkResourceGroupName = "rg2"; 
            dstVirtualMachineVirtualNetworkSubnetName        = "default"
        }
        @{
            srcVirtualMachineName                            = "vm2"; 
            srcVirtualMachineResourceGroupName               = "rg1"; 
            srcVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineName                            = "vm2tovm2" ; 
            dstVirtualMachineResourceGroupName               = "rg2"; 
            dstVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineVirtualNetworkName              = "vnet"; 
            dstVirtualMachineVirtualNetworkResourceGroupName = "rg2"; 
            dstVirtualMachineVirtualNetworkSubnetName        = "default"
        }
        @{
            srcVirtualMachineName                            = "vm3"; 
            srcVirtualMachineResourceGroupName               = "rg1"; 
            srcVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineName                            = "vm3tovm2" ; 
            dstVirtualMachineResourceGroupName               = "rg2"; 
            dstVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineVirtualNetworkName              = "vnet"; 
            dstVirtualMachineVirtualNetworkResourceGroupName = "rg2"; 
            dstVirtualMachineVirtualNetworkSubnetName        = "default"
        }
        @{
            srcVirtualMachineName                            = "vm4"; 
            srcVirtualMachineResourceGroupName               = "rg1"; 
            srcVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineName                            = "vm4tovm2" ; 
            dstVirtualMachineResourceGroupName               = "rg2"; 
            dstVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineVirtualNetworkName              = "vnet"; 
            dstVirtualMachineVirtualNetworkResourceGroupName = "rg2"; 
            dstVirtualMachineVirtualNetworkSubnetName        = "default"
        }
        @{
            srcVirtualMachineName                            = "vm5"; 
            srcVirtualMachineResourceGroupName               = "rg1"; 
            srcVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineName                            = "vm5tovm2" ; 
            dstVirtualMachineResourceGroupName               = "rg2"; 
            dstVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineVirtualNetworkName              = "vnet"; 
            dstVirtualMachineVirtualNetworkResourceGroupName = "rg2"; 
            dstVirtualMachineVirtualNetworkSubnetName        = "default"
        }
        @{
            srcVirtualMachineName                            = "vm6"; 
            srcVirtualMachineResourceGroupName               = "rg1"; 
            srcVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineName                            = "vm6tovm2" ; 
            dstVirtualMachineResourceGroupName               = "rg2"; 
            dstVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineVirtualNetworkName              = "vnet"; 
            dstVirtualMachineVirtualNetworkResourceGroupName = "rg2"; 
            dstVirtualMachineVirtualNetworkSubnetName        = "default"
        }
        @{
            srcVirtualMachineName                            = "vm7"; 
            srcVirtualMachineResourceGroupName               = "rg1"; 
            srcVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineName                            = "vm7tovm2" ; 
            dstVirtualMachineResourceGroupName               = "rg2"; 
            dstVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineVirtualNetworkName              = "vnet"; 
            dstVirtualMachineVirtualNetworkResourceGroupName = "rg2"; 
            dstVirtualMachineVirtualNetworkSubnetName        = "default"
        }
        @{
            srcVirtualMachineName                            = "vm8"; 
            srcVirtualMachineResourceGroupName               = "rg1"; 
            srcVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineName                            = "vm8tovm2" ; 
            dstVirtualMachineResourceGroupName               = "rg2"; 
            dstVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineVirtualNetworkName              = "vnet"; 
            dstVirtualMachineVirtualNetworkResourceGroupName = "rg2"; 
            dstVirtualMachineVirtualNetworkSubnetName        = "default"
        }
        @{
            srcVirtualMachineName                            = "vm9"; 
            srcVirtualMachineResourceGroupName               = "rg1"; 
            srcVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineName                            = "vm9tovm2" ; 
            dstVirtualMachineResourceGroupName               = "rg2"; 
            dstVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineVirtualNetworkName              = "vnet"; 
            dstVirtualMachineVirtualNetworkResourceGroupName = "rg2"; 
            dstVirtualMachineVirtualNetworkSubnetName        = "default"
        }
        @{
            srcVirtualMachineName                            = "vm10"; 
            srcVirtualMachineResourceGroupName               = "rg1"; 
            srcVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineName                            = "vm10tovm2" ; 
            dstVirtualMachineResourceGroupName               = "rg2"; 
            dstVirtualMachineSubscriptionId                  = "49170441-ebef-47c3-9905-70ee5fdb7d38"; 
            dstVirtualMachineVirtualNetworkName              = "vnet"; 
            dstVirtualMachineVirtualNetworkResourceGroupName = "rg2"; 
            dstVirtualMachineVirtualNetworkSubnetName        = "default"
        }
    )
)

$virtualMachineMappingConfig | Foreach-Object -ThrottleLimit 10 -Parallel {

    Write-Verbose "Processing VM: $($_.srcVirtualMachineName)"


    Try {
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