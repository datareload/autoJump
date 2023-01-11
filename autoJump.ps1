#Builds an ISO which will automatically deploy a Windows Server VM (Tested  with 2019) or Domain Controller with CA configured with 
#   VMware Template/Webenrollment
#   IIS with Depot dirs for VCF
#   VMTools 
#   Optional:
#   Chrome - Ability to import managed bookmarks
#   OVFTool
#   PowerCLI / PowerVCF / PowerValidatedSolutions
#   Putty
#   VLC
#   Inject additional commands, hosts into the hostfile, and copy files
#Version 1.2
#Date: 11/22/2022

<#
    .SYNOPSIS
    Builds an ISO which will automatically deploy and configure a Windows server VM
    
    .DESCRIPTION
    The autojump.ps1 script Builds an ISO which will automatically deploy a Windows server VM (Tested with 2019) or domain controller with CA configured with: 
    -VMware Template/Webenrollment
    -IIS with Depot dirs for VCF
    -VMTools 
    -Optional:
    -Chrome - Ability to import managed bookmarks
    -OVFTool
    -PowerCLI / PowerVCF / PowerValidatedSolutions
    -Putty
    -VCF Lab Constructor
    -Inject additional commands, hosts into the hostfile, and copy files

    .PARAMETER compName
    Specifies the hostname given to the Windows OS when installed. The default is vcfad.
    .PARAMETER compIP
    Specifies the IP address that will be statically assigned to the VMXNET3 network interface identified as Ethernet0 in Windows.
    The default is 10.0.0.201.
    .PARAMETER compSubnet
    Specifies the subnet mask configured on the network interface identified as Ethernet0 in Windows.
    The default is 255.255.255.0.
    .PARAMETER compGw
    Specifies the gateway configured on the network interface identified as Ethernet0 in Windows.
    The default is 10.0.0.221.
    .PARAMETER compVlan
    Specifies the VLAN configured on the network interface identified as Ethernet0 in Windows.  A VLAN ID of 0 will produce untagged traffic.
    The default is 10.
    .PARAMETER compDNSFwd
    Specifies the DNS server configured on the network interface identified as Ethernet0 in Windows when the role of JUMP is specified in the isoRole parameter.  If the role of AD is specified in the isoRole parameter the compDNSFwd value will be assigned as the DNS forwarder of the Windows DNS server that is installed locally.
    The default is 10.0.0.221
    .PARAMETER adDomain
    Specifies the domain name that will be assigned to the Windows server when the role of AD is specified in the isoRole parameter.
    The default is vcf.holo.lab
    .PARAMETER adminPass
    Specifies the password for the administrator user of Windows.
    The default is VMware123!
    .PARAMETER vmToolsExeLoc
    Specifies the filesystem or network location of the VMware tools EXE file accessible from the computer executing the script.
    .PARAMETER winIsoLoc
    Specifies the filesystem or network location of the Windows 2019 ISO file accessible from the computer executing the script.
    .PARAMETER isoRole
    Specifies the role of the Windows operating system that will be installed.  The valid roles are: "AD" or "JUMP".  
    The role of JUMP will install and configure Windows, as well as any optional and/or additional applications and files.  
    The role of AD will install and configure Windows, Active Directory, DNS, Certificate Services, and IIS as well as any additional optional applications.
    .PARAMETER powerCLIZipLoc
    Specifies the filesystem or network location of the PowerCLI zip file accessible from the computer executing the script.
    .PARAMETER powerVCFZipLoc
    Specifies the filesystem or network location of the PowerVCF zip file accessible from the computer executing the script.
    .PARAMETER powerVSZipLoc
    Specifies the filesystem or network location of the PowerVaildatedSolutions zip file accessible from the computer executing the script.
    .PARAMETER ovfToolMSILoc
    Specifies the filesystem or network location of the OVFTool MSI file accessible from the computer executing the script.
    .PARAMETER puttyMSILoc
    Specifies the filesystem or network location of the Putty MSI file accessible from the computer executing the script.
    .PARAMETER chromeInstallerExeLoc
    Specifies the filesystem or network location of the Chrome offline installer EXE file accessible from the computer executing the script.
    .PARAMETER vlcZipLoc
    Specifies the filesystem or network location of the VMware Lab Constructor zip file accessible from the computer executing the script.
    .PARAMETER addHostsFile
    Specifies the filesystem or network location of the addHostsFile text file accessible from the computer executing the script.
    This file should contain a list of hosts with the format:
    IP          FQDN
    10.0.0.10   web.example.com
    .PARAMETER bookMarksFile
    Specifies the filesystem or network location of the bookmarks JSON file accessible from the computer executing the script.
    This file is for importing to Google Chrome with the format:
    [
        {"toplevel_name": "Company Links"}, 
	        {"name": "Folder 1", "children": 
		       [
		       {"name": "Website 1", "url": "https://website1.com/"}, 
		       {"name": "Website 2", "url": "https://website2.com/"}
		       ]
            },
            {"name": "Folder 2", "children": 
               [
	           {"name": "Website 7", "url": "https://website7.com/"}
               ]
            }
        }
    ]   
    .PARAMETER addCmdsFile
    Specifies the filesystem or network location of the addCmdsFile cmd file accessible from the computer executing the script.
    This file is a list of commands that are executed as a cmd file as the last operation that will be executed after the windows install.
    Any calls to files in the addFilesFile will have the path %WINDIR%\Setup\Scripts\<filename> This points to their location in the new Windows filesystem during install.
    Example cmd file:
    :: Add a *non-persistant* route

    route add 172.24.32.0 mask 255.255.255.0 10.0.0.1

    :: Install Notepad ++ using the executable installer with "Silent" switch

    %WINDIR%\Setup\Scripts\npp.8.4.7.Installer.x64.exe /S

    :: Install FireFox using the MSI installer with "quiet" switch and "no restart". 

    "%WINDIR%\Setup\Scripts\Firefox Setup 107.0.msi" /q /norestart

    :: Run a powershell script

    %WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c %WINDIR%\Setup\Scripts\setwallpaper.ps1    
    .PARAMETER addFilesFile
    Specifies the filesystem or network location of the addFilesFile text file accessible from the computer executing the script.
    This file is a list of files with their full filesystem or network location path on the computer executing the script.
    The files listed will be copied to the path %WINDIR%\Setup\Scripts\<filename> in the new Windows filesystem during install.
    Example:
    C:\Users\Administrator\Documents\autoJump\README.md
    C:\Users\Administrator\Documents\autoJump\sddccommander_vcf_wide_design.png
    .INPUTS
    None. You cannot pipe objects to autoJump.ps1.
    .OUTPUTS
    ISO File located in the script execution directory.
    .EXAMPLE 
    autoJump.ps1 @autoJumpParms
    Minimum required parameters.  This will only install Windows, install VMware Tools and configure firewall and networking in Windows
    
    Splatted:
    $autoJumpParms = @{
	winIsoLoc = "C:\Users\Administrator\Downloads\17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso"
	vmToolsExeLoc = "C:\Users\Administrator\Downloads\VMware-tools-11.3.5-18557794-x86_64.exe"
	isoRole = "JUMP"
    }
    .EXAMPLE
    autoJump.ps1 -winIsoLoc C:\Users\Administrator\Downloads\windows.iso -vmToolsExeLoc C:\Users\Administrator\Downloads\VMware-tools-11.3.5-18557794-x86_64.exe -isoRole AD
    Minimum required parameters.  This will only install Windows, install VMware Tools and configure firewall and networking in Windows

    .EXAMPLE
    autoJump.ps1 @autoJumpParms
    Install Windows, VMTools, Active Directory with DNS and Certifiacte Authority, Chrome, Import Bookmarks, OVFTools, Putty, PowerCLI, PowerVCF, PowerValidatedSolutions, VLC import files and run final commands.

    Splatted:
    $autoJumpParms = @{
	winIsoLoc = "C:\Users\Administrator\Downloads\17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso"
	vmToolsExeLoc = "C:\Users\Administrator\Downloads\VMware-tools-11.3.5-18557794-x86_64.exe"
	isoRole = "AD"
	addHostsFile = "C:\users\Administrator\Downloads\holoHosts.txt"
	addCmdsFile = "C:\users\Administrator\Documents\autoJump\additionalcommands.bat"
	addFilesFile = "C:\users\Administrator\Documents\autoJump\additionalfiles.txt"
	powerCLIZipLoc = "C:\Users\Administrator\Downloads\VMware-PowerCLI-12.6.0-19610541.zip"
	ovfToolMsiLoc = "C:\Users\Administrator\Downloads\VMware-ovftool-4.4.3-18663434-win.x86_64.msi"
	vlcZipLoc = "C:\Users\Administrator\Downloads\VLCGuiHH-1-062722.zip"
	powerVCFZipLoc = "C:\Users\Administrator\Downloads\powervcf.2.2.0.zip"
	powerVSZipLoc = "C:\users\Administrator\Downloads\powervalidatedsolutions.1.7.0.zip"
	bookMarksFile = "C:\Users\Administrator\Downloads\HOLO-bookmarks.json"
	chromeInstallerExeLoc = "C:\Users\Administrator\Downloads\ChromeStandaloneSetup64.exe"
	puttyMSILoc = "C:\users\Administrator\Downloads\putty-64bit-0.77-installer.msi"
	}
    
    .EXAMPLE
    autoJump.ps1 -chromeInstallerExeLoc C:\Users\Administrator\Downloads\ChromeStandaloneSetup64.exe -winIsoLoc C:\Users\Administrator\Downloads\17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso -vmToolsExeLoc C:\Users\Administrator\Downloads\VMware-tools-11.3.5-18557794-x86_64.exe -powerCLIZipLoc C:\Users\Administrator\Downloads\VMware-PowerCLI-12.6.0-19610541.zip -ovfToolMsiLoc C:\Users\Administrator\Downloads\VMware-ovftool-4.4.3-18663434-win.x86_64.msi -vlcZipLoc C:\Users\Administrator\Downloads\VLC_4.5-102622.zip -powerVCFZipLoc C:\Users\Administrator\Downloads\powervcf.2.2.0.zip -powerVSZipLoc C:\users\Administrator\Downloads\powervalidatedsolutions.1.7.0.zip -addHostsFile C:\users\Administrator\Downloads\holoHosts.txt -bookMarksFile C:\Users\Administrator\Downloads\HOLO-bookmarks.json -puttyMSILoc C:\users\Administrator\Downloads\putty-64bit-0.77-installer.msi -addCmdsFile C:\users\Administrator\Documents\autoJump\additionalcommands.bat -isoRole AD -addFilesFile C:\users\Administrator\Documents\autoJump\additionalfiles.txt
    Install Windows, VMTools, Active Directory with DNS and Certifiacte Authority, Chrome, OVFTools, Putty, PowerCLI, PowerVCF, PowerValidatedSolutions, import files and run final commands.


#>


Param  (
        [String]$compName = 'vcfad',
        [String]$compIP = '10.0.0.201',
        [String]$compSubnet = '255.255.255.0',
        [String]$compGw = '10.0.0.221',
        [String]$compVlan = '10',
        [String]$compDNSFwd = '10.0.0.221',
        [String]$adDomain = 'vcf.holo.lab',
        [String]$adminPass = 'VMware123!',
        #Mandatory
        [Parameter(Mandatory=$true)][ValidateScript({if(!($_ | Test-Path)){throw "File does not exist"}return $true})][System.IO.FileInfo]$vmToolsExeLoc,
        [Parameter(Mandatory=$true)][ValidateScript({if(!($_ | Test-Path)){throw "File does not exist"}return $true})][System.IO.FileInfo]$winIsoLoc,
        [Parameter(Mandatory=$true)][ValidateSet("AD","JUMP")]$isoRole,
        #Not Mandatory
        [ValidateScript({if($_ -eq $null){return $true}else{if(!($_ | Test-Path)){throw "File does not exist"}return $true}})][System.IO.FileInfo]$powerCLIZipLoc,
        [ValidateScript({if(!($_ | Test-Path)){throw "File does not exist"}return $true})][System.IO.FileInfo]$ovfToolMSILoc,
        [ValidateScript({if(!($_ | Test-Path)){throw "File does not exist"}return $true})][System.IO.FileInfo]$puttyMSILoc,
        [ValidateScript({if(!($_ | Test-Path)){throw "File does not exist"}return $true})][System.IO.FileInfo]$chromeInstallerExeLoc,
        [ValidateScript({if(!($_ | Test-Path)){throw "File does not exist"}return $true})][System.IO.FileInfo]$powerVCFZipLoc,
        [ValidateScript({if(!($_ | Test-Path)){throw "File does not exist"}return $true})][System.IO.FileInfo]$powerVSZipLoc,
        [ValidateScript({if(!($_ | Test-Path)){throw "File does not exist"}return $true})][System.IO.FileInfo]$vlcZipLoc,
        [ValidateScript({if(!($_ | Test-Path)){throw "File does not exist"}return $true})][System.IO.FileInfo]$addHostsFile,
        [ValidateScript({if(!($_ | Test-Path)){throw "File does not exist"}return $true})][System.IO.FileInfo]$bookMarksFile,
        [ValidateScript({if(!($_ | Test-Path)){throw "File does not exist"}return $true})][System.IO.FileInfo]$addCmdsFile,
        [ValidateScript({if(!($_ | Test-Path)){throw "File does not exist"}return $true})][System.IO.FileInfo]$addFilesFile
)
#Change the below product key for non eval install
$winProductKey = "6VCNF-G7MXC-YW7X8-MYRQX-2YWVQ"
$global:scriptDir = Split-Path $MyInvocation.MyCommand.Path

Function logger($strMessage, [switch]$logOnly, [switch]$consoleOnly) {
    $curDateTime = get-date -format "hh:mm:ss"
    $entry = "$curDateTime :> $strMessage"
    write-host $entry

}
function extractISO ($ISOPath) 
{

    $mount = Mount-DiskImage -ImagePath "$ISOPath" -PassThru

         if($mount) {
         
             $volume = Get-DiskImage -ImagePath $mount.ImagePath | Get-Volume
             $source = $volume.DriveLetter + ":\*"
             $folder = mkdir $scriptDir\temp\ISO -Force
         
             logger "Extracting '$ISOPath' to '$folder'..."
		 
             $params = @{Path = $source; Destination = $folder; Recurse = $true; Force = $true;}
             copy-item @params
             $hide = Dismount-DiskImage -ImagePath "$ISOPath"
             logger "Extraction complete"
        }
        else {
             logger "ERROR: Could not mount $ISOPath check if file is already in use"
             exit
        }
}
function New-IsoFile 
{  
  <# .Synopsis Creates a new .iso file .Description The New-IsoFile cmdlet creates a new .iso file containing content from chosen folders .Example New-IsoFile "c:\tools","c:Downloads\utils" This command creates a .iso file in $env:temp folder (default location) that contains c:\tools and c:\downloads\utils folders. The folders themselves are included at the root of the .iso image. .Example New-IsoFile -FromClipboard -Verbose Before executing this command, select and copy (Ctrl-C) files/folders in Explorer first. .Example dir c:\WinPE | New-IsoFile -Path c:\temp\WinPE.iso -BootFile "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\efisys.bin" -Media DVDPLUSR -Title "WinPE" This command creates a bootable .iso file containing the content from c:\WinPE folder, but the folder itself isn't included. Boot file etfsboot.com can be found in Windows ADK. Refer to IMAPI_MEDIA_PHYSICAL_TYPE enumeration for possible media types: http://msdn.microsoft.com/en-us/library/windows/desktop/aa366217(v=vs.85).aspx .Notes NAME: New-IsoFile AUTHOR: Chris Wu LASTEDIT: 03/23/2016 14:46:50 #> 
   
  [CmdletBinding(DefaultParameterSetName='Source')]Param( 
    [parameter(Position=1,Mandatory=$true,ValueFromPipeline=$true, ParameterSetName='Source')]$Source,  
    [parameter(Position=2)][string]$Path = "$env:temp\$((Get-Date).ToString('yyyyMMdd-HHmmss.ffff')).iso",  
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})][string]$BootFile = $null, 
    [ValidateSet('CDR','CDRW','DVDRAM','DVDPLUSR','DVDPLUSRW','DVDPLUSR_DUALLAYER','DVDDASHR','DVDDASHRW','DVDDASHR_DUALLAYER','DISK','DVDPLUSRW_DUALLAYER','BDR','BDRE')][string] $Media = 'DVDPLUSRW_DUALLAYER', 
    [string]$Title = (Get-Date).ToString("yyyyMMdd-HHmmss.ffff"),  
    [switch]$Force, 
    [parameter(ParameterSetName='Clipboard')][switch]$FromClipboard 
  ) 
  
  Begin {  
    ($cp = new-object System.CodeDom.Compiler.CompilerParameters).CompilerOptions = '/unsafe' 
    if (!('ISOFile' -as [type])) {  
      Add-Type -CompilerParameters $cp -TypeDefinition @'
public class ISOFile  
{ 
  public unsafe static void Create(string Path, object Stream, int BlockSize, int TotalBlocks)  
  {  
    int bytes = 0;  
    byte[] buf = new byte[BlockSize];  
    var ptr = (System.IntPtr)(&bytes);  
    var o = System.IO.File.OpenWrite(Path);  
    var i = Stream as System.Runtime.InteropServices.ComTypes.IStream;  
   
    if (o != null) { 
      while (TotalBlocks-- > 0) {  
        i.Read(buf, BlockSize, ptr); o.Write(buf, 0, bytes);  
      }  
      o.Flush(); o.Close();  
    } 
  } 
}  
'@  
    } 
   
    if ($BootFile) { 
      if('BDR','BDRE' -contains $Media) { Write-Warning "Bootable image doesn't seem to work with media type $Media" } 
      ($Stream = New-Object -ComObject ADODB.Stream -Property @{Type=1}).Open()  # adFileTypeBinary 
      $Stream.LoadFromFile((Get-Item -LiteralPath $BootFile).Fullname) 
      ($Boot = New-Object -ComObject IMAPI2FS.BootOptions).AssignBootImage($Stream) 
    } 
  
    $MediaType = @('UNKNOWN','CDROM','CDR','CDRW','DVDROM','DVDRAM','DVDPLUSR','DVDPLUSRW','DVDPLUSR_DUALLAYER','DVDDASHR','DVDDASHRW','DVDDASHR_DUALLAYER','DISK','DVDPLUSRW_DUALLAYER','HDDVDROM','HDDVDR','HDDVDRAM','BDROM','BDR','BDRE') 
  
    Write-Verbose -Message "Selected media type is $Media with value $($MediaType.IndexOf($Media))"
    ($Image = New-Object -com IMAPI2FS.MsftFileSystemImage -Property @{VolumeName=$Title}).ChooseImageDefaultsForMediaType($MediaType.IndexOf($Media)) 
   
    if (!($Target = New-Item -Path $Path -ItemType File -Force:$Force -ErrorAction SilentlyContinue)) { Write-Error -Message "Cannot create file $Path. Use -Force parameter to overwrite if the target file already exists."; break } 
  }  
  
  Process { 
    if($FromClipboard) { 
      if($PSVersionTable.PSVersion.Major -lt 5) { Write-Error -Message 'The -FromClipboard parameter is only supported on PowerShell v5 or higher'; break } 
      $Source = Get-Clipboard -Format FileDropList 
    } 
  
    foreach($item in $Source) { 
      if($item -isnot [System.IO.FileInfo] -and $item -isnot [System.IO.DirectoryInfo]) { 
        $item = Get-Item -LiteralPath $item
      } 
  
      if($item) { 
        Write-Verbose -Message "Adding item to the target image: $($item.FullName)"
        try { $Image.Root.AddTree($item.FullName, $true) } catch { Write-Error -Message ($_.Exception.Message.Trim() + ' Try a different media type.') } 
      } 
    } 
  } 
  
  End {  
    if ($Boot) { $Image.BootImageOptions=$Boot }  
    $Result = $Image.CreateResultImage()  
    [ISOFile]::Create($Target.FullName,$Result.ImageStream,$Result.BlockSize,$Result.TotalBlocks) 
    Write-Verbose -Message "Target image ($($Target.FullName)) has been created"
    logger "ISO creation Complete"
    $Target
  } 
} 
#Auto Unattend XML file, this is copied into the root of the ISO
$customUnattendXML = @"
    <?xml version="1.0" encoding="utf-8"?>
    <unattend xmlns="urn:schemas-microsoft-com:unattend">
        <settings pass="windowsPE">
            <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
                xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <DiskConfiguration>
                    <Disk wcm:action="add">
                        <CreatePartitions>
                            <CreatePartition wcm:action="add">
                                <Order>1</Order>
                                <Size>500</Size>
                                <Type>Primary</Type>
                            </CreatePartition>
                            <CreatePartition wcm:action="add">
                                <Order>2</Order>
                                <Size>100</Size>
                                <Type>EFI</Type>
                            </CreatePartition>
                            <CreatePartition wcm:action="add">
                                <Order>3</Order>
                                <Size>16</Size>
                                <Type>MSR</Type>
                            </CreatePartition>
                            <CreatePartition wcm:action="add">
                                <Order>4</Order>
                                <Extend>true</Extend>
                                <Type>Primary</Type>
                            </CreatePartition>
                        </CreatePartitions>
                        <ModifyPartitions>
                            <ModifyPartition wcm:action="add">
                                <Order>1</Order>
                                <Label>WinRE</Label>
                                <Format>NTFS</Format>
                                <PartitionID>1</PartitionID>
                            </ModifyPartition>
                            <ModifyPartition wcm:action="add">
                                <PartitionID>2</PartitionID>
                                <Order>2</Order>
                                <Format>FAT32</Format>
                                <Label>System</Label>
                            </ModifyPartition>
                            <ModifyPartition wcm:action="add">
                                <Order>3</Order>
                                <PartitionID>3</PartitionID>
                            </ModifyPartition>
                            <ModifyPartition wcm:action="add">
                                <Format>NTFS</Format>
                                <Label>Windows</Label>
                                <Letter>C</Letter>
                                <Order>4</Order>
                                <PartitionID>4</PartitionID>
                            </ModifyPartition>
                        </ModifyPartitions>
                        <WillWipeDisk>true</WillWipeDisk>
                        <DiskID>0</DiskID>
                    </Disk>
                    <WillShowUI>OnError</WillShowUI>
                </DiskConfiguration>
                <UserData>
                    <AcceptEula>true</AcceptEula>
                </UserData>
                <ImageInstall>
                    <OSImage>
                        <InstallFrom>
                            <MetaData wcm:action="add">
                                <Key>/IMAGE/INDEX</Key>
                                <Value>2</Value>
                            </MetaData>
                        </InstallFrom>
                        <InstallTo>
                            <DiskID>0</DiskID>
                            <PartitionID>4</PartitionID>
                        </InstallTo>
                    </OSImage>
                </ImageInstall>
                <EnableFirewall>false</EnableFirewall>
            </component>
            <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
                xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <SetupUILanguage>
                    <UILanguage>en-US</UILanguage>
                </SetupUILanguage>
                <InputLocale>0c09:00000409</InputLocale>
                <SystemLocale>en-US</SystemLocale>
                <UILanguage>en-US</UILanguage>
                <UILanguageFallback>en-US</UILanguageFallback>
                <UserLocale>en-US</UserLocale>
            </component>
        </settings>
        <settings pass="offlineServicing">
            <component name="Microsoft-Windows-LUA-Settings" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
                xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <EnableLUA>false</EnableLUA>
            </component>
        </settings>
        <settings pass="generalize">
            <component name="Microsoft-Windows-Security-SPP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
                xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <SkipRearm>1</SkipRearm>
            </component>
        </settings>
        <settings pass="specialize">
            <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
                xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <InputLocale>0409:00000409</InputLocale>
                <SystemLocale>en-US</SystemLocale>
                <UILanguage>en-US</UILanguage>
                <UILanguageFallback>en-US</UILanguageFallback>
                <UserLocale>en-US</UserLocale>
            </component>
            <component name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
                xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <SkipAutoActivation>true</SkipAutoActivation>
            </component>
            <component name="Microsoft-Windows-SQMApi" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
                xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <CEIPEnabled>0</CEIPEnabled>
            </component>
            <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
                xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <ComputerName>${compName}</ComputerName>
                <ProductKey>${winProductKey}</ProductKey>
            </component>
            <component name="Microsoft-Windows-ServerManager-SvrMgrNc" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
                xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <DoNotOpenServerManagerAtLogon>true</DoNotOpenServerManagerAtLogon>
            </component>
            <component name="Microsoft-Windows-TerminalServices-LocalSessionManager" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <fDenyTSConnections>false</fDenyTSConnections>
            </component>
            <component name="Microsoft-Windows-TerminalServices-RDP-WinStationExtensions" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <UserAuthentication>1</UserAuthentication>
            </component>
            <component name="Networking-MPSSVC-Svc" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <DomainProfile_EnableFirewall>false</DomainProfile_EnableFirewall>
                <PrivateProfile_EnableFirewall>false</PrivateProfile_EnableFirewall>
                <PublicProfile_EnableFirewall>false</PublicProfile_EnableFirewall>
            </component>
            <component name="Microsoft-Windows-IE-ESC" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <IEHardenAdmin>false</IEHardenAdmin>
                <IEHardenUser>false</IEHardenUser>
            </component>
            <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <RunSynchronous>
                    <RunSynchronousCommand wcm:action="add">
                        <Description>Show startup scripts</Description>
                        <Order>2</Order>
                        <Path>cmd /c  reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v HideStartupScripts /t REG_DWORD /d 0 /f</Path>
                    </RunSynchronousCommand>           
                </RunSynchronous>
            </component>            
        </settings>
        <settings pass="oobeSystem">
            <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
                xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <AutoLogon>
                    <Password>
                        <Value>${adminPass}</Value>
                        <PlainText>true</PlainText>
                    </Password>
                    <Enabled>true</Enabled>
                    <Username>administrator</Username>
                </AutoLogon>
                <OEMName>VLC</OEMName>
                <OOBE>
                    <HideEULAPage>true</HideEULAPage>
                    <HideLocalAccountScreen>true</HideLocalAccountScreen>
                    <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                    <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                    <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                    <NetworkLocation>Work</NetworkLocation>
                    <ProtectYourPC>1</ProtectYourPC>
                    <SkipMachineOOBE>true</SkipMachineOOBE>
                    <SkipUserOOBE>true</SkipUserOOBE>
                </OOBE>
                <RegisteredOrganization>Organization</RegisteredOrganization>
                <RegisteredOwner>Owner</RegisteredOwner>
                <DisableAutoDaylightTimeSet>false</DisableAutoDaylightTimeSet>
                <TimeZone>UTC</TimeZone>
                <UserAccounts>
                    <AdministratorPassword>
                        <Value>${adminPass}</Value>
                        <PlainText>true</PlainText>
                    </AdministratorPassword>
                </UserAccounts>
            </component>
        </settings>
    </unattend>
"@
#clean Temp
logger "Cleaning out Temp dir"

if("$scriptdir\temp" | Test-Path) {
    try{
    Remove-Item $scriptDir\temp -Force -Confirm:$false -Recurse -ErrorAction Stop
    }
    catch {
    logger "Problem removing files, please ensure you are using a new powershell window to run the script and that no files are open or in use."
    exit
    }
}
logger "Start extracting ISO to $scriptDir\Temp\ISO"
extractISO -ISOPath $winIsoLoc
#Setup var's and create dir's for subsequent script creation
New-Item -ItemType Directory -Path "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\"
$moduleLoc = $($env:PSModulePath -split ";")[2]
$vmToolsName = Split-Path $vmToolsExeLoc -Leaf
Copy-Item -Path $vmToolsExeLoc -Destination "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\"

$adNetBiosName = $($adDomain.Split('.')[0])

#SetupComplete.cmd file, this is copied into the ISO under .\sources\$OEM$\$$\Setup\scripts
$customSetupComplete =@"
%WINDIR%\system32\reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff" /f
%WINDIR%\system32\cmd.exe /c C:\windows\setup\scripts\${vmToolsName} /s /v "/qn REBOOT=ReallySuppress"
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c "Set-Executionpolicy bypass -Confirm:`$false -Force"
%WINDIR%\system32\netsh.exe interface ip set address name="Ethernet0" static ${compIP} ${compSubnet} ${compGw}
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c "Set-NetAdapterAdvancedProperty -Name Ethernet0 -DisplayName 'VLAN ID' -DisplayValue ${compVlan}"
"@

#if Role is AD
if ($isoRole -eq "AD") {
    $customSetupComplete = $customSetupComplete + @"
`r`n%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c Install-ADDSForest -DomainName "${adDomain}" -DomainNetBiosName "${adNetBiosName}" -InstallDNS -SafeModeAdministratorPassword "`$(ConvertTo-SecureString -String ${adminPass} -asPlainText -Force)" -Confirm:`$false -NoRebootOnCompletion
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name confCAWebEnroll -Value "C:\windows\setup\scripts\CA-WebEnroll-Setup.cmd"
"@
#if Role is Jump
} else {$customSetupComplete = $customSetupComplete + @"
`r`n%WINDIR%\system32\reg.exe add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce /v installDefaultApps /d "%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -noexit ""C:\windows\setup\scripts\extractMods.ps1""" /f
%WINDIR%\system32\netsh.exe interface ip set dns "Ethernet0" static {$compDNSFwd}
"@
}
$customSetupComplete = $customSetupComplete + @"
`r`n%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c Restart-Computer
"@
#any mods that are zipped should go here
$extractMods = @"
Add-Type -AssemblyName System.IO.Compression.FileSystem
Start-Transcript -Path "C:\autoJump.log" -Append
Get-Volume -DriveLetter D | Get-Partition | Remove-PartitionAccessPath -AccessPath "D:\"
echo "Removed Partition Access for D"
"@
if ($powerCLIZipLoc) {
    $powerCLIName = Split-Path $powerCLIZipLoc -Leaf
    Copy-Item -Path $powerCLIZipLoc -Destination "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\"
    $extractMods += @"
`r`n`$powerCLIZip = [System.IO.Compression.ZipFile]::OpenRead(`$("C:\windows\setup\scripts\${powerCLIName}"))
[System.IO.Compression.ZipFileExtensions]::ExtractToDirectory(`$powerCLIZip,`$("${moduleLoc}"))
Write-Host "Extracted ${powerCLIName}"
"@
}
if ($powerVCFZipLoc) {
    $powerVCFName = Split-Path $powerVCFZipLoc -Leaf
    Copy-Item -Path $powerVCFZipLoc -Destination "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\"
    $extractMods += @"
`r`n`$powerVCFZip = [System.IO.Compression.ZipFile]::OpenRead(`$("C:\windows\setup\scripts\${powerVCFName}"))
[System.IO.Compression.ZipFileExtensions]::ExtractToDirectory(`$powerVCFZip,`$("${moduleLoc}\PowerVCF"))
Write-Host "Extracted ${powerVCFName}"
"@
}
if ($powerVSZipLoc) {
    $powerVSName = Split-Path $powerVSZipLoc -Leaf
    Copy-Item -Path $powerVSZipLoc -Destination "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\"
    $extractMods += @"
`r`n`$powerVSZip = [System.IO.Compression.ZipFile]::OpenRead(`$("C:\windows\setup\scripts\${powerVSName}"))
[System.IO.Compression.ZipFileExtensions]::ExtractToDirectory(`$powerVSZip,`$("${moduleLoc}\PowerValidatedSolutions"))
Write-Host "Extracted ${powerVSName}"
"@
}
if($vlcZipLoc) {
    $vlcZipName = Split-Path $vlcZipLoc -Leaf
    Copy-Item -Path $vlcZipLoc -Destination "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\"
    $extractMods += @"
`r`n`$vlcZip = [System.IO.Compression.ZipFile]::OpenRead(`$("C:\windows\setup\scripts\${vlcZipName}"))
[System.IO.Compression.ZipFileExtensions]::ExtractToDirectory(`$vlcZip,`$("c:\VLC"))
Write-Host "Extracted ${vlcZipName}"
"@
}
if($addHostsFile) {
    $addHostsName = Split-Path $addHostsFile -Leaf
    Copy-Item -Path $addHostsFile -Destination "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\"
    $extractMods += @"
`r`nAdd-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value `$(Get-Content -Path "C:\windows\setup\scripts\${addHostsName}")
Write-Host "Appended ${addHostsName} to hosts file"
"@
}
if ($addFilesFile) {
    $filestoCopy = Get-Content $addFilesFile
    foreach ($copyFile in $filestoCopy) {
        if ($copyFile -ne "") {
            If (($copyFile | Test-Path)) {
                Copy-Item -Path $copyFile -Destination "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\"
            }
        }
    }
}
$extractMods += @"
`r`nSet-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name installApps -Value "C:\windows\setup\scripts\InstallDefaultApps.cmd"
Restart-Computer
"@

#any apps that have exe or msi should go here
$installDefaultApps = "echo Installing apps"
if ($ovfToolMSILoc) {
    $ovfToolName = Split-Path $ovfToolMsiLoc -Leaf
    Copy-Item -Path $ovfToolMsiLoc -Destination "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\"
    $installDefaultApps += @"
`r`nc:\Windows\system32\cmd.exe /c "C:\Windows\System32\msiexec.exe /i C:\windows\setup\scripts\${ovfToolName} /qn /norestart"
echo "Installed ${ovfToolName}"
"@
}
if ($puttyMSILoc) {
    $puttyFileName = Split-Path $puttyMsiLoc -Leaf
    Copy-Item -Path $puttyMsiLoc -Destination "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\"
    $installDefaultApps += @"
`r`nc:\Windows\system32\cmd.exe /c "C:\Windows\System32\msiexec.exe /i C:\windows\setup\scripts\${puttyFileName} /qn /norestart"
echo "Installed ${puttyFileName}"
"@ 
}
if ($chromeInstallerExeLoc) {
    $chromeName = Split-Path $chromeInstallerExeLoc -Leaf
    Copy-Item -Path $chromeInstallerExeLoc -Destination "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\"
    $installDefaultApps += @"
`r`nC:\Windows\system32\cmd.exe /c "C:\windows\setup\scripts\${chromeName} /silent /install"
echo "Installed ${chromeName}"
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c "C:\windows\setup\scripts\browserSettings.ps1"
echo "Set browserSettings"
"@
    if($bookMarksFile) {
        $importBookMarks = Get-Content -Path $bookMarksFile
    }
    if($addCmdsFile) {
        $addCmdsName = Split-Path $addCmdsFile -Leaf
        Copy-Item -Path $addCmdsFile -Destination "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\"
        $installDefaultApps += @"
`r`n%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name addCmds -Value "C:\windows\setup\scripts\$addCmdsName"
echo "Added ${addCmdsName} to runonce"
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c Restart-Computer
"@
    }
} else {
    if($addCmdsFile) {
        $addCmdsName = Split-Path $addCmdsFile -Leaf
        Copy-Item -Path $addCmdsFile -Destination "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\"
        $installDefaultApps += @"
`r`n%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name addCmds -Value "C:\windows\setup\scripts\$addCmdsName"
echo "Added ${addCmdsName} to runonce"
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c Restart-Computer
"@
    }
}

#CA-Web-enroll.cmd file, this is copied into the ISO under .\sources\$OEM$\$$\Setup\scripts
$cawebenrollsetup = @"
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c Set-DNSServerForwarder "${compDNSFwd}" -Passthru
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c Install-WindowsFeature -Name adcs-cert-authority,adcs-web-enrollment -IncludeAllSubFeature -IncludeManagementTools
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c Install-AdcsCertificationAuthority -CAType EnterpriseRootCA -Confirm:`$false
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c Install-AdcsWebEnrollment -Confirm:`$false
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c Install-WindowsFeature -Name web-basic-auth
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c "Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/windowsAuthentication' -Name 'enabled' -Value 'false' -PSPath 'IIS:\' -Location 'Default Web Site/CertSrv'"
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c "Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/basicAuthentication' -Name 'enabled' -Value 'true' -PSPath 'IIS:\' -Location 'Default Web Site/CertSrv'"
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c mkdir C:\inetpub\wwwroot\PROD2\evo\vmw\bundles -Force
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c mkdir C:\inetpub\wwwroot\PROD2\evo\vmw\manifests -Force
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name finalCert -Value "C:\windows\setup\scripts\iisCertset.cmd"
"@
$cawebenrollsetup = $cawebenrollsetup + @"
`r`n%WINDIR%\system32\certutil -dsaddtemplate c:\windows\setup\scripts\VMwareCertTempl.txt
%WINDIR%\system32\certutil -setCAtemplates +"VMware"
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c Restart-Computer
"@

#VMware Certificate Template txt file, this is copied into the ISO under .\sources\$OEM$\$$\Setup\scripts
$certDCSplit = $adDomain.Split(".")
$vmwareCertTempl =@"
[Version]
Signature = "$Windows NT$"


[VMware]
    objectClass = "top", "pKICertificateTemplate"
    cn = "VMware"
    distinguishedName = "CN=VMware,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=$($certDCSplit[$($certDCSplit.Count - 2)]),DC=$($certDCSplit[$($certDCSplit.Count - 1)])"
    instanceType = "4"
    displayName = "VMware"
    showInAdvancedViewOnly = "TRUE"
    nTSecurityDescriptor = "D:PAI(OA;;RPWPCR;0e10c968-78fb-11d2-90d4-00c04f79dc55;;DA)(OA;;RPWPCR;0e10c968-78fb-11d2-90d4-00c04f79dc55;;S-1-5-21-3624711327-1928871231-2040357511-519)(A;;CCDCLCSWRPWPDTLOSDRCWDWO;;;DA)(A;;CCDCLCSWRPWPDTLOSDRCWDWO;;;S-1-5-21-3624711327-1928871231-2040357511-519)(A;;CCDCLCSWRPWPDTLOSDRCWDWO;;;LA)(A;;LCRPLORC;;;AU)"
    name = "VMware"
    flags = "131649"
    revision = "100"
    objectCategory = "CN=PKI-Certificate-Template,CN=Schema,CN=Configuration,DC=$($certDCSplit[$($certDCSplit.Count - 2)]),DC=$($certDCSplit[$($certDCSplit.Count - 1)])"
    pKIDefaultKeySpec = "1"
    pKIKeyUsage = "e0"
    pKIMaxIssuingDepth = "0"
    pKICriticalExtensions = "2.5.29.15"
    pKIExpirationPeriod =  "2 Years"
    pKIOverlapPeriod =  "6 Weeks"
    pKIDefaultCSPs = "2,Microsoft DH SChannel Cryptographic Provider", "1,Microsoft RSA SChannel Cryptographic Provider"
    dSCorePropagationData = "16010101000000.0Z"
    msPKI-RA-Signature = "0"
    msPKI-Enrollment-Flag = "32768"
    msPKI-Private-Key-Flag = "50593792"
    msPKI-Certificate-Name-Flag = "1"
    msPKI-Minimal-Key-Size = "2048"
    msPKI-Template-Schema-Version = "2"
    msPKI-Template-Minor-Revision = "3"
    msPKI-Cert-Template-OID = "1.3.6.1.4.1.311.21.8.113749.13915579.3820940.12247198.16264753.177.7964721.11618799"

[TemplateList]
    Template = "VMware"
"@
#File Associations mainly for making Chrome Default Browser
$newAssociation=@"
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
  <Association Identifier=".htm" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier=".html" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier="http" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier="https" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
</DefaultAssociations>
"@
$iisCertset = @"
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c "do {write-host 'Checking for Cert to be created';timeout /nobreak 10} until (`$(get-childitem -Path Cert:\LocalMachine\My | Where-object {`$_.Subject -match '${adDomain}'}))"
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c "New-IISSiteBinding -Name 'Default Web Site' -BindingInformation '*:443:' -CertificateThumbPrint `$(`$(Get-ChildItem -Path Cert:\LocalMachine\My | Where-object {`$_.Subject -match '${adDomain}'})).Thumbprint -CertStoreLocation 'Cert:\LocalMachine\my' -Protocol https"
%WINDIR%\system32\reg.exe add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce /v installDefaultApps /d "%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -noexit ""C:\windows\setup\scripts\extractMods.ps1"""
%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c Restart-Computer
"@
#Make chrome default browser, remove IE taskbar icon, remove WINRE drive
$browserSettings=@"
Function Set-ChromeDefault{

    `$attempts = 1
    while (`$attempts -lt 5){
        try {
                `$domainDN = Get-ADDomain | Select -ExpandProperty distinguishedName
                `$attempts = 5
        } catch {
                `$attempts++
                Write-Host "Failed to get DN, waiting 5 seconds and trying again up to 5 times: Attempt #`$attempts"
                sleep 5
        }
    }
    New-GPO -Name "VLCSettings" -Domain ${adDomain} | New-GPLink -Target `$domainDN -LinkEnabled Yes -Enforced Yes
    `$assocKey = "HKLM\Software\Policies\Microsoft\Windows\System"
    Set-GPRegistryValue -Name "VLCSettings" -Key `$assocKey -ValueName "DefaultAssociationsConfiguration" -Value "c:\windows\Setup\Scripts\defaultAssociations.xml" -Type String

}
`$iepath = "$Home\Desktop"
`$WshShell = New-Object -comObject WScript.Shell
`$Shortcut = `$WshShell.CreateShortcut("`$iepath\Internet Explorer.lnk")
`$Shortcut.TargetPath = "C:\Program Files\Internet Explorer\iexplore.exe"
`$Shortcut.Save()
(New-Object -ComObject shell.application).Namespace(`$iepath).parsename('Internet Explorer.lnk').verbs() | ?{`$_.Name.replace('&','') -match 'Unpin from taskbar'} | %{`$_.DoIt(); `$exec = `$true}
Remove-Item -Path "`$iepath\Internet Explorer.lnk" -Force
`$puttyPath = "$Home\Desktop"
`$WshShell = New-Object -comObject WScript.Shell
`$Shortcut = `$WshShell.CreateShortcut("`$puttyPath\Putty.lnk")
`$Shortcut.TargetPath = "C:\Program Files\PuTTY\putty.exe"
`$Shortcut.Save()
(New-Object -ComObject shell.application).Namespace(`$puttyPath).parsename('Putty.lnk').verbs() | ?{`$_.Name.replace('&','') -match 'Unpin from taskbar'} | %{`$_.DoIt(); `$exec = `$true}
New-Item -Path "HKLM:\Software\Policies\Google\Chrome" -Force
New-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "BrowserSignin" -Value 0 -PropertyType DWord
New-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "BuiltInDnsClientEnabled" -Value 0 -PropertyType DWord
New-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "PromotionalTabsEnabled" -Value 0 -PropertyType DWord
New-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "HomepageLocation" -Value "chrome://newtab" -PropertyType String
New-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "ManagedBookmarks" -Value '${importBookMarks}' -PropertyType String
New-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "BookmarkBarEnabled" -Value "0x00000001" -PropertyType DWord
New-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "ShowAppsShortcutInBookmarkBar" -Value "0x00000000" -PropertyType DWord
Set-ChromeDefault
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name addCmds -Value "C:\windows\setup\scripts\$addCmdsName"
Write-Host "Added ${addCmdsName} to runonce"
Restart-Computer
"@
#IIS Certificate Set file, this is copied into the ISO under .\sources\$OEM$\$$\Setup\scripts

logger "Customize and move files to appropriate locations"

$customUnattendXML | Out-File -FilePath "$scriptDir\Temp\ISO\Autounattend.xml"
$customSetupComplete | Out-File (New-Item -Path "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\SetupComplete.cmd" -Force) -Encoding ASCII
$cawebenrollsetup | Out-File (New-Item -Path "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\CA-WebEnroll-Setup.cmd" -Force) -Encoding ASCII
$vmwareCertTempl | Out-File (New-Item -Path "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\VMwareCertTempl.txt" -Force) -Encoding ASCII
$installDefaultApps | Out-File (New-Item -Path "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\InstallDefaultApps.cmd" -Force) -Encoding ASCII
$extractMods | Out-File (New-Item -Path "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\extractMods.ps1" -Force) -Encoding ASCII
$browserSettings | Out-File (New-Item -Path "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\browserSettings.ps1" -Force) -Encoding ASCII
$iisCertset | Out-File (New-Item -Path "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\iisCertset.cmd" -Force) -Encoding ASCII
$newAssociation | Out-File (New-Item -Path "$scriptDir\Temp\ISO\sources\`$OEM`$\`$`$\Setup\Scripts\defaultAssociations.xml" -Force) -Encoding ASCII

logger "Create custom ISO"

Get-ChildItem "$scriptDir\Temp\ISO" | New-IsoFile -Path $scriptDir\CustomWindows-$(get-date -format hhmmss).iso -BootFile "$scriptDir\temp\ISO\efi\microsoft\boot\efisys_noprompt.bin" -Force
Exit-PSSession
