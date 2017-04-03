#!/bin/bash
readonly PROGRAM_NAME='backupnas'
readonly PROGRAM_TITLE='NAS Backup Script'
QUIET=false
CFGPREFIX='NB'

# variable initialization section
LOCKPATH=/tmp/backnas.lock
PROFILE_PATH=
SOURCE_PATH=
TARGET_PATH=

# Prints the usage of the script in case of using the help command.
printUsage () {
  # TODO
  echo 'Usage: '"$PROGRAM_NAME"' SYNTAX'
  echo
  echo 'EXPLAIN GENERAL USAGE'
  echo
  echo 'Options:'
  echo '-h, --help	Display this help message and exit.'
  echo 'OPTIONS'
}

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

# Parses the startup arguments into variables.
parseArguments () {
  while [[ $# > 0 ]]; do
    key="$1"
    case $key in
      # help
      -h|--help)
      printUsage
      exit 0
      ;;
      # quiet mode
      -q|--quiet)
      QUIET=true
      ;;
      # profile
      -p|--profile)
      PROFILE_PATH="$2"
      shift
      ;;
      # unknown option
      -*)
      fc_error "Unknown option '$key'!"
      return 2
      ;;
      # parameter
      *)
      if ! handleParameter "$1"; then
        fc_error 'Too many arguments!'
        return 2
      fi
      ;;
    esac
    shift
  done
  
  # check for valid number of parameters
  if [ -z "$PROFILE_PATH" ]; then
    if [ -z "$SOURCE_PATH" ] || [ -z "$TARGET_PATH" ]; then
      fc_error 'Too few arguments!'
      return 2
    fi
  fi
  
  # load prefixed variables from profile
  if [ -n "$PROFILE_PATH" ]; then
    if [ ! -f "$PROFILE_PATH" ]; then
      fc_error "The profile '$PROFILE_PATH' does not exist!"
      return 3
    elif ! load_config "$PROFILE_PATH" "$CFGPREFIX"; then
      return 3
    fi
  fi
  # override loaded variables that have been passed directly
  local VARIABLES=( 'SOURCE_PATH' 'TARGET_PATH' )
  override_config "$VARIABLES" "$CFGPREFIX"

  # check validity of parameter values
  if ! validateParams; then
    return 3
  fi
}

# Handles the parameters (arguments that aren't an option) and checks if their count is valid.
handleParameter () {
  # 1. parameter: source path
  if [ -z "$SOURCE_PATH" ]; then
    SOURCE_PATH="$1"
  # 2. parameter: target path
  elif [ -z "$TARGET_PATH" ]; then
    TARGET_PATH="$1"
  else
    # too many parameters
    return 1
  fi
}

# Validates the parameter values.
validateParams () {
  # validate profile (existence-check)
  if [ -n "$PROFILE_PATH" ]; then
    if ([ -z "$NB_SOURCE_PATH" ] || [ -z "$NB_TARGET_PATH" ]) && [ -z "$NB_MAPPING_FILE" ]; then
      fc_error "The profile must either define source and target paths or the path to a mapping file!"
      return 1
    elif [ -n "$NB_MAPPING_FILE" ] && [ ! -f "$NB_MAPPING_FILE" ]; then
      fc_error "The mapping file '$NB_MAPPING_FILE' does not exist!"
      return 1
    elif [ -n "$NB_EXCLUSION_FILE" ] && [ ! -f "$NB_EXCLUSION_FILE" ]; then
      fc_error "The exclusion file '$NB_EXCLUSION_FILE' does not exist!"
      return 1
    fi
  fi
  
  # validate source and target paths (if specified)
  if [ -n "$NB_SOURCE_PATH" ] && [ ! -e "$NB_SOURCE_PATH" ]; then
    fc_error "The source path '$NB_SOURCE_PATH' does not exist!"
    return 1
  elif [ -n "$NB_TARGET_PATH" ] && [ ! -e "$NB_TARGET_PATH" ]; then
    fc_error "The target path '$NB_TARGET_PATH' does not exist!"
    return 1
  fi
}

# Loads a configuration file (bash) if it only includes variable assignments.
# Supports empty lines, comments and prefix filtering.
#
# Parameters:
# 1. file path
# 2. (optional) variable prefix
load_config () {
  local CFGPATH="$1"
  local PREFIX="$2"
  if [ -n "$PREFIX" ]; then
    local PREFIX="$PREFIX"_
  fi
  local PATTERN="^$|^#|^${PREFIX}[^ ]*=[^;\$\`]*$"

  # TODO dependency egrep
  local VIOLATIONS=$(egrep -v "$PATTERN" "$CFGPATH")
  if [ -n "$VIOLATIONS" ]; then
    # malformed configuration file
    local ERROR_MSG='The configuration file is malformed. Only comments and variable declarations are allowed'
    if [ -n "$PREFIX" ]; then
      local ERROR_MSG="$ERROR_MSG. All variables must start with '$PREFIX'"
    fi
    fc_error "$ERROR_MSG."
    fc_error "The following line(s) violate(s) this rule:\n\n${VIOLATIONS}\n"
    return 1
  fi
  source "$CFGPATH"
}

# Overrides parameters loaded from a configuration file with values specified by the user directly.
override_config () {
  local VARIABLES="$1"
  local PREFIX="$2"
  for VAR in "$VARIABLES"; do
    local VALUE="${!VAR}"
    if [ -n "$VALUE" ]; then
      eval "${PREFIX}_$VAR"=\$VALUE
    fi
  done
}

###############################
# main script function section
###############################

# Checks whether a mount point is mounted or not.
fc_is_mounted () {
  if mount | grep "$1" >/dev/null; then
    return 0
  fi
  return 1
}

# Mounts the user-specified mount point. If a Samba user is specified, the user is prompted for the password.
fc_mount () {
  fc_info "Mounting '$NB_MOUNTPOINT'..."
  if [ -n "$NB_SAMBA_USER" ]; then
    # prompt user to enter Samba account password
    local PASSWD=$(zenity --title='SMBB Samba User Authentication' --width=315 --entry --hide-text --text="Please enter the password of your Samba user '$NB_SAMBA_USER', in order to backup your system:")
    if [ -z "$PASSWD" ]; then
      return 1
    fi

    # use the given credentials to mount the Samba share
    # TODO dependency: cifs
    mount -t cifs -o user,noauto,username="$NB_SAMBA_USER",passwd="$PASSWD" "$NB_MOUNTPOINT"
  else
    # mount should have everything it needs in fstab
    mount "$NB_MOUNTPOINT"
  fi
  return $(fc_is_mounted "$NB_MOUNTPOINT")
}

# Pushes a directory structure from one location to another.
# Supports NB_EXCLUSION_FILE and NB_DRY_RUN.
fc_push () {
  local SOURCE="$1"
  local TARGET="$2"
  local ARGS=()
  # output: human readable, change summary, progress bar
  ARGS+=('-h' '-i' '--progress')
  # transfer: archive files, no space-splitting, skip files if target newer, compress
  ARGS+=('-a' '-s' '-u' '-z')
  # exclusion file
  if [ -n "$NB_EXCLUSION_FILE" ]; then
    ARGS+=("--exclude-from=$NB_EXCLUSION_FILE")
  fi
  # dry run
  if [ "$NB_DRY_RUN" = true ]; then
    fc_warn 'THIS IS A DRY RUN - NO CHANGES WILL BE PERFORMED!'
    ARGS+=('-n')
  fi

  if [ -n "$NB_SAMBA_USER" ]; then
    # disable permissions if backup destination is Samba share
    ARGS+=('--no-p' "$SOURCE" "$TARGET")
  elif [ -n "$NB_SSH_REMOTE" ]; then
    ARGS+=('-e' 'ssh' "$SOURCE")

    # specify SSH remote (and username)
    if [ -n "$NB_SSH_USERNAME" ]; then
      ARGS+=("$NB_SSH_USERNAME@$NB_SSH_REMOTE:$TARGET")
    else
      ARGS+=("$NB_SSH_REMOTE:$TARGET")
    fi
  fi
  #TODO log rsync/program output to daily/instance log file
  rsync "${ARGS[@]}"
}

##############
# entry point
##############
parseArguments "$@"
SUCCESS=$?
if [ "$SUCCESS" -ne 0 ]; then
  fc_info "Use the '-h' switch for help."
  exit "$SUCCESS"
fi

# execute main script functions
## check for running instances and trap lock file deletion
if [ -f "$LOCKPATH" ]; then
  fc_error "$PROGRAM_NAME is already running, exiting."
  exit 4
fi
trap 'rm -f "$LOCKPATH"; exit $?' INT TERM EXIT

## mount Samba share if necessary
UNMOUNT=false
if [ -n "$NB_MOUNTPOINT" ]; then
  # check if not already mounted
  if fc_is_mounted "$NB_MOUNTPOINT"; then
    fc_info "'$NB_MOUNTPOINT' is already mounted."
  # check if mounting failed
  elif ! fc_mount "$NB_MOUNTPOINT"; then
    fc_error "Failed to mount '$NB_MOUNTPOINT'!"
    exit 6
  else
    UNMOUNT=true
  fi
fi

## backup files
if [ -n "$NB_MAPPING_FILE" ]; then
  # backup all mapping entries
  grep -v -e '^$' -e '^#' "$NB_MAPPING_FILE" | while read from to; do
    fc_push "$from" "$to"
  done
else
  # backup single directory
  fc_push "$NB_SOURCE" "$NB_TARGET"
fi

## unmount Samba share if mounted during execution
if [ "$NB_UNMOUNT" = true ]; then
  umount "$NB_MOUNTPOINT"
fi

## remove lock file and trapping
rm -f "$LOCKPATH"
trap - INT TERM EXIT
