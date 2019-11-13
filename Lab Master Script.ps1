#TMF01 - Workshop Upgrading and Migrating to Server 2019

#region - Exercise 1.1

repadmin /replsum /bysrc /bydest /sort:delta >c:\repltest.txt

dcdiag.exe /e /test:frssysvol >c:\frstest.txt

dcdiag /test:fsmocheck >c:\fsmocheck.txt

repadmin /SHOWREPS TMDC01 >c:\Showreps 
repadmin /SHOWREPS TMDC02 >>c:\Showreps 



#endregion


#region - Exercise 1.2

#Upgrade FRS to DFSR for Sysvol
# https://blogs.technet.microsoft.com/askds/2010/04/22/the-case-for-migrating-sysvol-to-dfsr/

Dcdiag /e /test:sysvolcheck /test:advertising >c:\sysvolcheck.txt
Dfsrmig /setglobalstate 1
Dfsrmig /getmigrationstate 
Dfsrmig /setglobalstate 3

#endregion

#region - Exercise 1.3
#Run and Verify ADPREP

netdom query fsmo
repadmin /options TMDC01 +DISABLE_OUTBOUND_REPL
adprep.exe /forestprep
adprep.exe /domainprep
adprep.exe /gpprep /domainprep
#C:\Windows\debug\adprep\logs\” Current Date and Time” and open ADPrep.log

#Verify Schema and Domain Version of 16 and 
repadmin /options TMDC01 -DISABLE_OUTBOUND_REPL

repadmin /syncall /e /d /a >c:\postrootschema-repl-Pull.txt
repadmin /syncall /e /d /a /P >c:\postrootschema-repl-Push.txt

#endregion


#region - Exercise 1.4
#Install Active Directory on TMDC03
Install-WindowsFeature AD-Domain-Services
Import-Module ADDSDeployment
Test-ADDSDomainControllerInstallation -DomainName Techmentor.com
Install-ADDSDomainController -CreateDnsDelegation:$false -InstallDns:$true -DatabasePath 'C:\Windows\NTDS' -DomainName 'Techmentor.com'
repadmin /kcc
ipconfig /registerdns
Net Stop netlogon & Net Start netlogon
repadmin /syncall /e /d /a 
repadmin /syncall /e /d /a /P 

#Troubleshooting AD Replication

#Go back to TMDC01 - 
repadmin /kcc
repadmin /syncall /e 
repadmin /syncall /e /P 

#Go back to TMDC03 - Should work now
repadmin /kcc
repadmin /syncall /e 
repadmin /syncall /e /P 

#endregion

#region Exercise 1.5
#Transfer FSMO Roles with Powershell
Get-ADForest Techmentor.com | Select SchemaMaster,DomainNamingMaster
Get-ADDomain Techmentor.com | Select RIDMaster,InfrastructureMaster,PDCEmulator
Netdom Query FSMO
Move-ADDirectoryServerOperationMasterRole -identity TMDC03 -OperationMasterRole PDCEmulator,RIDMaster,InfrastructureMaster,SchemaMaster,DomainNamingMaster
Netdom Query FSMO


#endregion

#region - Exercise 1.6
#Install Active Directory on TMDC04

#Don't forget to add TMDC04 to the domain.  It was added late as a domain controller

Install-WindowsFeature AD-Domain-Services
Import-Module ADDSDeployment
Test-ADDSDomainControllerInstallation -DomainName Techmentor.com
Install-ADDSDomainController -CreateDnsDelegation:$false -InstallDns:$true -DatabasePath 'C:\Windows\NTDS' -DomainName 'Techmentor.com'
repadmin /kcc
ipconfig /registerdns
Net Stop netlogon & Net Start netlogon
repadmin /syncall /e /d /a 
repadmin /syncall /e /d /a /P 

#Troubleshooting AD Replication

#Go back to TMDC01 - 
repadmin /kcc
repadmin /syncall /e 
repadmin /syncall /e /P 

#Go back to TMDC03 - Should work now
repadmin /kcc
repadmin /syncall /e 
repadmin /syncall /e /P 

#endregion



#region - Exercise 1.7
#Tune SRV Records Prior to Decomissioning Domain Controllers

#Add Registry Keys on the old domain controllers
#HKLM\System\CurrentControlSet\Services\Netlogon\Parameters
#Add Reg Dword - LdapSrvPriority
#Value 10

Net Stop Netlogon & Net Start Netlogon

Repadmin /syncall
Repadmin /syncall /e /P 

#Review DNS Service Records for Techmentor.com

#endregion


#region - Exercise 1.10
#Manual Configuration of NTP Settings to an External Time Source
w32tm.exe /config /manualpeerlist:"0.pool.ntp.org,0x8 1.pool.ntp.org,0x8 2.pool.ntp.org,0x8" /syncfromflags:manual /update
w32tm /config /reliable:yes
net stop w32time && net start w32time
w32tm /resync


#Create a new GPO for PDC Time External

w32tm /config /syncfromflags:domhier /update
net stop w32time && net start w32time
w32tm /query /peers
net stop w32time
w32tm /unregister
w32tm /register
net start w32time
gpupdate /force 
gpresult /z
w32tm /query /peers 


#Move FSMO Roles to DC04
netdom query fsmo
Move-ADDirectoryServerOperationMasterRole -identity TMDC04 -OperationMasterRole PDCEmulator,RIDMaster,InfrastructureMaster,SchemaMaster,DomainNamingMaster
netdom query fsmo
gpupdate /force
gpresult /z 
w32tm /query /peers 



#logon to 

#endregion

#region Exercise 1.15
#Using PowerShell to update for Forest Functional Level to Server 2019
#https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/active-directory-functional-levels
#There are no new functional Levels for Server 2019 --> 2016 is the highest
Get-ADDomain | select domainMode, DistinguishedName 
Get-ADForest | select forestMode


Get-ADDomain –identity techmentor.com


#Run against the PDC Eumulator
$pdc = Get-ADDomainController -Discover -Service PrimaryDC
Set-ADDomainMode -Identity $pdc.Domain -Server $pdc.HostName[0] -DomainMode Windows2016Domain

#Update the Forest Funcitonal Level


$pdc = Get-ADDomainController -Discover -Service PrimaryDC
Set-ADForestMode -Identity $pdc.Domain -Server $pdc.HostName[0] -Forest Windows2016Forest

Get-ADDomain | select domainMode, DistinguishedName 
Get-ADForest | select forestMode

#endregion



#region Exercise 2.1
#Migrate DHCP
#Logon to TMDHCP02
Add-WindowsFeature DHCP -IncludeMangementTools
#Goto the lab manual for steps


#endregion

#region Exercise 2.2
#Export DHCP via PowerShell
Export-DHCPServer -File c:\Post-Install\DHCPDB.xml -leases -force -computername DHCP01 -verbose
Add-WindowsFeature -Name DHCP -IncludeManagementTools
Import-DHCPServer -file c:\Post-Install\DHCPDB.XML -backuppath c:\post-install -leases -scopeoverwrite -force -computername DHCP02 -verbose

#endregion

#region Exercise 3.1

#Activation of TMWAC01
DISM /Online /Set-Edition:ServerStandard /ProductKey:<InsertProductKEY> /AcceptEula

#endregion


#region exercise 3.2



#endregion


#region exercise 4.1

Invoke-WebRequest -Uri " https://raw.githubusercontent.com/dkawula/Migrating-to-Server-2019-Active-Directory/master/DNSFunctions.ps1" -OutFile "C:\Post-Install\DNSFunctions.ps1"

Import-Module c:\post-install\DNSFunctions.ps1

Backup-DNSServerZoneAll -computername TMDC01

Export-DNSServerIPConfiguration -Domain techmentor.com

Export-DNSServerZoneReport -Domain Techmentor.com

Add-DNSServerPrimaryZone -Name “Dave.com” -zonefile “Dave.com.dns” -verbose

Copy-DNSServerZOne -srcserver TMDC01 -SrcZone Dave.com -DestServer TMDC03 -DestZone Dave.com -StaleDays 25


#endregion

#region exercise 4.2


Add-DNSServerPrimaryZone -networkid 172.16.100.0/24 -zonefile "100.16.172.in-addr.arpa.dns"

DNSServerPrimaryZone -networkid 172.16.101.0/24 -zonefile "101.16.172.in-addr.arpa.dns"

#endregion


#region exercise 5.1

Invoke-WebRequest -Uri " https://raw.githubusercontent.com/dkawula/Migrating-to-Server-2019-Active-Directory/master/Chapter_15_Sample_WordPressSite_WithMySQL_Install.ps1" -OutFile "C:\Post-Install\Install-WordPress.ps1"

#endregion


#region 5.2

  $w3wpPath = $Env:WinDir + "\System32\inetsrv\w3wp.exe" 
    If(Test-Path $w3wpPath) { 
        $productProperty = Get-ItemProperty -Path $w3wpPath 
        Write-Host $productProperty.VersionInfo.ProductVersion 
    } 
    Else { 
        Write-Host "Not find IIS." 
    }   



#endregion

#region Exercise 6.1

#SCript to force logoff of RDSH Users with a GUI
#Setup script variables 
https://gallery.technet.microsoft.com/scriptcenter/Remotely-log-users-off-377c848d

$script:x =@() 
$ConnectionBroker = "Connection Broker FQDN Goes Here" 
$SessionHostCollection = "Session Host collection name goes here" 
 
#Imports the modules 
Import-Module RemoteDesktop 
 
#Runs the script 
SetupForm  
 
Function SetupForm { 
    #Setup the form 
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")  
 
    $objForm = New-Object System.Windows.Forms.Form  
    $objForm.Text = "Select user(s)" 
    $objForm.Size = New-Object System.Drawing.Size(300,320)  
    $objForm.StartPosition = "CenterScreen" 
 
    $LogOffButton = New-Object System.Windows.Forms.Button 
    $LogOffButton.Location = New-Object System.Drawing.Size(120,240) 
    $LogOffButton.Size = New-Object System.Drawing.Size(75,23) 
    $LogOffButton.Text = "Apply" 
    $objForm.Controls.Add($LogOffButton) 
     
    #When a user clicks the log off button get the details of the logged in users and call the scriptactions function 
    $LogOffButton.Add_Click( 
       { 
            foreach ($objItem in $objListbox.SelectedItems) 
               {$script:x += $objItem} 
            $MessageText = $objMessageTextBox.Text 
            $WaitTime = $objWaitforText.Text 
            ScriptActions  
            $objForm.Close() 
                 
         }) 
 
    $CancelButton = New-Object System.Windows.Forms.Button 
    $CancelButton.Location = New-Object System.Drawing.Size(200,240) 
    $CancelButton.Size = New-Object System.Drawing.Size(75,23) 
    $CancelButton.Text = "Cancel" 
    $CancelButton.Add_Click({$objForm.Close()}) 
    $objForm.Controls.Add($CancelButton) 
 
    $objLabel = New-Object System.Windows.Forms.Label 
    $objLabel.Location = New-Object System.Drawing.Size(10,20)  
    $objLabel.Size = New-Object System.Drawing.Size(280,20)  
    $objLabel.Text = "Please select user(s):" 
    $objForm.Controls.Add($objLabel)  
 
    $objListBox = New-Object System.Windows.Forms.ListBox  
    $objListBox.Location = New-Object System.Drawing.Size(10,40)  
    $objListBox.Size = New-Object System.Drawing.Size(260,20)  
    $objListBox.Height = 80 
    $objListBox.SelectionMode = "MultiExtended" 
 
    $objLabelMessage = New-Object System.Windows.Forms.Label 
    $objLabelMessage.Location = New-Object System.Drawing.Size(10,115)  
    $objLabelMessage.Size = New-Object System.Drawing.Size(280,20)  
    $objLabelMessage.Text = "Message to send to user(s):" 
    $objForm.Controls.Add($objLabelMessage)  
 
    $objMessageTextBox = New-Object System.Windows.Forms.TextBox 
    $objMessageTextBox.Location = New-Object System.Drawing.Size(10,135)  
    $objMessageTextBox.Size = New-Object System.Drawing.Size(260,20)  
    $objForm.Controls.Add($objMessageTextBox)  
     
    $objLabelTime = New-Object System.Windows.Forms.Label 
    $objLabelTime.Location = New-Object System.Drawing.Size(10,160)  
    $objLabelTime.Size = New-Object System.Drawing.Size(280,20)  
    $objLabelTime.Text = "Time in sec before logging user off" 
    $objForm.Controls.Add($objLabelTime) 
 
    $objWaitforText = New-Object System.Windows.Forms.TextBox 
    $objWaitforText.Location = New-Object System.Drawing.Size(10,180)  
    $objWaitforText.Size = New-Object System.Drawing.Size(70,20)  
    $objForm.Controls.Add($objWaitforText)  
 
    $objCheckSendMessage = New-Object System.Windows.Forms.CheckBox  
    $objCheckSendMessage.Location = New-Object System.Drawing.Size(10,200)  
    $objCheckSendMessage.Size = New-Object System.Drawing.Size(100,30) 
    $objCheckSendMessage.Text = "Send Message" 
    $objForm.Controls.Add($objCheckSendMessage)  
 
    $objCheckLogOff = New-Object System.Windows.Forms.CheckBox  
    $objCheckLogOff.Location = New-Object System.Drawing.Size(120,200)  
    $objCheckLogOff.Size = New-Object System.Drawing.Size(100,30) 
    $objCheckLogOff.Text = "Log Off" 
    $objForm.Controls.Add($objCheckLogOff)  
 
#Find logged in users and display them in the form  
    $loggedonusers = Get-RDUserSession -ConnectionBroker "$connectionBroker" -CollectionName "$SessionHostCollection" 
    ForEach ($user in $loggedonusers) { 
    [void] $objListBox.Items.Add($user.username) 
    } 
      
    $objForm.Controls.Add($objListBox)  
 
    $objForm.Topmost = $True 
 
    $objForm.Add_Shown({$objForm.Activate()}) 
    [void] $objForm.ShowDialog() 
} 
 
Function SendMessage { 
#This is the function to send a message to the user - it is called during the script operation depending on user selected options 
 
    ForEach ($x in $objListBox.SelectedItems) { 
        $UserSession = Get-RDUserSession -ConnectionBroker "$ConnectionBroker" -CollectionName "$sessionhostcollection" | Where-Object {$_.username -eq $x} 
        Send-RDUserMessage -HostServer $UserSession.HostServer -UnifiedSessionID $UserSession.UnifiedSessionID -MessageTitle "Message from IT" -MessageBody "$MessageText" 
    } 
} 
 
Function LogOff { 
#This is the function used to log users off the remote desktop farm - it is called during the script operation depending on user selected options 
    ForEach ($x in $objListBox.SelectedItems) { 
        $UserSession = Get-RDUserSession -ConnectionBroker "$connectionbroker" -CollectionName "$sessionhostcollection" | Where-Object {$_.username -eq $x} 
        Invoke-RDUserLogoff  -HostServer $UserSession.HostServer -UnifiedSessionID $UserSession.UnifiedSessionID -Force 
    } 
} 
 
Function ScriptActions { 
#This function contains the actions to take depending on the selections set by the user 
 
#If the Send Message check box is checked call the SendMessage function 
    If($objCheckSendMessage.Checked -eq $true) { 
        SendMessage 
        } 
         
#If the check log off check box is checked call the logoff function         
    If($objCheckLogOff.Checked -eq $true) { 
        #Waits for the specified number of seconds defined by the user running the script before calling the logoff function 
        Start-Sleep -Seconds $waittime 
        LogOff 
        } 
}

#END Script


#Script to Disable new connections to the RDSH Farm
foreach 
      ($HostToEnable in 
      (get-rdsessionhost -collectionname QuickSessionCollection |
       where {$_.NewConnectionAllowed -like "No"}
      )
      )
{
$HostToEnable
set-RDSessionHost $HostToEnable.SessionHost -NewConnectionAllowed "No"
}


#Script to Reenable connectivity to the RDSH Farm

#Script to Disable new connections to the RDSH Farm
foreach 
      ($HostToEnable in 
      (get-rdsessionhost -collectionname QuickSessionCollection |
       where {$_.NewConnectionAllowed -like "Yes"}
      )
      )
{
$HostToEnable
set-RDSessionHost $HostToEnable.SessionHost -NewConnectionAllowed "Yes"
}



#endregion

#region Exercise 7.1
#Populate the source print server with printers.

#Run this on TMPrint01

$port = [wmiclass]"Win32_TcpIpPrinterPort"
$newPort = $port.CreateInstance()
$newPort.name = "IP_192.168.1.21"
$newPort.Protocol = 1
$newPort.HostAddress = "192.168.1.21"
$newPort.PortNumber = "9100"
$newPort.Put()





$wmiPrinter = [wmiclass]"Win32_Printer"
$newPrinter = $wmiPrinter.CreateInstance()
$newPrinter.DriverName = "HP LaserJet 4100 Series PCL6"
$newPrinter.PortName = "IP_192.168.1.21"
$newPrinter.DeviceID = "Accounting_Printer"
$newPrinter.Put()


$port = [wmiclass]"Win32_TcpIpPrinterPort"
$newPort = $port.CreateInstance()
$newPort.name = "IP_192.168.1.22"
$newPort.Protocol = 1
$newPort.HostAddress = "192.168.1.22"
$newPort.PortNumber = "9100"
$newPort.Put()




$wmiPrinter = [wmiclass]"Win32_Printer"
$newPrinter = $wmiPrinter.CreateInstance()
$newPrinter.DriverName = "HP LaserJet 4100 Series PCL6"
$newPrinter.PortName = "IP_192.168.1.22"
$newPrinter.DeviceID = "Sales_Printer"
$newPrinter.Put()


$port = [wmiclass]"Win32_TcpIpPrinterPort"
$newPort = $port.CreateInstance()
$newPort.name = "IP_192.168.1.23"
$newPort.Protocol = 1
$newPort.HostAddress = "192.168.1.23"
$newPort.PortNumber = "9100"
$newPort.Put()





$wmiPrinter = [wmiclass]"Win32_Printer"
$newPrinter = $wmiPrinter.CreateInstance()
$newPrinter.DriverName = "HP LaserJet 4100 Series PCL6"
$newPrinter.PortName = "IP_192.168.1.23"
$newPrinter.DeviceID = "IT_Printer"
$newPrinter.Put()

#Open Printer Management and Share the Printers and then Create a GPO that deploys them

#Deploy the Printers Per User to the Drive Mappings GPO

#Test the printer drive mapping script by logging into another VM and running GPUpdate /force

#Make sure to turn the Windows Firewall back on to share the printer
#https://support.microsoft.com/en-us/help/2123653/error-0x000006d9-when-you-try-to-share-a-printer-on-a-computer-that-is

#endregion

