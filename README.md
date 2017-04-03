# NAS Backup Script

The NAS backup script (*NB*) can be used to automate the process of backing up files to a local or remote location.
Using *rsync* under the hood, it supports backing up files via SSH and to remote NAS systems (Samba shares).

*NB* pushes user-defined locations to their declared destinations on a daily basis.
These locations and their destinations are defined in a single mapping file.

Newer files will never be overridden and no files will be removed at the backup location.
However, this behavior can be configured.

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

## Configuration

There are three types of configuration files that the NAS backup script supports.
This section gives you a quick overview, see [configuration](configuration.md) for more information and available configuration options.

1. `.config` files: Specifies general configuration options, such as modes and locations.
1. `.map` files: Lists directories that are to be pushed and maps them to their backup destination.
1. `.ignore` files: Lists patterns that are used by `rsync` to exclude files from the backup process. This exclusion file applies to all mappings defined.

### SSH Setup

TODO

### Samba Setup

TODO

## Related

* [NAS Setup Instructions](nas-setup.md)
