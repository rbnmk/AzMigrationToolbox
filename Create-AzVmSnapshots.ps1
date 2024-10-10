<#
.SYNOPSIS
Script for creating Snapshots of all disks of a single VM and create a variable for you to use. 
You can use this to create a managed disk by using an other command after creating the snapshot.

.DESCRIPTION
This script is intended to be run from PowerShell in your current AzContext

.EXAMPLE
$Snapshots = .\Create-AzVmSnapshots.ps1 `
                    -vmName FILESERVER `
                    -resourceGroupName Servers

.EXAMPLE
$osDiskSnapshot = .\Create-AzVmSnapshots.ps1 `
                    -vmName FILESERVER `
                    -resourceGroupName Servers `
                    -osDiskOnly

Created by RBNMK
#>

[CmdletBinding()]
param(
    [parameter(mandatory = $true)] [string] $vmName,
    [parameter(mandatory = $true)] [string] $resourceGroupName,
    [parameter(mandatory = $true)] [string] $subscriptionId,
    [parameter(mandatory = $false)] [switch] $osDiskOnly
)

### Check AZ Context
$Context = Get-AzContext

if (!$Context) {
    Write-Warning "No Azure context found. Please login to your Azure account first."
    Connect-AzAccount
}
elseif ($Context.Subscription.Id -ne $subscriptionId) {
    Write-Warning "The subscription ID provided does not match the current context. Switching to the correct subscription."
    Set-AzContext -SubscriptionId $subscriptionId
}

### Try to get all needed resources and declare variables
$Snapshots = @()

Try {
    $Location = (Get-AzResourceGroup -Name $resourceGroupName -ErrorAction Stop).Location
}
catch {
    Write-Warning "$($Error[0].Exception.Message)"
    Break
}

Try {
    $vmParams = @{
        ResourceGroupName = $resourceGroupName
        Name = $vmName
        ErrorAction = 'Stop'
    }
    $virtualMachine = Get-AzVM @vmParams
}
catch {
    Write-Warning "$($Error[0].Exception.Message)"
    Break
}

$vmStatusParams = @{
    ResourceGroupName = $resourceGroupName
    Name = $vmName
    Status = $true
}
$vmStatus = Get-AzVM @vmStatusParams

if ($vmStatus.Statuses.displaystatus -match "VM Running") { 
    Write-Warning -Message "The VM is currently running. It is recommended that you turn off the VM first! Turning off first.."

    Stop-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Force | Out-Null
    
    Do {
        $vmStatus = Get-AzVM @vmStatusParams
        Start-Sleep -Seconds 2
        Write-Host "Checking VM status"
        Write-Host "." -NoNewline
    }
    until ($vmStatus.Statuses.displaystatus -notmatch "VM Running")
    Write-Host "Continuing with snapshot creation.."
}

### Get the OSDisk SKU

$OsDisk = Get-AzResource -ResourceId $virtualMachine.StorageProfile.OsDisk.ManagedDisk.Id | Select-Object Name, ResourceGroupName | Get-AzDisk
$OsDiskSku = $osDisk.Sku
$OsDiskSkuName = $osDisk.Sku.Name
$OsDiskSkuTier = $osDisk.Sku.Tier
$OsDiskTier = $osDisk.Tier
$OsDiskIOPSReadWrite = $osDisk.DiskIOPSReadWrite
$OsDiskMBpsReadWrite = $osDisk.DiskMBpsReadWrite
$OsDiskCaching = $datadisk.Caching
$OsDiskCaching = $virtualMachine.StorageProfile.OsDisk.Caching

switch ($OsDiskSkuName) {
    "StandardSSD_LRS" { $OsDiskSnapShotSkuName = "Standard_LRS" }
    default { $OsDiskSnapShotSkuName = $OsDiskSkuName }
}

Write-Verbose "$VMName OSDisk: $($virtualMachine.StorageProfile.OsDisk.Name)"
Write-Verbose "$VMName OSDisk SKU: $($OsDiskSku)"
Write-Verbose "$VMName OSDisk SKU Name: $($OsDiskSkuName)"
Write-Verbose "$VMName OSDisk SKU Tier: $($OsDiskSkuTier)"
Write-Verbose "$VMName OSDisk Caching: $($OsDiskCaching)"

### Create the snapshot for the OS Disk of the supplied VM
$snapshotConfigParams = @{
    SourceUri = $virtualMachine.StorageProfile.OsDisk.ManagedDisk.Id
    Location = $Location
    SkuName = $OsDiskSnapShotSkuName
    CreateOption = 'copy'
}
$Snapshot = New-AzSnapshotConfig @snapshotConfigParams

$snapshotParams = @{
    SnapshotName = "$($virtualMachine.StorageProfile.OsDisk.Name)_snapshot_$(Get-Date -Format filedate)"
    ResourceGroupName = $resourceGroupName
    ErrorAction = 'SilentlyContinue'
}
$SnapshotExists = Get-AzSnapshot @snapshotParams

if ($SnapshotExists) {
    $updateSnapshotParams = @{
        Snapshot = $Snapshot
        SnapshotName = "$($virtualMachine.StorageProfile.OsDisk.Name)_snapshot_$(Get-Date -Format filedate)"
        ResourceGroupName = $resourceGroupName
    }
    $osDiskSnapshot = Update-AzSnapshot @updateSnapshotParams
}
else {
    $newSnapshotParams = @{
        Snapshot = $Snapshot
        SnapshotName = "$($virtualMachine.StorageProfile.OsDisk.Name)_snapshot_$(Get-Date -Format filedate)"
        ResourceGroupName = $resourceGroupName
    }
    $osDiskSnapshot = New-AzSnapshot @newSnapshotParams
}

Write-Host "Creating snapshot.. $($osDiskSnapshot.Name)" -ForegroundColor Green

$Snapshots += [PSCustomObject]@{
    vmName  = $vmName
    lun     = "nolun"
    type    = "osdisk"
    name    = $osDiskSnapshot.Name
    sku     = $OsDiskSku
    skuName = $OsdiskSkuName
    skuTier = $OsDiskSkuTier
    caching = $OsDiskCaching
    Tier = $OsDiskTier
    IOPSReadWrite = $OsDiskIOPSReadWrite
    DataDiskMBpsReadWrite = $OsDiskMBpsReadWrite
}

### Create the snapshot(s) for the Data disks of the supplied VM

if ($osDiskOnly) { 
    Write-Host "Skipping datadisks..." 
}
else {
    if (!($virtualMachine.StorageProfile.DataDisks)) { 
        Write-Host "No datadisks found for $($VirtualMachine.Name)" -ForegroundColor Cyan 
    }
    else {
        foreach ($datadisk in $virtualMachine.StorageProfile.DataDisks | Sort-Object Lun) {

            $Disk = Get-AzResource -ResourceId $datadisk.ManagedDisk.Id | Select-Object Name, ResourceGroupName | Get-AzDisk

            $DataDiskSku = $Disk.Sku
            $DataDiskDiskSkuName = $Disk.Sku.Name
            $DataDiskSkuTier = $Disk.Sku.Tier
            $DataDiskTier = $Disk.Tier
            $DataDiskIOPSReadWrite = $Disk.DiskIOPSReadWrite
            $DataDiskMBpsReadWrite = $Disk.DiskMBpsReadWrite
            $DataDiskCaching = $datadisk.Caching

            switch ($DataDiskDiskSkuName) {
                "StandardSSD_LRS" { $DataDiskSnapshotSkuName = "Standard_LRS" }
                default { $DataDiskSnapshotSkuName = $DataDiskDiskSkuName }
            }

            Write-Verbose "$VMName DataDisk: $($datadisk.Name)"
            Write-Verbose "$VMName DataDisk SKU: $($DataDiskSku)"
            Write-Verbose "$VMName DataDisk SKU Name: $($DataDiskDiskSkuName)"
            Write-Verbose "$VMName DataDisk SKU Tier: $($DataDiskSkuTier)"
            Write-Verbose "$VMName DataDisk Caching: $($DataDiskCaching)"

            $snapshotConfigParams = @{
                SourceUri = $datadisk.ManagedDisk.Id
                Location = $Location
                SkuName = $DataDiskSnapshotSkuName
                CreateOption = 'copy'
            }
            $Snapshot = New-AzSnapshotConfig @snapshotConfigParams

            $snapshotParams = @{
                SnapshotName = "$($datadisk.name)_snapshot_$(Get-Date -Format filedate)"
                ResourceGroupName = $resourceGroupName
                ErrorAction = 'SilentlyContinue'
            }
            $SnapshotExists = Get-AzSnapshot @snapshotParams
            
            if ($SnapshotExists) {
                $updateSnapshotParams = @{
                    Snapshot = $Snapshot
                    SnapshotName = "$($datadisk.name)_snapshot_$(Get-Date -Format filedate)"
                    ResourceGroupName = $resourceGroupName
                }
                $dataDiskSnapshot = Update-AzSnapshot @updateSnapshotParams
            }
            else {
                try {
                    $newSnapshotParams = @{
                        Snapshot = $Snapshot
                        SnapshotName = "$($datadisk.name)_snapshot_$(Get-Date -Format filedate)"
                        ResourceGroupName = $resourceGroupName
                        ErrorAction = 'Stop'
                    }
                    $dataDiskSnapshot = New-AzSnapshot @newSnapshotParams
                }
                catch {
                    throw 
                }
            }

            Write-Host "Creating snapshot.. $($dataDiskSnapshot.Name)" -ForegroundColor Green
            $Snapshots += [PSCustomObject]@{
                vmName  = $vmName
                type    = "datadisk"
                name    = $dataDiskSnapshot.Name
                lun     = $datadisk.Lun
                sku     = $DataDiskSku
                skuName = $DataDiskDiskSkuName
                skuTier = $DataDiskSkuTier
                caching = $DataDiskCaching
                Tier = $DataDiskTier
                IOPSReadWrite = $DataDiskIOPSReadWrite
                DataDiskMBpsReadWrite = $DataDiskMBpsReadWrite
            }  
        }
    }
}

$Snapshots