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
      printf 'Failed to create user configuration directory "%s"!' $USER_DCFG
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
    if grep "$USER_ANATAB" -e "$ANAENT" &>/dev/null; then
      fc_info 'Skipping existing anacrontab entry.'
    else
      fc_info 'Appending entry to existing user anacrontab.'
      echo "$ANAENT" >> "$USER_ANATAB"
    fi
  fi
  
  # run user anacron on login
  PROF=.profile
  USER_PROFILE=~/.profile
  if [ ! -f "$USER_PROFILE" ]; then
    cp "$PROF" "$USER_PROFILE"
  else
    PROFENT=$( cat "$PROF" )
    # TODO grep returns true if one of the lines has been found
    if grep "$USER_PROFILE" -e "$PROFENT" &>/dev/null; then
      fc_info 'Skipping existing user profile entry.'
    else
      fc_info 'Appending entry to existing user profile.'
      echo "$PROFENT" >> "$USER_PROFILE"
    fi
  fi
}

# TODO install backup script to /usr/local/bin
# TODO use default backup config path in anacrontab OR ask user for config file paths

# create user anacrontab calling the backup script
fc_anacron
