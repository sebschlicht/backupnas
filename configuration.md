# Configuration

*NB* supports up to three types of configuration files:
1. *NB* configuration files (`.config`)
1. [optional] mapping files (`.map`)
1. [optional] exclusion files (`.ignore`)

## *NB* Configuration

The *NB* configuration is the main configuration file.

Here you can specify which mapping file and/or exclusion file to use, if you want to use them.  
You can also specify a mountpoint that should be mounted prior to backing up files.

The following table lists all options that are available.

Option | Default Value | Description
------ | ------------- | -----------
NB_MAPPING_FILE | none | Path to the mapping file. If you don't specify a mapping file, you have to pass both the source and the destination path to the script directly.
NB_EXCLUSION_FILE | none | Path to the exclusion file.
NB_MOUNTPOINT | none | Mount point to be mounted prior to the backup.
NB_SAMBA_USER | none | Samba user to use when mounting a Samba share mount point. The user will be prompted for the password. If you don't want to have to enter a password, specify the credentials in the *fstab* entry instead.
NB_SSH_REMOTE | none   | Remote machine to backup files to via SSH.
NB_SSH_USERNAME | none | Name of the remote user to login to via SSH.
NB_DRY_RUN | false     | Dry run flag. If set to `true` no changes will be performed. A summary of changes (that weren't made) will still be printed.

## Mapping File

The mapping file allows to map local directories, that should be backed up, to their backup destination.
Thus it's used to backup multiple directories.

Each line in the mapping file maps a local directory to its (remote) backup destination.
For example, the first entry in the SSH example mapping file (`ssh.map`)

    /data/sebschlicht/documents/ /mnt/nas/main/backup/sebastian/documents

tells *NB* to backup all the files in `/data/sebschlicht/documents` to the backup location `/mnt/nas/main/backup/sebastian/documents`.

By default both the source and destination paths are local paths.
However, if you specify a remote machine as in the SSH example, the destination path is a path on the remote machine.

## Exclusion File

The exclusion file allows to exclude files from the backup.
Each line in the file represents a filename pattern, matching files will be excluded from the backup.

This is a built-in feature of *rsync*.
See `man rsync` for details.
