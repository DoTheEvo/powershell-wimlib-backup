# powershell-wimlib-backup

**deduplicating, shadow copy, backup solution using wimlib**

based around [wimlib](https://wimlib.net/) - open source, cross-platform library for creating, extracting, and modifying Windows Imaging (WIM) archives.

* deduplication saves lots of disk space
* Volume Shadow Service, opened / locked files do get backed up
* scheduled backups
* automatic deletion of old backups
* email notifications
* whole system drive backup
* over the network backups

---

## how to install

* check that you have powershell at version 5.1 using `$PSVersionTable.PSVersion`  
  if not, [offline installer here](https://www.microsoft.com/en-us/download/details.aspx?id=54616)
* download the latest [powershell-wimlib-backup release](https://github.com/DoTheEvo/powershell-wimlib-backup/releases)
* extract it
* run `WIMLIB_BACKUP_DEPLOY.BAT` as an administrator
* follow the on-screen instructions
* done, delete downloaded and extracted files

![PSVersion](https://i.imgur.com/f5SSO6r.png)

## how to configure

* edit ini file in `C:\ProgramData\wimlib_backup\configs\<name>` based on your needs
* in task scheduler find folder `wimlib_backup` and inside it set task to your prefered schedule

![config_file](https://i.imgur.com/NBlJ8uD.png)

---

#### aditional info

- user `wimlib_backup_user` with admin privilages is created, it allows scheduled powershell scripts to run on the background without being seen
- in config file you can set email and receive info after each backup
- in config file you can set up automatic deletion of old backups
- there are detailed logs in `C:\ProgramData\wimlib_backup\logs\`
- you can set many different backup tasks by re-running `C:\ProgramData\wimlib_backup\WIMLIB_BACKUP_DEPLOY.BAT`
- you can backup up whole system partition and then recover to that system. Though it's bit tricky. Easiest method is to just do clean installation using the same windows version you have, then delete all the files on the system partition and copy the ones from your backup in their place. This bypasses dealing with boot partition and such...

![email_info](https://i.imgur.com/jAXRgd3.png)

#### files explained


| file                                   | description                                                                        |
|----------------------------------------|------------------------------------------------------------------------------------|
| `WIMLIB_BACKUP_DEPLOY.BAT`             | a bat file that bypasses script execution policy and runs wimlib_backup_deploy.ps1 |
| `wimlib_backup_deploy.ps1`             | script that copies files where they belong, creates user, creates schedule tasks   |
| `wimlib-1.12.0-windows-x86_64-bin.zip` | contains wimlib, gets extracted and placed in appdata                              |
| `wimlib_backup.ps1`                    | the actual backup script that based on config files runs wimlib                    |
| `simulate_years_of_backups.ps1`        | test file for simulating years of backups, changes date of the PC                  |
