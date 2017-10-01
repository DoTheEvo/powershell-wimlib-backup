# ------------------------------------------------------------------------------
# -----------------------------   WIMLIB_BACKUP   --------------------------
# ------------------------------------------------------------------------------
# - requirements:
#       WMF 5.0+, Volume Shadow Copy (VSS) service enabled
# - this script backups $target in to a wim file at $backup_path
# - uses volume shadowcopy service to also backup opened files
# - uses deduplication of wim format to greatly reduce size of the backup

# ----  values expected in config file  ----
# target=C:\test
# backup_path=C:\
# compression_level=LZX:20
# delete_old_backups=true
# keep_last_n=3
# keep_monthly=false
# keep_n_monthly=10
# keep_weekly=false
# keep_n_weekly=4
# ----------------------------------------------
# keep_last_n - integer, that number of last backups are kept no matter other settings
# keep_weekly - true/false, if set to true, keep one backup of every week
# keep_monthly - true/false, if set to true, keep one backup of every month

# get full path to the config file passed as a parameter, throw error if theres none
Param( [string]$config_path=$(throw "config file is mandatory, please provide as parameter") )

$config_fullpath = Resolve-Path -Path $config_path
$config_file_name = (Get-Item $config_fullpath).name

#removes _config.ini from the name if its there, if its not it uses whole filename without the extention
if ($config_file_name.EndsWith('_config.ini')) {
    $pure_config_name = $config_file_name.Substring(0,($config_file_name.Length)-11)
} else {
    $pure_config_name = $config_file_name.Substring(0,($config_file_name.Length)-4)
}

# start logging in to the log file that is named based on the config file
$log_file_name = $pure_config_name + ".log"
$log_file_full_path = Join-Path -Path $PSScriptRoot -ChildPath "logs" | Join-Path -ChildPath $log_file_name
Start-Transcript -Path $log_file_full_path -Append -Force

# read the content of the config file, ignore lines starting with #, rest load as variables
Get-Content $config_fullpath | Foreach-Object{
    if (-NOT $_.StartsWith("#")){
        $var = $_.Split('=')
        # load preset variables as booleans
        if (@('delete_old_backups','keep_monthly','keep_weekly') -contains $var[0]) {
            New-Variable -Name $var[0] -Value  ($var[1] -eq $true)
        # load what looks like numbers as integers
        } ElseIf ($var[1] -match "^\d+$") {
            echo "we got integer: $var[0]"
            echo "value: $var[1]"
            $integer_version = [convert]::ToInt32($($var[1]), 10)
            New-Variable -Name $var[0] -Value $integer_version
        # rest as string
        } else {
            New-Variable -Name $var[0] -Value $var[1]
        }
    }
}

# some variables used through out the script
$ErrorActionPreference = "Stop"
$script_start_date = Get-Date
$date = Get-Date -format "yyyy-MM-dd"
$unix_time = Get-Date -UFormat %s -Millisecond 0
$wimlib_exe_full_path = "C:\ProgramData\wimlib_backup\wimlib-1.12.0-windows-x86_64-bin\wimlib-imagex.exe"
$wim_image_name = $pure_config_name + "_" + $date + "_" + $unix_time

$t = Get-Date -format "yyyy-MM-dd || HH:mm:ss"
echo " "
echo "################################################################################"
echo "#######                      $t                      #######"
echo " "
echo "- user: $(whoami)"
echo "- target: $target"
echo "- target partition: $target_partition"
echo "- backup to destination: $backup_path"
echo "- compression_level: $compression_level"
echo "- delete_old_backups: $delete_old_backups"
echo "- keep_last_n: $keep_last_n"
echo "- keep_monthly: $keep_monthly"
echo "- keep_weekly: $keep_weekly"
echo "- keep_n_monthly: $keep_n_monthly"
echo "- keep_n_weekly: $keep_n_weekly"

# running with admin privilages check
$running_as_admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-NOT $running_as_admin){
    throw "NOT RUNNING AS ADMIN, THE END"
}
# check if $target path exists on the system
if (-NOT (Test-Path $target)) {
    throw "NOT A VALID TARGET PATH: " + $target
}
# check if $backup_path path exists on the system
if (-NOT (Test-Path $backup_path)) {
    throw "NOT A VALID BACKUP PATH: " + $backup_path
}

echo "-------------------------------------------------------------------------------"
echo "USING WIMLIB TO BACKUP UP TARGET IN TO A WIM ARCHIVE"

$wim_file_full_path = join-path -path $backup_path -childpath $($pure_config_name + ".wim")

if (Test-Path $wim_file_full_path) {
    "- adding new image in to the archive '$wim_file_full_path' ..."
    $command = 'append'
} else {
    "- Creating new wimlib archive '$wim_file_full_path' ..."
    $command = 'capture'
}

[Collections.ArrayList]$wimlib_arguments = $command, $target, $wim_file_full_path, $wim_image_name, "--snapshot", "--compress=$compression_level", "--check"

echo "- this command will now be executed:"
echo "$wimlib_exe_full_path $wimlib_arguments"

&$wimlib_exe_full_path $wimlib_arguments

echo "- done"

$runtime = (Get-Date) - $script_start_date
$readable_runtime = "{0:dd} days {0:hh} hours {0:mm} minutes {0:ss} seconds" -f $runtime

echo " "
echo "#######              $readable_runtime              #######"
echo "################################################################################"
echo " "
