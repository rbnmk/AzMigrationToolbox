#Resource Group
$locationName = "westeurope"
$ResourceGroupName = "rg1"

#Virtual Network
$networkName = "vm1-vnet"
$vnet = Get-AzVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName

#Virtual Machines
$vmCount = 4
$publisherName = "MicrosoftWindowsServer"
$offer = "WindowsServer"
$skus = "2022-datacenter-azure-edition-hotpatch"

$credential = Get-Credential

1..$vmCount | ForEach-Object -ThrottleLimit 10 -Parallel {
  #Action that will run in Parallel. Reference the current object via $PSItem and bring in outside variables with $USING:varna{

    $vmName = ("vm{0}" -f $_)
    $vmSize = "Standard_D2s_v3"

    $nic = New-AzNetworkInterface -Name "nic$vmName" -ResourceGroupName $using:ResourceGroupName -Location $using:LocationName -SubnetId $using:vnet.Subnets[0].Id -Force
    $VirtualMachine = New-AzVMConfig -VMName $vmName -VMSize $VMSize
    $VirtualMachine = Add-AzVMDataDisk -Name "dd$vmName" -VM $VirtualMachine -StorageAccountType "Standard_LRS" -DiskSizeInGB 25 -CreateOption Empty -DeleteOption Delete -Caching ReadWrite -Lun 0 
    $VirtualMachine = Add-AzVMDataDisk -Name "dd2$vmName" -VM $VirtualMachine -StorageAccountType "StandardSSD_LRS" -DiskSizeInGB 25 -CreateOption Empty -DeleteOption Delete -Caching ReadOnly -Lun 1
    $VirtualMachine = Add-AzVMDataDisk -Name "dd3$vmName" -VM $VirtualMachine -StorageAccountType "Standard_LRS" -DiskSizeInGB 52 -CreateOption Empty -DeleteOption Delete -Caching ReadWrite -Lun 2 
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $vmName -Credential $using:credential
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $nic.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $using:publisherName -Offer $using:offer -Skus $using:skus -Version latest

    New-AzVM -ResourceGroupName $using:ResourceGroupName -Location $using:LocationName -VM $VirtualMachine -Verbose
}