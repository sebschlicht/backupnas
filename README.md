# NAS Backup Script

The NAS backup script (*NB*) can create automatic backups of your personal data.
In contrast to backup tools like *duplicity*, *NB* stores your files in a way that they are directly accessible.

By default, a daily backup of your entire home directory will be created, where new files will be added and existing files will be updated.
Locally removed files, however, will be left at the backup location untouched.

## Backup Destination

The backup location can be a local directory or a remote location, accessed via SSH (public key authentication).
Any machine with a SSH server running will do fine.

If you do not have a machine setup to serve as your backup destination already, consider my Ansible [NAS setup playbook](https://github.com/sebschlicht/ansible-nas) to get things up and running ASAP.
Special features include:

* access from numerous devices (Windows, Linux, mobile, smartTVs)
* mirroring the backup to a second location
* all in a single, configurable command (Ansible playbook)

However, you might as well create local backups for now.

## Getting Started

1. Download and extract the [latest release](releases/latest) or checkout the source code directly.

1. Install the backup script and its [dependencies](dependencies-and-compatibility) via the installer:

       $ cd backupnas
       $ ./install.sh
   
   *Note*: You will be required to authorize the installation (`sudo`) with your password.

1. Adapt the configuration (`~/.nb/config`) to your needs:

       REMOTE_HOST=pi3
       REMOTE_USERNAME=sebschlicht
       BACKUP_LOCATION=/mnt/nas/primary/backup/sebschlicht
   
   *Note*: You may leave out the `REMOTE_*` options if you want to store your backup in a local directory.

Done. Your home directory will be backed up to the specified location on a daily basis.  
You can find the logs of performed backups in `~/.nb/logs/`.

## Further Configuration

For more information about the configuration options head to the [project's wiki](../../wiki) which covers how to:

* exclude files from the backup
* backup additional/different locations

## Dependencies and Compatibility

*NB* has very few dependencies (installed by the installation script automatically) and works on any system that's able to provide them:

* rsync (transfer files)
* anacron (schedule automatic execution)

*NB* has been tested on Ubuntu 15.04+ (up to 18.04) but most probably will run smoothly on older versions and other distros.
