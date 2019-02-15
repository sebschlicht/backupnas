#!/bin/sh
# Shell script to install the backup script.
QUIET=false

# Echoes an error message to stderr.
fc_error () {
  if [ "$QUIET" = false ]; then
    >&2 echo -e "[ERROR] $1"
  fi
}
# Echoes a warning to stderr.
fc_warn () {
  if [ "$QUIET" = false ]; then
    >&2 echo -e "[WARN] $1"
  fi
}
# Echoes an info message to stdout.
fc_info () {
  if [ "$QUIET" = false ]; then
    echo -e "[INFO] $1"
  fi
}

fc_anacron () {
  # create user configuration directory
  USER_DCFG=~/etc
  if [ ! -d "$USER_DCFG" ]; then
    if ! mkdir "$USER_DCFG"; then
      printf 'Failed to create user configuration directory "%s"!' "$USER_DCFG"
      exit 1
    fi
  fi
  
  # create user anacrontab
  ANATAB=anacrontab
  USER_ANATAB="$USER_DCFG"/anacrontab
  if [ ! -f "$USER_ANATAB" ]; then
    cp "$ANATAB" "$USER_ANATAB"
  else
    ANAENT=$( tail -1 "$ANATAB" )
    if grep -q "$USER_ANATAB" -e "$ANAENT"; then
      fc_info 'Skipping existing anacrontab entry.'
    else
      fc_info 'Appending entry to existing user anacrontab.'
      echo "$ANAENT" >> "$USER_ANATAB"
    fi
  fi

  # create anacron spool directory
  USER_ANASPOOL=~/var/spool/anacron
  if [ ! -d "$USER_ANASPOOL" ]; then
    if ! mkdir -p "$USER_ANASPOOL"; then
      printf 'Failed to create anacron spool directory "%s"!' "$USER_ANASPOOL"
      exit 1
    fi
  fi
  
  # run user anacron on login
  PROF=.profile
  USER_PROFILE=~/.profile
  if [ ! -f "$USER_PROFILE" ]; then
    cp "$PROF" "$USER_PROFILE"
  else
    PROFENT=$( cat "$PROF" )
    if grep -q "$USER_PROFILE" -e "$PROFENT"; then
      fc_info 'Skipping existing user profile entry.'
    else
      fc_info 'Appending entry to existing user profile.'
      echo "$PROFENT" >> "$USER_PROFILE"
    fi
  fi
}

# install backup script to /usr/local/bin
BACKUPNAS=backupnas.sh
USER_BACKUPNAS=/usr/local/bin/backupnas.sh
sudo cp "$BACKUPNAS" "$USER_BACKUPNAS"
sudo chmod 755 "$USER_BACKUPNAS"

# copy example configuration files to configuration folder
NBEXCFG=config-examples
USER_NBCFG=~/.nb
USER_NBEXCFG="$USER_NBCFG"/examples
if [ ! -d "$USER_NBEXCFG" ]; then
  mkdir -p "$USER_NBEXCFG"
fi
cp "$NBEXCFG"/* "$USER_NBEXCFG"

# create user anacrontab calling the backup script
fc_anacron
