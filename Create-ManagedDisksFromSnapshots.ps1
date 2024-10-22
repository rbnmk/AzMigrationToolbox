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

    Try {
        if ($existingSnapshot.type -eq "osdisk") {
            $diskName = "$($existingSnapshot.vmName)-osdisk"
        }
        else {
            $diskName = "$($existingSnapshot.vmName)-datadisk-$disknumber"
            $diskNumber++
        }

        $diskConfigParams = @{
            Location         = $existingSnapshot.Location
            SourceResourceId = $existingSnapshot.ResourceId
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
