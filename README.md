# powershell-wimlib-backup
Deduplicating, VSS, backup solution, creating wim archive, using wimlib

* Deduplicating - saves lots of space, cleaner and simpler than incremental
* VSS - Volume Shadow Service, opened files wont stop this backup

[wimlib](https://wimlib.net/) -  open source, cross-platform library for creating, extracting, and modifying Windows Imaging (WIM) archives. This powershell script just makes easier to use it.

---

## how to install

* download the latest [release](https://github.com/DoTheEvo/powershell-wimlib-backup/releases)
* extract it
* run `WIMLIB_BACKUP_DEPLOY.BAT` as administrator
* follow the on-screen instructions
* delete downloaded and extracted files

## how to configure

* edit ini file in `C:\ProgramData\wimlib_backup\configs\<name>` based on your needs
* edit `wimlib_backup_<name>` in task scheduler based on your needs

---

#### aditional info

- windows user `wimlib_backup_user` is created, it provides some benefits
- in config file you can set email and receive info after each backup
- you can set many different backup tasks by re-running `C:\ProgramData\wimlib_backup\WIMLIB_BACKUP_DEPLOY.BAT`
