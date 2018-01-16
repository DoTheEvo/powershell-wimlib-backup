# powershell-wimlib-backup
Deduplicating, VSS, backup solution, creating wim archive, using wimlib

* Deduplicating - saves lots of space, cleaner than incremental
* VSS - Volume Shadow Service, opened files wont stop this backup

[wimlib](https://wimlib.net/) -  open source, cross-platform library for creating, extracting, and modifying Windows Imaging (WIM) archives. This powershell script just makes easier to use it.

---

## how to install

* have powershell at version 5.1, [offline installer here](https://www.microsoft.com/en-us/download/details.aspx?id=54616)
* download the latest [powershell-wimlib-backup release](https://github.com/DoTheEvo/powershell-wimlib-backup/releases)
* extract it
* run `WIMLIB_BACKUP_DEPLOY.BAT` as an administrator
* follow the on-screen instructions
* delete downloaded and extracted files

## how to configure

* edit ini file in `C:\ProgramData\wimlib_backup\configs\<name>` based on your needs
* edit `wimlib_backup_<name>` in task scheduler based on your needs

---

#### aditional info

- windows user `wimlib_backup_user` is created, it provides some benefits
- in config file you can set email and receive info after each backup
- in config file you can set up automatic deletion of old backups
- you can set many different backup tasks by re-running `C:\ProgramData\wimlib_backup\WIMLIB_BACKUP_DEPLOY.BAT`

#### files explained


| file                                   | description                                                                        |
|----------------------------------------|------------------------------------------------------------------------------------|
| `WIMLIB_BACKUP_DEPLOY.BAT`             | a bat file that bypasses script execution policy and runs wimlib_backup_deploy.ps1 |
| `wimlib_backup_deploy.ps1`             | script that copies files where they belong, creates user, creates schedule tasks   |
| `wimlib-1.12.0-windows-x86_64-bin.zip` | contains wimlib, gets extracted and placed in appdata                              |
| `wimlib_backup.ps1`                    | the actual backup script that based on config files runs wimlib                    |
| `simulate_years_of_backups.ps1`        | test file for simulating years of backups, changes date of the PC                  |
