[Cmdletbinding()]
param(
    [parameter(Mandatory = $true)] [string]$virtualMachineResourceGroupName,
    [parameter(Mandatory = $true)] [string]$virtualMachineName,
    [parameter(Mandatory = $true)] [string]$VirtualMachineSize,
    [parameter(Mandatory = $true)] [string]$virtualNetworkName,
    [parameter(Mandatory = $true)] [string]$virtualNetworkResourceGroupName,
    [parameter(Mandatory = $true)] [string]$virtualNetworkSubnetName,
    [parameter(Mandatory = $true)] [string]$Location,
    [parameter(Mandatory = $true)] [string]$osDiskName,
    [parameter(Mandatory = $false)] $DataDisks = @(),
    [parameter(Mandatory = $false)] $planConfig
)

# Register EncryptionAtHost feature
Register-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute" | Out-Null

# Initialize virtual machine configuration
$vmConfigParams = @{
    VMName = $virtualMachineName
    VMSize = $VirtualMachineSize
    EncryptionAtHost = $true
}
$VirtualMachine = New-AzVMConfig @vmConfigParams

$disk = Get-AzDisk -DiskName $osDiskName

# Use the Managed Disk Resource Id to attach it to the virtual machine. Please change the OS type to linux if OS disk has linux OS
$osDiskParams = @{
    VM = $VirtualMachine
    ManagedDiskId = $disk.Id
    CreateOption = 'Attach'
}
if ($disk.OsType -eq "Windows") {
    $osDiskParams.Windows = $true
    $VirtualMachine = Set-AzVMOSDisk @osDiskParams
} else {
    $osDiskParams.Caching = $disk.tags.Caching
    $osDiskParams.Linux = $true
    $VirtualMachine = Set-AzVMOSDisk @osDiskParams
}

# Add provided data disks
$lunNumber = 0
foreach ($DataDisk in $DataDisks) {
    $dd = Get-AzDisk -DiskName $DataDisk.Name -ResourceGroupName $DataDisk.resourceGroupName
    $dataDiskParams = @{
        Name = $dd.Name
        VM = $VirtualMachine
        ManagedDiskId = $dd.Id
        Caching = $DataDisk.Caching
        Lun = $lunNumber
        CreateOption = 'Attach'
    }
    $VirtualMachine = Add-AzVMDataDisk @dataDiskParams
    $lunNumber++
}

# Get the virtual network where virtual machine will be hosted
$vnet = Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $virtualNetworkResourceGroupName
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $virtualNetworkSubnetName -VirtualNetwork $vnet

# Create NIC in the first subnet of the virtual network
$nicParams = @{
    Name = "nic-$($VirtualMachineName.ToLower())"
    ResourceGroupName = $virtualMachineResourceGroupName
    Location = $Location
    SubnetId = $subnet.Id
    Force = $true
}
$nic = New-AzNetworkInterface @nicParams

$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $nic.Id
$VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Enable
$VirtualMachine = Set-AzVmSecurityProfile -VM $VirtualMachine -SecurityType "TrustedLaunch"
$VirtualMachine = Set-AzVmUefi -VM $VirtualMachine -EnableVtpm $True -EnableSecureBoot $True

if ($planConfig) {
    Set-AzMarketplaceTerms @planConfig -Accept
    $VirtualMachine | Set-AzVmPlan @planConfig
}

# Create the virtual machine with Managed Disk
$vmParameters = @{
    VM = $VirtualMachine
    ResourceGroupName = $virtualMachineResourceGroupName
    Location = $Location
}

try {
    $VM = New-AzVM @vmParameters -ErrorAction Stop
} catch {
    Write-Warning "$($Error[0].Exception.Message)"
    if ($error[0].Exception.Message -match "Security type of VM is not compatible with the security type of attached OS Disk") {
        Write-Verbose "Creating VM with standard security type"
        $VirtualMachine.SecurityProfile = $null
        $VirtualMachine = Set-AzVmSecurityProfile -VM $VirtualMachine -SecurityType "Standard"
        $VM = New-AzVM @vmParameters -ErrorAction Continue
    } else {
        throw "$($Error[0].Exception.Message)"
    }
}

# Set the primary IP configuration of the NIC to static
$createdVirtualMachine = Get-AzVM -Name $virtualMachineName -ResourceGroupName $virtualMachineResourceGroupName
$nic = Get-AzNetworkInterface -ResourceId $createdVirtualMachine.NetworkProfile.NetworkInterfaces[0].Id
$config = @{
    Name = $nic.IpConfigurations[0].Name
    PrivateIpAddress = $nic.IpConfigurations[0].PrivateIpAddress
    Subnet = $nic.IpConfigurations[0].subnet
}
$nic | Set-AzNetworkInterfaceIpConfig @config -Primary | Out-Null
$nic | Set-AzNetworkInterface | Out-Null