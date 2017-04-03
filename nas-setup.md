# NAS Setup Instructions

This document describes the process of installing and configuring a Samba server to be used as a NAS in a home network.  
In contrast to common instruction sets out there, this document puts a focus on security.

We start from a clean filesystem that multiple users want to backup their data to, securely.
All those files should be owned by the respective user on filesystem level.
A Samba share should make the files available to the respective user.
We call these shares private.

Some files, however, do not (strongly) belong to a particular user.
Think of digitalized series, drivers or holiday pictures.
A Samba share should make the files available to all authenticated users.
We call these shares semi-public.

Though you might not want the exact setup (e.g. private shares to be writeable or semi-public shares) these instructions may help you to get things started.

## Installation

To install the Samba server simply use `apt-get`.

    sudo apt-get install samba

## NTFS

If you want to put the NAS on a hard disk with NTFS, you can use the following *fstab* entry as a *starting point*.

    UUID=...   /mnt/nas/main ntfs-3g windows_names,permissions,defaults,auto,locale=de_DE.utf8

## Configuration

This section describes how to set up the Samba server.

User files will be owned by the respective user.
NSemi-public files will be owned by a virtual NAS user.

Subsections will point at the Samba config.  
The Samba configuration file is located at:
`/etc/samba/smb.conf`

1. At first, create a directory where the whole NAS resides in, e.g. `/nas`.  
   We call this directory the NAS root.
    
       sudo mkdir /nas
   
   If the directory isn't by default, let it be owned by root and apply 755 permissions:
   
       sudo chown root:root /nas
       sudo chmod 755 /nas

1. Create the virtual NAS user, e.g. `nas`, that owns the semi-public files (both a system user with disabled login and a Samba user).

       adduser nas --disabled-login
       sudo smbpasswd -a nas

1. [Create the semi-public shares](#create-semi-public-share) you need.

1. For each user that's going to use your backup system, follow the steps of [adding a user](#add-user).

### Add User

1. Create the user on the system. This is necessary, as Samba users map to system users. It is essential to the permission management when using Samba.

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
   * `writeable` activates write access for valid users. On a backup system this *may not* be desired! 

1. Restart the Samba server to apply the config changes.

       sudo service smbd restart

### Create Semi-Public Share

To create a share that all authenticated users can access, follow the following steps.

1. Create a folder in the NAS root, where the semi-public data should be stored and set appropriate permissions.

       sudo mkdir <path>
       sudo chown -R nas:nas <path>
       sudo chmod 777 <path>

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

## Resources

* [RaspberryPi NAS Guide](http://www.welzels.de/blog/projekte/raspberry-pi/low-budget-nas-mit-einem-raspberry-pi/pi-nas-datei-server-und-zubehor/)
* [RaspberryPi Samba Installation Guide](https://jankarres.de/2013/11/raspberry-pi-samba-server-installieren/)
* [Samba Documentation: Users and Security](https://www.samba.org/samba/docs/using_samba/ch09.html)
