$VMName = TMS2D1
$GuestOSName = TMS2D1
$VMPath = "E:\DCBuild_TMOrlando2019\VHDs"
$DomainCred = Get-Credential

Invoke-Command -VMName $VMNamne { 


  Get-VM | Stop-VM $VMName -Force
  1..16 | ForEach-Object { New-VHD -Path "$($VMPath)\$($GuestOSName) - Data $_.vhdx" -Dynamic -SizeBytes 10000GB }
  1..16 | ForEach-Object { Add-VMHardDiskDrive -VMName $VMName -Path "$($VMPath)\$($GuestOSName) - Data $_.vhdx" -ControllerType SCSI}
  Set-VMProcessor -VMName $VMName -Count 2 -ExposeVirtualizationExtensions $True
  Get-VMNetworkAdapter -VMName $VMName | Set-VMNetworkAdapter -AllowTeaming On
  Get-VMNetworkAdapter -VMName $VMName | Set-VMNetworkAdapter -MacAddressSpoofing on
  Start-VM $VMName
  
  Write-Output -InputObject "[$($VMName)]:: Installing Clustering"
  $null = Install-WindowsFeature -Name File-Services, Failover-Clustering, Hyper-V, FS-Data-Deduplication -IncludeManagementTools
    
  }