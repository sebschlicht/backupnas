#!/bin/bash
# Shell script to install the backup script.

fc_anacron () {
  # create user configuration directory
  USER_DCFG=~/etc
  if [ ! -d "$USER_DCFG" ]; then
    if ! mkdir "$USER_DCFG"; then
      printf '[ERROR] Failed to create user configuration directory "%s"!' "$USER_DCFG"
      exit 1
    fi
  fi
  
  # create user anacrontab or append job
  ANATAB=anacrontab
  USER_ANATAB="$USER_DCFG"/anacrontab
  if [ ! -f "$USER_ANATAB" ]; then
    cp "$ANATAB" "$USER_ANATAB"
  else
    ANAENT=$( tail -1 "$ANATAB" )
    if ! grep -q "$USER_ANATAB" -e "$ANAENT"; then
      echo '[WARN] Appending entry to existing user anacrontab. Please verify that this worked!'
      echo "$ANAENT" >> "$USER_ANATAB"
    fi
  fi

  # create anacron spool directory
  USER_ANASPOOL=~/var/spool/anacron
  if [ ! -d "$USER_ANASPOOL" ]; then
    if ! mkdir -p "$USER_ANASPOOL"; then
      printf '[ERROR] Failed to create anacron spool directory "%s"!' "$USER_ANASPOOL"
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
    if ! grep -q "$USER_PROFILE" -e "$PROFENT"; then
      echo "$PROFENT" >> "$USER_PROFILE"
    fi
  fi
}

NB_USER_BASE=~/.nb
NB_TARGET_BIN=/usr/local/bin/backupnas

# use super user to install backup script to local binaries folder
sudo cp backupnas.sh "$NB_TARGET_BIN"

# create NB directories
mkdir -p "$NB_USER_BASE/logs"

# setup anacrontab scheduler in user mode
fc_anacron

# place default configuration files as examples
NB_USER_EXAMPLES="$NB_USER_BASE/examples"
if [ ! -d "$NB_USER_EXAMPLES" ]; then
  mkdir -p "$NB_USER_EXAMPLES"
fi
cp examples/* "$NB_USER_EXAMPLES/"

# place default configuration files, if no config present
if [ ! -f "$NB_USER_BASE/config" ]; then
  cp examples/* "$NB_USER_BASE/"
else
  echo '[INFO] Existing configuration files left untouched. Find the current default configuration in the examples.'
fi
