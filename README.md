Auto Jump 
-Windows ISO Builder script

This script will build a customized "Windows Server 2019-Desktop Experience" ISO ready to be attached to a VMware vSphere VM.  There are optional applications and powershell modules that can be installed. 
You can also embed files in the generated ISO and run a CMD file as the final Windows install step to provide further extensibility.  Examples of these files are included with sample code for adding a route, 
installing additonal applications from EXE and MSI, and setting the desktop wallpaper using a PS1 and PNG image. 

Note: You must specify a static IP, and you must ensure that there is no IP Conflict.
 
The autoJump Script will complete the configuration and installation of the following:

-Windows 2019
 -as either a simple Windows server or with Active Directory, DNS Server, Certificate Services and Web enrollment, and the VMware Certificate Template
-VMTools
-IP/Subnet/GW/VLAN
-Disables Firewall and IE Enhanced Security
-Enables remote desktop connectivity via RDP

Optionally the script can install and configure:<br>
-Google Chrome<br>
-Putty<br>
-PowerCLI<br>
-PowerVCF<br>
-PowerValidated Solutions<br>
-VCF Lab Constructor<br>
-Additional Files and scripts<br>

You will need to download and specify the location via script parameters (detailed below) the following software at a minimum:<br>
-Windows Server 2019 - This is an evaluation copy that will expire 180 days from date of install
 -https://software-download.microsoft.com/download/pr/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso
-Latest VMTools
 -https://packages.vmware.com/tools/esx/latest/windows/x64/

Locations for downloading optional software:<br>
-Google Chrome Standalone<br>
 -https://www.google.com/intl/en/chrome/?standalone=1<br>
-Latest PowerCLI module Zip<br>
 -https://developer.vmware.com/web/tool/vmware-powercli<br>
-Latest PowerVCF module Zip<br>
 -https://github.com/vmware/powershell-module-for-vmware-cloud-foundation/archive/refs/heads/main.zip<br>
-Latest PowerValidatedSolutions module Zip<br>
 -https://github.com/vmware-samples/power-validated-solutions-for-cloud-foundation/archive/refs/heads/main.zip<br>
-Latest Putty SSH Client MSI<br>
 -https://tartarus.org/~simon/putty-snapshots/w64/putty-64bit-installer.msi<br>
-Latest OVFTool<br>
 -https://developer.vmware.com/web/tool/4.4.0/ovf<br>
-VCF Lab Constructor<br>
 -https://tiny.cc/getVLCBits<br>

Once the ISO is created you'll need to create a VM, mount the ISO and boot the VM.  It can take ~30 minutes to run the install and configuration but there is no interaction required.

VM as follows:
-Guest OS family: Windows
-Guest OS version: Microsoft Windows Server 2019
-Hardware defaults are fine EXCEPT:
 -Customize settings: Connect to correct portgroup and set Network adapter type to VMXNET3

See detailed help in powershell by running "get-help autoJump.ps1 -detailed" or the help.txt file in the script directory.

SYNTAX
    C:\Users\Administrator\Documents\autoJump\autoJump.ps1 [[-compName] <String>] [[-compIP] <String>] [[-compSubnet] <String>] [[-compGw] <String>] [[-compVlan] <String>] [[-compDNSFwd] <String>]
    [[-adDomain] <String>] [[-adminPass] <String>] [-vmToolsExeLoc] <FileInfo> [-winIsoLoc] <FileInfo> [-isoRole] <Object> [[-powerCLIZipLoc] <FileInfo>] [[-ovfToolMSILoc] <FileInfo>] [[-puttyMSILoc]
    <FileInfo>] [[-chromeInstallerExeLoc] <FileInfo>] [[-powerVCFZipLoc] <FileInfo>] [[-powerVSZipLoc] <FileInfo>] [[-vlcZipLoc] <FileInfo>] [[-addHostsFile] <FileInfo>] [[-bookMarksFile] <FileInfo>]
    [[-addCmdsFile] <FileInfo>] [[-addFilesFile] <FileInfo>] [<CommonParameters>]

Example command line:

Splatted parameters (Minimum required parameters):

$autoJumpParms = @{
	winIsoLoc = "C:\Users\Administrator\Downloads\17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso"
	vmToolsExeLoc = "C:\Users\Administrator\Downloads\VMware-tools-11.3.5-18557794-x86_64.exe"
	isoRole = "JUMP"
	}

.\autoJump.ps1 @autoJumpParms

---------------------------------------------------------------------------------------------------------------------------------------

CLI Parameters (Minimum required parameters):

.\autoJump.ps1 -winIsoLoc C:\Users\Administrator\Downloads\17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso -vmToolsExeLoc C:\Users\Administrator\Downloads\VMware-tools-11.3.5-18557794-x86_64.exe -isoRole JUMP



