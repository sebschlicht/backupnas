# NAS Backup Script

The NAS backup script (*NB*) can be used to automate the process of backing up files to a local or remote location.
Using *rsync* under the hood, it supports backing up files to remote machines via SSH (authentication only via SSH key) and to NAS systems (Samba shares).

*NB* pushes user-defined locations to their declared destinations on a daily basis.
These locations and their destinations are defined in a single mapping file.

Newer files will never be overridden and no files will be removed at the backup location.
However, this behavior can be changed.

## Installation

To install *NB* checkout this repository and execute the installer:

    git clone git@github.com:sebschlicht/backupnas.git
    cd backupnas
    ./install.sh

This leaves you with the backup script at its place and some example configuration files at `~/.nb/examples`.

## Getting Started

If you want a quick start, here it is.  
If you want to elaborate on what's possible first, head to the [configuration section](#configuration).

1. Copy the example configuration files to the configuration folder and make the SSH example configuration your active *NB* configuration.

       cd ~/.nb/examples/
       cp ssh.* ../
       cp backup.ignore ../
       ln -s ../ssh.config ../backup.config
       
1. Edit the SSH remote and username in the `ssh.config`.  
   Please note that *NB* uses the user's default SSH key to connect via SSH.

1. Edit the `ssh.map` file to your needs.
   Each line maps a local directory to its (remote) backup location.  
   For example, the first line in the example file pushes the local folder `/data/sebschlicht/documents` to `/mnt/nas/main/backup/sebastian/documents` on the backup system.

## Example Configurations

There are three types of [configuration files](configuration.md) that the NAS backup script supports.
1. `.config` files: Specifies general configuration options.
1. [optional] `.map` files: Maps backup source paths to their destination path.
1. [optional] `.ignore` files: Allows to define exclusion patterns.

Here are two configuration examples, one for backups via SSH and one to a Samba server. 

In both setups we assume that a user (*sebschlicht*) wants to backup multiple directories containing:
* documents (`/data/sebschlicht/documents`)
* music (`/data/sebschlicht/music`)
* pictures (`/data/sebschlicht/pictures`)
* scripts (`/data/sebschlicht/scripts`)
* videos (`/data/sebschlicht/videos`)

*NB* supports to pass *the* source and *the* destination path as arguments.
However, we have multiple source and destination paths here.
Thus we have to use a [mapping file](configuration.md#mapping file).
Due to subtile differences when pushing via SSH and to Samba shares, we need different mapping files for both setups.

### SSH Setup

In order to push the listed directories to a remote machine (*pi*) via SSH, we have to specify the remote machine.
We simply set `NB_SSH_REMOTE` in the *NB* configuration file.

**~/.nb/ssh.config**:

    NB_SSH_REMOTE=pi
    
Since we've set a remote, all destination paths are now paths on the remote machine.

>Warning:  
You can't specify SSH credentials at the moment.
Thus SSH will only work using SSH keys.
The user's default SSH key will be used and the user will be prompted to unlock his or her key, if necessary.

Then we have to create a mapping file that maps all the local user directories to paths on *pi*.

**~/.nb/ssh.map**:

    /data/sebschlicht/documents/ /mnt/nas/main/backup/sebastian/documents
    /data/sebschlicht/music/ /mnt/nas/main/backup/sebastian/music
    /data/sebschlicht/pictures/ /mnt/nas/main/backup/sebastian/pictures
    /data/sebschlicht/scripts/ /mnt/nas/main/backup/sebastian/scripts
    /data/sebschlicht/videos/ /mnt/nas/main/backup/sebastian/videos

Using this mapping file, *NB* will push the content of `/data/sebschlicht/documents` to `/mnt/nas/main/backup/sebastian/documents` on the remote machine *pi*.
And so on.

Now we have to add our mapping file to the *NB* configuration:

**~/.nb/ssh.config**:

    NB_MAPPING_FILE=~/.nb/ssh.map
    NB_SSH_REMOTE=pi

Finally activate the config.

    ln -s ~/.nb/ssh.config ~/.nb/backup.config

That's it.
The next time the user logs into his account and backups haven't been made for a day, *NB* will push our directories to their respective remote location on *pi* via SSH using the user's SSH key.

### Samba Setup

To push the listed directories to a Samba server's (*pi*) share (*sebschlicht*), we first have to mount the share, e.g. to `/mnt/nas.pi`.
To do so, we add a entry to *fstab* using *cifs*

**/etc/fstab**:

    ...
    # mount Samba share sebschlicht for backups
    //pi/sebschlicht  /mnt/nas.pi  cifs  user,noauto  0  0

and create the mount point for the user.
You could (or rather should) use a location that the user has access to anyway.

    sudo mkdir -p /mnt/nas.pi
    sudo chown sebschlicht:sebschlicht /mnt/nas.pi

Now we need to specify the mountpoint in the *NB* configuration, so that *NB* mounts it prior to pushing the files.

**~/.nb/samba.config**:

    NB_MOUNTPOINT=/mnt/nas.pi

For now, *NB* doesn't have any credentials to mount the Samba share.
The most secure way is to specify the username in the *NB* configuration and let *NB* prompt the user for his Samba user password.

**~/.nb/samba.config**:

    NB_MOUNTPOINT=/mnt/nas.pi
    NB_SAMBA_USER=sebastian

Then we have to create a mapping file that maps all the local user directories to paths within the *mounted* Samba share. 

**~/.nb/samba.map**:

    /data/sebschlicht/documents/ /mnt/nas.pi/userdata/sebastian/documents
    /data/sebschlicht/music/ /mnt/nas.pi/userdata/sebastian/music
    /data/sebschlicht/pictures/ /mnt/nas.pi/userdata/sebastian/pictures
    /data/sebschlicht/scripts/ /mnt/nas.pi/userdata/sebastian/scripts
    /data/sebschlicht/videos/ /mnt/nas.pi/userdata/sebastian/videos

Using this mapping file, *NB* will push the content of `/data/sebschlicht/documents` to `/mnt/nas.pi/userdata/sebastian/documents` and thus to the mounted Samba share.
And so on.

Now we have to add our mapping file to the *NB* configuration:

**~/.nb/samba.config**:

    NB_MAPPING_FILE=~/.nb/samba.map
    NB_MOUNTPOINT=/mnt/nas.pi
    NB_SAMBA_USER=sebastian

Finally activate the config.

    ln -s ~/.nb/samba.config ~/.nb/backup.config

That's it.
The next time the user logs into his account and backups haven't been made for a day, *NB* will push our directories to their respective remote location on *pi* via SSH using the user's SSH key.

## Related

* [NAS Setup Instructions](nas-setup.md)
