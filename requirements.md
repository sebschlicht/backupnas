# NAS Backup System

This document researches and describes the requirements for a home NAS to backup files.
This includes methods to communicate with the NAS, permissions and folder structures on file level and security concerns.
Thus not only the NAS with its components but also related devices, the OS and configurations are of concern.

## Requirements

Requirements are split up into three groups:
1. Compatibility (with clients including administrators) 
1. Availability (of the system and the data it's storing)
1. Security (of the system and the data it's storing)

### Compatibility

* All systems SHOULD be able to read from the NAS.
* Windows and Linux systems MUST be able to read from the NAS.
* The NAS SHOULD be mountable from Linux systems.
* The NAS system SHOULD be accessible via SSH.
* The NAS SHOULD be readable/writable via SSH.

### Availability

* The NAS SHOULD be available at any time.
* It COULD be available from any location in this world.
* If the NAS goes down, there MUST be a backup system available, with data that SHOULD not be older than 2 days.
* There SHOULD be a way to undo changes and revert files to their status of at least 2 weeks before.

### Security

* The NAS MUST authenticate users to ensure they're allowed to access the NAS.
* It SHOULD be able to limit write and COULD be able to limit read access of certain directories to certain users.
* It COULD be able to match Linux users on the filesystem to Windows users accessing the NAS and vice versa.

## Setup: Samba@RaspberryPi

Requirements Group | Requirement | Priority | Solution
------------------ | ----------- | -------- | --------
Compatibility      | universal   | SHOULD   | 
Compatibility      | used-os     | MUST     | 
Compatibility      | linux-mount | SHOULD   | 
Compatibility      | ssh-admin   | SHOULD   | Pi@raspbian
Compatibility      | ssh-rw      | SHOULD   | 
Availability       | available   | SHOULD   | Pi (low power consumption) and sleepable hard drive
Availability       | remote      | COULD    | FritzBox! VPN
Availability       | backup      | MUST     | RAID-0 on second NAS system / hard drive
Availability       | backup-new  | SHOULD   | cronjob to sync systems / hard drives
Availability       | undo        | SHOULD   | 
Security           | auth        | MUST     | 
Security           | rights-w    | SHOULD   | 
Security           | rights-r    | COULD    | 
Security           | rights-linux | COULD   | 
