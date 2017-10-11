# ------------------------------------------------------------------------------
# ---------------------   DEPLOY_AND_MAKE_SCHEDULED_TASK   ---------------------
# ------------------------------------------------------------------------------
# - this script creates folder C:\ProgramData\wimlib_backup
# - copies in to it
#       "wimlib_backup.ps1"
#       "wimlib_backup_deploy.ps1"
#       "WIMLIB_BACKUP_DEPLOY.BAT"
#       "wimlib zip archive which get extracted and deleted afterwards"
# - creates in it a config file named based on the users input
# - creates new $wimlib_backup_user account with a password
# - creates new scheduled backup task

# --------------------------------------------------------------------
$current_wimlib_version = "wimlib-1.12.0-windows-x86_64-bin.zip"
$deploy_folder = 'C:\ProgramData\wimlib_backup'
$wimlib_backup_user = "wimlib_backup_user"
# --------------------------------------------------------------------

# start logging in to %temp%
$log_file = "$env:TEMP\wimlib_deploy.log"
Start-Transcript -Path $log_file -Append -Force
$ErrorActionPreference = "Stop"

# check if running as adming
$running_as_admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-NOT $running_as_admin){
    echo "NOT RUNNING AS ADMIN, THE END"
    cmd /c pause
    exit
}

$t = Get-Date -format "yyyy-MM-dd || HH:mm:ss"
echo " "
echo "################################################################################"
echo "#######                      $t                      #######"
echo " "

# get the name that will be associated with this backup
echo "ENTER THE NAME OF THIS BACKUP"
echo "- config file will be named based on it"
echo "- wim archive will be named after it"
echo "- shechuled task will have it in the name"
$backup_name = Read-Host "- no spaces, no diacritic, no special characters"
while (!$backup_name) {
    $backup_name = Read-Host "- no spaces, no diacritic, no special characters"
}

# some paths that will be used
$config_file_name = $backup_name + "_config.ini"
$configs_folder = Join-Path -Path $deploy_folder -ChildPath "configs"
$config_file_path = Join-Path -Path $configs_folder -ChildPath $config_file_name

# check if config with the same name does not alrady exists
if (Test-Path $config_file_path) {
    echo "THE NAME: $backup_name IS ALREADY IN USE!"
    cmd /c pause
    exit
}

echo "`n- deploy path: $deploy_folder"

if (Test-Path $deploy_folder) {
    echo "- the $deploy_folder path already exists"
} else {
    New-Item $deploy_folder -type directory
    echo "- new folder created: $deploy_folder"
}

if (Test-Path $configs_folder) {
    echo "- the $configs_folder path already exists"
} else {
    New-Item $configs_folder -type directory
    echo "- new folder created: $deploy_folder"
}

$config_template = @"
target=C:\test
backup_path=C:\
# LZX:20 is quick, LZX:50 is normal, LZX:100 is max compression
compression_level=LZX:20
backup_wim_file_before_adding_new_image=false
delete_old_backups=true
keep_last_n=3
keep_monthly=false
keep_n_monthly=4
keep_weekly=false
keep_n_weekly=2
"@

$config_template | Out-File -FilePath $config_file_path -Encoding ASCII

echo "`n- config file created: $config_file_path"

# add permission to allow easy editing of the config file
$Acl = Get-Acl -Path $config_file_path
$Ar = New-Object  system.security.accesscontrol.filesystemaccessrule("USERS","Modify","Allow")
$Acl.SetAccessRule($Ar)
Set-Acl -Path $config_file_path -AclObject $Acl
echo "- changing config files permissions to allow easy editing"


# copying and extracting files if need be
if ($PSScriptRoot -eq $deploy_folder) {
    echo "`n- running this script from $deploy_folder"
    echo "- nothing will be copied"
    echo "- only a new config file is created and a new scheduled task is added"
} else {
    echo "`n- copying the files to $deploy_folder"
    echo "- will overwrite script files if they already exist"
    robocopy $PSScriptRoot $deploy_folder wimlib_backup.ps1 wimlib_backup_deploy.ps1 WIMLIB_BACKUP_DEPLOY.BAT $current_wimlib_version /NFL /NDL /NJS /IS

    # extract wimlib zip and delete the zip file afterwards
    $zip_wimlib_path = Join-Path -Path $deploy_folder -ChildPath $current_wimlib_version
    $zip_extract_target = Join-Path -Path $deploy_folder -ChildPath (Get-Item $zip_wimlib_path).BaseName
    if (Test-Path $zip_extract_target) {
        echo "- $zip_extract_target already exists, deleting"
        Remove-Item $zip_extract_target -Force -Recurse
    }
    echo "- extracting wimlib program files in to $zip_extract_target"
    expand-archive -Path $zip_wimlib_path -destinationpath $zip_extract_target -Force
    Remove-Item -Path $zip_wimlib_path -Force
}

# new user to allow the scheduled task to run without being seen in any way, /RU SYSTEM does not work on win10, and 7/8 had less info in logging
$local_users = Get-LocalUser
if (-NOT ($local_users.Name -contains $wimlib_backup_user)) {
    echo "`nADDING NEW USER: $wimlib_backup_user"
    echo "- enter new password for this account"
    $usr_password = Read-Host -AsSecureString
    New-LocalUser -Name $wimlib_backup_user -Password $usr_password -Description "Wimlib Backup Administrator" -AccountNeverExpires -PasswordNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member $wimlib_backup_user
    echo "- added to the Administrators group"

    # editing registry to hide the account from login screen
    echo "- hidding $wimlib_backup_user from the login screen"
    $registry_path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList'
    New-Item $registry_path -Force | New-ItemProperty -Name $wimlib_backup_user -Value 0 -PropertyType DWord -Force
} else {
    echo "- $wimlib_backup_user already exists, youd better remember the password"
}


# scheduled task should be edited manually afterwards using taskschd.msc
echo "CREATING NEW SCHEDULED TASK"

$schedule = "DAILY" # MINUTE HOURLY DAILY WEEKLY MONTHLY ONCE ONSTART ONLOGON ONIDLE
$modifier = 1 # 1 - every day, 7 - every 7 days, behaves differently depending on unit in schedule
$start_time = "20:19"
$title = "wimlib_backup_$backup_name"
$command_in_trigger = "'& C:\ProgramData\wimlib_backup\wimlib_backup.ps1 -config_path $config_file_path'"
$trigger = "Powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command $command_in_trigger"

# using cmd for the compatibility with windows 7 instead of Register-ScheduledTask cmdlet
# /RP for password is needed to allow run without being logged in
cmd /c SchTasks /Create /SC $schedule /MO $modifier /ST $start_time /TN $title /TR $trigger /RL HIGHEST /F /RU $wimlib_backup_user /RP

echo "- edit the scheduled task using taskschd.msc for the specific needs"

echo " "
echo "################################################################################"

Stop-Transcript
cmd /c pause
