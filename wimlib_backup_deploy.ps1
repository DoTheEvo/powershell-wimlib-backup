# ------------------------------------------------------------------------------
# ---------------------   DEPLOY_AND_MAKE_SCHEDULED_TASK   ---------------------
# ------------------------------------------------------------------------------
# - v1.0.2  2017-11-07

# - this script creates folder C:\ProgramData\wimlib_backup
# - copies in to it
#       "wimlib_backup.ps1"
#       "wimlib_backup_deploy.ps1"
#       "WIMLIB_BACKUP_DEPLOY.BAT"
#       "wimlib binary zip archive which is extracted and deleted afterwards"
# - new config file is created based on the users input
# - new $wimlib_backup_user windows local accout is created with a password
#       and is hidden from login screen
# - new scheduled backup task is created

# --------------------------------------------------------------------
$current_wimlib_version = 'wimlib-1.12.0-windows-x86_64-bin.zip'
$deploy_folder = 'C:\ProgramData\wimlib_backup'
$wimlib_backup_user = 'wimlib_backup_user'
# --------------------------------------------------------------------

# start logging in to %temp%
$log_file = "$env:TEMP\wimlib_deploy.log"
Start-Transcript -Path $log_file -Append -Force
$ErrorActionPreference = 'Stop'

# check if running as adming
$running_as_admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
if (-NOT $running_as_admin){
    echo 'NOT RUNNING AS ADMIN, THE END'
    cmd /c pause
    exit
}

# check powershell version
if ($PSVersionTable.PSVersion.Build -lt 14409) {
    echo $PSVersionTable.PSVersion
    echo 'INSTALL WMF 5.1'
    cmd /c pause
    exit
}

# check NET framework version
$NET_info = Get-ItemProperty -Path 'HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full' -ErrorAction Stop
if ($NET_info.Release -lt 378675) {
    echo "NET framework version: $($NET_info.Version)"
    echo 'UPDATE NET FRAMEWORK TO AT LEAST v4.5.1'
    cmd /c pause
    exit
}

$t = Get-Date -format 'yyyy-MM-dd || HH:mm:ss'
echo ' '
echo '################################################################################'
echo "#######                      $t                      #######"

echo ' '
echo '---  COPYING FILES  ------------------------------------------------------------'
echo ' '

# copying and extracting files if need be
if ($PSScriptRoot -eq $deploy_folder) {
    echo "- running this script from $deploy_folder"
    echo '- no new files are copied'
} else {
    echo "- copying the files in to $deploy_folder"
    echo '  - wimlib_backup.ps1'
    echo '  - wimlib_backup_deploy.ps1'
    echo '  - WIMLIB_BACKUP_DEPLOY.BAT'
    echo "  - $current_wimlib_version"
    echo '- will overwrite files at the destination'
    robocopy $PSScriptRoot $deploy_folder wimlib_backup.ps1 wimlib_backup_deploy.ps1 WIMLIB_BACKUP_DEPLOY.BAT $current_wimlib_version /IS /NFL /NDL /NJS

    # extract wimlib zip and delete the zip file afterwards
    $zip_wimlib_path = Join-Path -Path $deploy_folder -ChildPath $current_wimlib_version
    $zip_extract_target = Join-Path -Path $deploy_folder -ChildPath (Get-Item $zip_wimlib_path).BaseName
    if (Test-Path $zip_extract_target) {
        echo "- $zip_extract_target already exists, deleting"
        Remove-Item $zip_extract_target -Force -Recurse
    }
    echo "- extracting wimlib program files in to $zip_extract_target"
    expand-archive -Path $zip_wimlib_path -destinationpath $zip_extract_target -Force
    echo '- deleting the zip file'
    Remove-Item -Path $zip_wimlib_path -Force
}

echo ' '
echo '---  NEW BACKUP JOB  -----------------------------------------------------------'
echo ' '

# get a name that will be associated with this backup
echo '- ENTER THE NAME FOR THIS BACKUP'
echo '  - config file will be named based on it'
echo '  - wim archive will be named after it'
echo '  - shechuled task will have it in the name'
$backup_name = Read-Host '- no spaces, no diacritic, no special characters'
while (!$backup_name) {
    $backup_name = Read-Host '- no spaces, no diacritic, no special characters'
}

echo "- backup name entered: $backup_name"
echo "- deploy path: $deploy_folder"

# some paths that will be used
$config_file_name = ('{0}_config.ini' -f $backup_name)
$configs_folder = Join-Path -Path $deploy_folder -ChildPath 'configs'
$config_file_path = Join-Path -Path $configs_folder -ChildPath $config_file_name

# check if config with the same name exists
if (Test-Path $config_file_path) {
    echo "THE NAME: $backup_name IS ALREADY IN USE!"
    echo 'EXITING...'
    cmd /c pause
    exit
}

# create the deploy and config folder if needed
if (Test-Path $deploy_folder) {
    echo "- the $deploy_folder path already exists"
} else {
    echo "- creating new folder: $deploy_folder"
    New-Item $deploy_folder -type directory
}

if (Test-Path $configs_folder) {
    echo "- the $configs_folder path already exists"
} else {
    echo "- creating new folder: $configs_folder"
    New-Item $configs_folder -type directory
}

# default values that will be in ???_config.ini
$config_template = @'
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
send_email=false
# comma separated emal addresses
email_recipients=example@example.com
email_sender_address=example@example.com
email_sender_password=password123
email_sender_smtp_server=smtp.gmail.com
'@

$config_template | Out-File -FilePath $config_file_path -Encoding ASCII

echo ' '
echo "- config file created: $config_file_path"

# add permission to allow easy editing of the config file
$Acl = Get-Acl -Path $config_file_path
$Ar = New-Object  system.security.accesscontrol.filesystemaccessrule('USERS','Modify','Allow')
$Acl.SetAccessRule($Ar)
Set-Acl -Path $config_file_path -AclObject $Acl
echo '- changing config files permissions to allow easy editing'


# creating new user to allow the scheduled task to run without being seen in any way
# /RU SYSTEM does not work on win10, and 7/8 had less info in logging
echo ' '
echo '---  CREATING / CHECKING WINDOWS LOCAL USER  -----------------------------------'
echo ' '

$local_users = Get-LocalUser
if (-NOT ($local_users.Name -contains $wimlib_backup_user)) {
    echo "- adding new user: $wimlib_backup_user"
    echo '- enter new password for this account'
    $usr_password = Read-Host -AsSecureString
    New-LocalUser -Name $wimlib_backup_user -Password $usr_password -Description 'Wimlib Backup Administrator' -AccountNeverExpires -PasswordNeverExpires
    Add-LocalGroupMember -Group 'Administrators' -Member $wimlib_backup_user
    echo '- added to the Administrators group'

    # editing registry to hide the account from login screen
    echo "- hidding $wimlib_backup_user from the login screen"
    $registry_path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList'
    New-Item $registry_path -Force | New-ItemProperty -Name $wimlib_backup_user -Value 0 -PropertyType DWord -Force
} else {
    echo "- $wimlib_backup_user already exists, lets hope you remember the password"
}

echo ' '
echo '---  CREATING NEW SCHEDULED TASK  ----------------------------------------------'
echo ' '

#=================================================================
# function to create folder named $taskpath in task scheduler
# $ErrorActionPreference must be Stop to catch non-terminating exception
Function New-ScheduledTaskFolder {
    Param ($taskpath)

    $scheduleObject = New-Object -ComObject schedule.service
    $scheduleObject.connect()
    $rootFolder = $scheduleObject.GetFolder("\")

    Try {$null = $scheduleObject.GetFolder($taskpath)}
    Catch { $null = $rootFolder.CreateFolder($taskpath) }
}
#=================================================================

New-ScheduledTaskFolder 'wimlib_backup'

# scheduled task should be edited using taskschd.msc, not here
$schedule = 'DAILY' # MINUTE HOURLY DAILY WEEKLY MONTHLY ONCE ONSTART ONLOGON ONIDLE
$modifier = 1 # 1 - every day, 7 - every 7 days, behaves differently depending on unit in schedule
$start_time = '20:19'
$title = "wimlib_backup\$backup_name"
$command_in_trigger = "'& C:\ProgramData\wimlib_backup\wimlib_backup.ps1 -config_path $config_file_path'"
$trigger = "Powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command $command_in_trigger"

# using cmd for the compatibility with windows 7 instead of Register-ScheduledTask cmdlet
# /RP for password is needed to allow run without being logged in
cmd /c SchTasks /Create /SC $schedule /MO $modifier /ST $start_time /TN $title /TR $trigger /RL HIGHEST /F /RU $wimlib_backup_user /RP

echo '- adjust the backups schedule using taskschd.msc'
echo ' '
echo 'THE END'
echo ' '
echo '################################################################################'

Stop-Transcript
cmd /c pause
