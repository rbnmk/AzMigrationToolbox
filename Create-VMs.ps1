<#
.SYNOPSIS
Creates multiple Azure VMs in a specified resource group and virtual network.

.DESCRIPTION
This script creates a specified number of Azure VMs in a given resource group and virtual network. 
It allows customization of VM size, image, and other properties through parameters.

.PARAMETER LocationName
The Azure region where the resources will be created. Default is 'westeurope'.

.PARAMETER ResourceGroupName
The name of the resource group where the VMs will be created. Default is 'rg1'.

.PARAMETER NetworkName
The name of the virtual network where the VMs will be connected. Default is 'vm1-vnet'.

.PARAMETER VMCount
The number of VMs to create. Default is 4.

.PARAMETER PublisherName
The publisher of the VM image. Default is 'MicrosoftWindowsServer'.

.PARAMETER Offer
The offer of the VM image. Default is 'WindowsServer'.

.PARAMETER Skus
The SKU of the VM image. Default is '2022-datacenter-azure-edition-hotpatch'.

.PARAMETER VMSize
The size of the VMs to be created. Default is 'Standard_D2s_v3'.

#>

param (
  [string]$LocationName = "westeurope",
  [string]$ResourceGroupName = "rg1",
  [string]$NetworkName = "vm1-vnet",
  [int]$VMCount = 4,
  [string]$PublisherName = "MicrosoftWindowsServer",
  [string]$Offer = "WindowsServer",
  [string]$Skus = "2022-datacenter-azure-edition-hotpatch",
  [string]$VMSize = "Standard_D2s_v3"
)

Write-Warning "This script should only be used for testing purposes"

# Get the virtual network
$vnet = Get-AzVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName

# Get credentials for the VMs
$credential = Get-Credential -Message "Enter the credentials for each of the VMs"

1..$VMCount | ForEach-Object -ThrottleLimit 10 -Parallel {
  param (
    $using:ResourceGroupName,
    $using:LocationName,
    $using:vnet,
    $using:PublisherName,
    $using:Offer,
    $using:Skus,
    $using:VMSize,
    [secureString]$using:credential
  )

  $vmName = ("vm{0}" -f $_)
  $nicParams = @{
    Name                 = "nic$vmName"
    ResourceGroupName    = $using:ResourceGroupName
    Location             = $using:LocationName
    SubnetId             = $using:vnet.Subnets[0].Id
    Force                = $true
  }
  $nic = New-AzNetworkInterface @nicParams

  $vmConfigParams = @{
    VMName   = $vmName
    VMSize   = $using:VMSize
  }
  $VirtualMachine = New-AzVMConfig @vmConfigParams

  $dataDiskParams = @(
    @{
      Name              = "dd$vmName"
      VM                = $VirtualMachine
      StorageAccountType= "Standard_LRS"
      DiskSizeInGB      = 25
      CreateOption      = "Empty"
      DeleteOption      = "Delete"
      Caching           = "ReadWrite"
      Lun               = 0
    },
    @{
      Name              = "dd2$vmName"
      VM                = $VirtualMachine
      StorageAccountType= "StandardSSD_LRS"
      DiskSizeInGB      = 25
      CreateOption      = "Empty"
      DeleteOption      = "Delete"
      Caching           = "ReadOnly"
      Lun               = 1
    },
    @{
      Name              = "dd3$vmName"
      VM                = $VirtualMachine
      StorageAccountType= "Standard_LRS"
      DiskSizeInGB      = 52
      CreateOption      = "Empty"
      DeleteOption      = "Delete"
      Caching           = "ReadWrite"
      Lun               = 2
    }
  )

  foreach ($diskParams in $dataDiskParams) {
    $VirtualMachine = Add-AzVMDataDisk @diskParams
  }

  $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable
  $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $vmName -Credential $using:credential
  $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $nic.Id
  $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $using:PublisherName -Offer $using:Offer -Skus $using:Skus -Version "latest"

  $vmParams = @{
    ResourceGroupName = $using:ResourceGroupName
    Location          = $using:LocationName
    VM                = $VirtualMachine
    Verbose           = $true
  }
  New-AzVM @vmParams
}