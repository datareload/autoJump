::==============================================================
:: This file gives several examples of commands that can be run
:: All of the installers, files and scripts referenced will need
:: to be copied to the image using by listing in the 
:: additionalfiles parameter
:: Note:If there are spaces in the path or filename it must be quoted.
::=============================================================
::
:: Add a *non-persistant* route

route add 172.24.32.0 mask 255.255.255.0 10.0.0.1

:: Install Notepad ++ using the executable installer with "Silent" switch

%WINDIR%\Setup\Scripts\npp.8.4.7.Installer.x64.exe /S

:: Install FireFox using the MSI installer with "quiet" switch and "no restart". 

"%WINDIR%\Setup\Scripts\Firefox Setup 107.0.msi" /q /norestart

:: Run a powershell script

%WINDIR%\system32\WindowsPowerShell\v1.0\powershell.exe -c %WINDIR%\Setup\Scripts\setwallpaper.ps1