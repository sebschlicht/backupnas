# NAS Backup Script

The NAS backup script (*NB*) can create automatic backups of your personal data.
In contrast to backup tools like *duplicity*, *NB* stores your files in a way that they are directly accessible.

By default, a daily backup of your entire home directory will be created, where new files will be added and existing files will be updated.
Locally removed files, however, will be left at the backup location untouched.

The backup location can be a local directory or a remote location, accessed via SSH (public key authentication).

## Getting Started

1. Install the backup script and its [dependencies](dependencies-and-compatibility) via the installer:

       git clone git@github.com:sebschlicht/backupnas.git
       cd backupnas
       ./install.sh

1. Adapt the configuration (`~/.nb/config`) to your needs:

       REMOTE_HOST=pi3
       REMOTE_USERNAME=sebschlicht
       BACKUP_LOCATION=/mnt/nas/primary/backup/sebschlicht
   
   *Note*: You may leave out the `REMOTE_*` options if you want to backup your files to a local directory.

1. Done. Your home directory will be backed up to the specified location on a daily basis.  
   You can find the output of each day's run(s) in `~/.nb/logs/`.

## Further Configuration

For more information about the configuration options head to the [project's wiki](../../wiki) which covers how to

* exclude files from the backup
* backup files that are outside of your home directory
* configure a remote machine to host the backup(s)
  * access your files from numerous devices (Windows, Linux, mobile, smartTVs)
  * by adapting configuration files and running a single Ansible playbook
  * mirror the backup to a second location (backup the backup)

## Dependencies and Compatibility

*NB* has very few dependencies (installed by the installation script automatically) and works on any system that's able to provide them:

* rsync (transfer files)
* anacron (schedule automatic execution)

*NB* has been tested on Ubuntu 15.04+ (up to 18.04) but most probably will run smoothly on older versions and other distros.
