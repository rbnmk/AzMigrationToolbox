<#
.SYNOPSIS
Script for creating Managed Disks by supplying the name of one or more snapshots. Can be used in conjunction with Create-AzVmSnapshots.

.DESCRIPTION
This script is intended to be run from PowerShell in your current AzContext.

.EXAMPLE
.\Create-ManagedDisksFromSnapshots.ps1 -Snapshots $Snapshots -resourceGroupName snapshotrg

.EXAMPLE
.\Create-ManagedDisksFromSnapshots.ps1 -Snapshots FILESERVER_SNAPSHOT -resourceGroupName snapshotrg

.EXAMPLE
https://github.com/rbnmk/posh/blob/master/scripts/Create-ManagedDisksFromSnapshots.ps1

Created by RBNMK
#>

[Cmdletbinding()]
param (
    [parameter(mandatory = $true)]$Snapshots,
    [parameter(mandatory = $true)]$srcResourceGroupName,
    [parameter(mandatory = $true)]$srcSubscriptionId,
    [parameter(mandatory = $true)]$dstResourceGroupName,
    [parameter(mandatory = $true)]$dstSubscriptionId
)

$Disks = @()
$diskNumber = 1
foreach ($existingSnapshot in $Snapshots) {
    # Check context
    $Context = Get-AzContext
    if (!$Context) {
        Write-Warning "No Azure context found. Please login to your Azure account first."
        Connect-AzAccount
        $Context = Get-AzContext
        if ($Context.Subscription.Id -ne $srcSubscriptionId) {
            Write-Warning "The subscription ID provided does not match the current context. Switching to the correct subscription."
            Set-AzContext -SubscriptionId $srcSubscriptionId
        }
    }
    elseif ($Context.Subscription.Id -ne $srcSubscriptionId) {
        Write-Warning "The subscription ID provided does not match the current context. Switching to the correct subscription."
        Set-AzContext -SubscriptionId $srcSubscriptionId
    }

    # Check if the resource group exists
    Try {
        $rgParams = @{
            ResourceGroupName = $srcResourceGroupName
            ErrorAction       = 'Stop'
        }
        $rg = Get-AzResourceGroup @rgParams
    }
    catch {
        Write-Warning "$($Error[0].Exception.Message)"
        Break
    }

    Try {
        $snapshotParams = @{
            ResourceGroupName = $srcResourceGroupName
            SnapshotName      = $existingSnapshot.name
            ErrorAction       = 'Stop'
        }
        $Snapshot = Get-AzSnapshot @snapshotParams
    }
    catch {
        Write-Warning "$($Error[0].Exception.Message)"
        Break
    }

    Try {
        if ($existingSnapshot.type -eq "osdisk") {
            $diskName = "$($existingSnapshot.vmName)-osdisk"
        }
        else {
            $diskName = "$($existingSnapshot.vmName)-datadisk-$disknumber"
            $diskNumber++
        }

        $diskConfigParams = @{
            Location         = $Snapshot.Location
            SourceResourceId = $Snapshot.Id
            SkuName          = $existingSnapshot.skuName
            Tier             = $existingSnapshot.Tier
            CreateOption     = 'Copy'
            ErrorAction      = 'Stop'
        }

        if ($existingSnapshot.DiskIOPSReadWrite) { $diskConfigParams.Add("DiskIOPSReadWrite", $existingSnapshot.DiskIOPSReadWrite) }
        if ($existingSnapshot.DiskIOPSReadWrite) { $diskConfigParams.Add("DiskMBpsReadWrite", $existingSnapshot.DiskMBpsReadWrite) }
        if ($existingSnapshot.OsType) { $diskConfigParams.add("OsType", $existingSnapshot.OsType) }

        $diskConfig = New-AzDiskConfig @diskConfigParams
    }
    catch {
        Write-Warning "$($Error[0].Exception.Message)"
        Break
    }

    $Context = Get-AzContext
    if (!$Context) {
        Write-Warning "No Azure context found. Please login to your Azure account first."
        Connect-AzAccount
        $Context = Get-AzContext
        if ($Context.Subscription.Id -ne $dstSubscriptionId) {
            Write-Warning "The subscription ID provided does not match the current context. Switching to the correct subscription."
            Set-AzContext -SubscriptionId $dstSubscriptionId
        }
    }
    elseif ($Context.Subscription.Id -ne $dstSubscriptionId) {
        Write-Warning "The subscription ID provided does not match the current context. Switching to the correct subscription."
        Set-AzContext -SubscriptionId $dstSubscriptionId
    }

    $managedDiskParams = @{
        Disk              = $diskConfig
        ResourceGroupName = $dstResourceGroupName
        DiskName          = $DiskName.toLower()
    }
    $managedDisk = New-AzDisk @managedDiskParams | Out-Null

    $diskParams = @{
        DiskName          = $diskName
        ResourceGroupName = $dstResourceGroupName
    }
    $Disk = Get-AzDisk @diskParams

    $tagParams = @{
        ResourceId = $disk.Id
        Operation  = 'Merge'
        Tag        = @{
            snapshotSourceName = $existingSnapshot.name
            snapshotSourceLun  = $existingSnapshot.lun
            skuName            = $existingSnapshot.skuName
            skuTier            = $existingSnapshot.skuTier
            caching            = $existingSnapshot.caching
        }
    }
    Update-AzTag @tagParams | Out-Null

    $Disks += [PSCustomObject]@{
        Name              = $Disk.Name
        ResourceGroupName = $Disk.ResourceGroupName
        ResourceId        = $Disk.Id
        Sku               = $Disk.Sku
        Caching           = $existingSnapshot.caching
        Lun               = $existingSnapshot.lun
        Type              = $existingSnapshot.type
    }

    Write-Host "Created $($Disk.Name)" -ForegroundColor Green
}

Return $Disks
