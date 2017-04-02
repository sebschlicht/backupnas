# NAS

This document researches and describes the requirements for a home NAS to backup files.
Later on, setup instructions and configurations will be presented.

## Requirements

### Compatibility

* All systems SHOULD be able to read from and write to the NAS.
* Windows and Linux systems MUST be supported.
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

## Test Setup

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
Security           | rights-linux | COULD    | 

## Setup

### Installation

    sudo apt-get install samba

### Configuration

Samba config: `/etc/samba/smb.conf`

#### Add User

1. Create the user on the system. This is necessary, as Samba users map to system users. This is essential to the permission management using Samba.

       adduser <user>

1. Create a folder in the NAS root, where the user's data should be stored and set appropriate permissions.

       sudo mkdir <path>
       sudo chown -R <user>:<user> <path>
       sudo chmod 700 <path>

1. Create the respective Samba user.

       sudo smbpasswd -a <user>

1. Now add a share for the user's folder to the Samba config using the following template:

       [<user>]  
         path = <path>  
         comment = Private share for user <user>.  
         valid users = <user>
         writeable = yes
         create mask = 0644  
         directory mask = 0755  
         guest ok = no
   
   **Explanation**
   * The `valid users` directive limits the access to the user that the share has been created for.
   * The `mask` directives ensure that the permissions of new files (and directories) match the default file permissions when working on disk.

1. Restart the Samba server to apply the config changes.

       sudo service smbd restart

### Public Share

To create a share that all users can both read and write to, follow the following steps.

1. Create a system user for the public share, e.g.

       adduser nas

1. Create a folder in the NAS root, where the user's data should be stored and set appropriate permissions.

       sudo mkdir <path>
       sudo chown -R nas:nas <path>
       sudo chmod 777 <path>

1. Create the respective Samba user.

       sudo smbpasswd -a nas

1. Now add the public share to the Samba config using the following template:

       [public]
         path = /nas/all
         comment = Public share for all users.
         writeable = yes
         browseable = yes
         create mask = 0666
         directory mask = 0777
         force user = nas
         force group = nas
         guest ok = no
   
**Explanation**
* The `mask` directives ensure that all users can access the files on disk level.
* The `force` directives let all files be owned by `nas:nas` on disk.
* The `guest` directive prohibits access without any login but you may also enable it.

## Backup Automatisation

Consider a backup script that is able to backup all relevant user files.
In order to let backups run automatically, let's say once a day, we need a scheduler that runs this script.
Due to file permissions, we need to run the backup script as the user that's owning the files.

A default crontab is executed in user mode.
However, cron doesn't execute missed jobs, thus backups could be skipped on multiple days of working on the computer.
This violates my requirements.

Anacron solves this issue but is executed as root.
We could use `su` to act as the intended user, but if you're using a password-protected SSH key to login to the remote machine it get's fuzzy:
Indeed, the user is prompted to unlock the key but the authentication window doesn't look as usual and the password isn't cached.
If you back up multiple directories (using multiple `rsync` statements), the user is promted to re-enter the password for each directory.

One solution is to use anacron in user mode.

### Anacron in User Mode

(These steps can be performed by `install.sh`)

1. To set up a user anacrontab create the anacron files and directories in the user's home:

       mkdir ~/etc
       touch ~/etc/anacrontab
       mkdir -p ~/var/spool/anacron

   (The first directory holds user-specific configuration files, such as the anacrontab.
   The second directory is used by anacron to store job timestamps to keep track of which ones are due and which are not.)

1. Create an anacrontab for the user that starts the script in the period of your choice (here: daily):

       # /etc/anacrontab: configuration file for anacron
       
       # See anacron(8) and anacrontab(5) for details.
       
       SHELL=/bin/bash
       PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
       
       # period  delay  job-identifier  command
       1         2      user.backup     ~/Scripts/backup.sh

1. Call anacron from `~/.profile` to execute the job on each login, if it's due:

       # run anacron in user mode
       /usr/sbin/anacron -s -t ${HOME}/etc/anacrontab -S ${HOME}/var/spool/anacron

   **If your computer** runs for a long period and **doesn't login daily**, this **approach** would be **insufficient**.
   In this case it would be better to create a daily *user cronjob* that calls anacron.

This way the SSH key doesn't have to be unlocked on each SSH command.

### Test Anacron Jobs

In order to test if the everything is working as expected, run anacron in foreground mode, forcing the execution of jobs right now:

       /usr/sbin/anacron -s -t ${HOME}/etc/anacrontab -S ${HOME}/var/spool/anacron -dfn
  
## Resources

* [RaspberryPi NAS Guide](http://www.welzels.de/blog/projekte/raspberry-pi/low-budget-nas-mit-einem-raspberry-pi/pi-nas-datei-server-und-zubehor/)
* [RaspberryPi Samba Installation Guide](https://jankarres.de/2013/11/raspberry-pi-samba-server-installieren/)
* [Samba Documentation: Users and Security](https://www.samba.org/samba/docs/using_samba/ch09.html)
* [Anacron in User Mode](http://askubuntu.com/questions/235089/how-can-i-run-anacron-in-user-mode)
