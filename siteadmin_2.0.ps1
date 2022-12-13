# Script made by William Tran-Viet at uOttawa :) 

$elevated = ([Security.Principal.WindowsPrincipal] ` [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) # black magic check on if script is running in elevated mode
if($elevated -eq $false){ 
Write-Host "Script is not running with elevated access. Restart Powershell as administrator." -ForegroundColor Red
exit
}
function checksiteadmin{ # checks if siteadmin exists already
    $op = Get-LocalUser | where-Object Name -eq "siteadmin" | Measure-Object # measures number of users named siteadmin 
    if ($op.Count -ne 0) {
        retrun $false
    }
    return $true
}

function addUsers{ # takes input of usernames separated by commas, splits into array and iteratively adds each user.  
    if($users.Length -eq 0){ # check for empty input
        Write-Host "No users added." -ForegroundColor Yellow
    }
    else{
        [array]$Array = $users.Split(",") 
        foreach ($i in $Array){
            try{
                Add-LocalGroupMember Administrators -Member OU\$i -ErrorAction Stop # the exceptions for this command don't get caught without -ErrorAction Stop
                Write-Host "User $i added to local admin group." -ForegroundColor Green
            }
            catch [Microsoft.PowerShell.Commands.PrincipalNotFoundException] {
                Write-Host "WARNING: User $i not found." -ForegroundColor Red
            }
            catch [Microsoft.PowerShell.Commands.MemberExistsException]{
                Write-Host "WARNING: User $i is already in local admin group." -ForegroundColor Red 
            }
        }
    } 
}
Start-Transcript -OutputDirectory "$PSScriptRoot\pstranscripts" # logging
Write-Host "Current working directory: $PSScriptRoot" 
Write-Host "Installing NuGet Package Provider..." # pre-requisites to do windows updates
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force 
Write-host "Installing PSWindowsUpdate module..."
Install-Module -Name PSWindowsUpdate -Force
Import-Module -Name PSWindowsUpdate


if(checksiteadmin -eq $true){
    Write-Host "Siteadmin exists already, skipping over..." -ForegroundColor Red
}
else{
    Write-Host "Siteadmin does not exist, proceeding." 
    Start-Sleep -Seconds 0.55 # arbitrary sleep :)
    Write-Host "Enter password."  
    $password = Read-Host -AsSecureString # password input
    Write-Host "Creating siteadmin..."
    New-LocalUser -Name "siteadmin" -Password $password -Description "Local admin account for SITE IT Services." -AccountNeverExpires -PasswordNeverExpires 
    Add-LocalGroupMember "Administrators" -Member "siteadmin" 
}
Start-Sleep -Seconds 0.55
Write-Host "Enter users to add as admin, separated by only a comma (NO SPACES), then press Enter. If none then leave field empty:"
$users = Read-Host
Write-Host "Adding Users..."
addUsers
Start-Sleep -Seconds 5
Write-Host "Starting Dell SupportAssist..." # installs dell supportassist which should be in the same folder as this script, sometimes it fails
Start-Process -Wait -FilePath "$PSScriptRoot\SupportAssistInstaller.exe"  
Write-Host "Setting Execution Policy back to Restricted..."
Set-ExecutionPolicy Restricted
Write-Host "Starting Windows Updates, PC will reboot automatically. Transcript file will be stored in the scripts\pstranscripts"
Stop-Transcript 
Install-WindowsUpdate -AcceptAll -AutoReboot
