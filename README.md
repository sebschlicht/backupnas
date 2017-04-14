# NAS Backup Script

The NAS backup script (*NB*) can be used to automate the process of backing up multiple directories or files to a local or remote location.

*NB* supports to backup files to:
* another local directory
* a Samba share that *NB* mounts automatically
* a remote machine via SSH (SSH key authentification)

*NB* pushes user-defined locations to their declared destinations on a daily basis, by defining an *Anacron* job.
These locations and their destinations can be defined in a single mapping file.

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
If you want to elaborate on what's possible first, head to the [configuration wiki page](wiki/configuration).

1. Copy the example configuration files to the configuration folder and make the SSH example configuration your active *NB* configuration.

       cd ~/.nb/examples/
       cp ssh.* ../
       cp backup.ignore ../
       ln -s ../ssh.config ../backup.config
       
1. Edit the SSH remote and username in the `ssh.config`.  
   Please note that *NB* uses the user's default SSH key to connect via SSH.

1. Edit the `ssh.map` file to match your needs.
   Each line maps a local directory to its backup location.  
   For example, the first line in the SSH example file pushes the local folder `/data/sebschlicht/documents` to `/mnt/nas/main/backup/sebastian/documents` on the backup system.

## Compatibility

*NB* has been tested on Ubuntu 15.04 and Ubuntu 16.04.

Due to how *NB* detects the SSH authentication socket, only Ubuntu *may* be supported for now, you simply have to try it out.

If you want to use *NB* on a distro where it doesn't work yet, please [create an issue](issues) naming your distro and attach the log file output of the failed backup process.
