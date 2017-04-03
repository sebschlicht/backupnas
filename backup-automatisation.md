# Backup Automatisation

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

## Anacron in User Mode

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
       1         2      user.backup     /usr/local/bin/backupnas.sh -p ~/.nb/backup.config

1. Call anacron from `~/.profile` to execute the job on each login, if it's due:

       # run anacron in user mode
       /usr/sbin/anacron -s -t ${HOME}/etc/anacrontab -S ${HOME}/var/spool/anacron

   **If your computer** runs for a long period and **doesn't login daily**, this **approach** would be **insufficient**.
   In this case it would be better to create a daily *user cronjob* that calls anacron.

This way the SSH key doesn't have to be unlocked on each SSH command.

### Test User Anacron Jobs

In order to test if the everything is working as expected, run anacron in foreground mode, forcing the execution of jobs right now:

       /usr/sbin/anacron -s -t ${HOME}/etc/anacrontab -S ${HOME}/var/spool/anacron -dfn

## Resources

* [Anacron in User Mode](http://askubuntu.com/questions/235089/how-can-i-run-anacron-in-user-mode)
