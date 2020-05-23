#!/bin/bash
readonly PROGRAM_NAME='backupnas'
readonly PROGRAM_TITLE='NAS Backup Script'
QUIET=false

readonly DEFAULT_CONFIG_FILE=~/.nb/config
readonly DEFAULT_MAPPING_FILE=~/.nb/mapping
readonly DEFAULT_INCLUDE_FILE=~/.nb/include
readonly DEFAULT_EXCLUDE_FILE=~/.nb/exclude

# variable initialization section
readonly LOCKPATH=~/.nb/lock
DRY_RUN=false
CONFIG_FILE=
MAPPING_FILE=
INCLUDE_FILE=
EXCLUDE_FILE=

# Prints the usage of the script in case of using the help command.
printUsage () {
  echo 'Usage: '"$PROGRAM_NAME"' [OPTIONS] [CONFIG_FILE [MAPPING_FILE]]'
  echo
  echo "$PROGRAM_TITLE"' is a tool to backup your personal data to local or remote locations.'
  echo
  echo "The config file configures the backup destination and provides possibly required credentials. Defaults to '~/.nb/config'."
  echo "The mapping file maps local paths to paths at the backup destination. Defaults to '~/.nb/mapping'"
  echo
  echo 'Options:'
  echo '-h, --help	              Display this help message and exit.'
  echo '-i, --include-file <path> Specify the path to an include file. Local directories matching a pattern specified in the given file will always be included in the backup. Defaults to '\''~/.nb/include'\''. See `man rsync` for details.'
  echo '-e, --exclude-file <path> Specify the path to an exclude file. Local directories matching a pattern specified in the given file will be excluded from the backup. Defaults to '\''~/.nb/exclude'\''. See `man rsync` for details.'
  echo '-n, --dry-run             Perform a dry run. No changes will be made.'
  echo '-q, --quiet               Supress all output.'
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
      # include file
      -i|--include-file)
      INCLUDE_FILE="$2"
      shift
      ;;
      # exclude file
      -e|--exclude-file)
      EXCLUDE_FILE="$2"
      shift
      ;;
      # dry run
      -n|--dry-run)
      DRY_RUN=true
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
  
  # config file: required with default
  if [ -n "$CONFIG_FILE" ]; then
    if [ ! -f "$CONFIG_FILE" ]; then
      fc_error "The configuration file '$CONFIG_FILE' does not exist!"
      return 3
    fi
  elif [ -f "$DEFAULT_CONFIG_FILE" ]; then
    CONFIG_FILE="$DEFAULT_CONFIG_FILE"
  else
    fc_error 'No config file available!'
    return 3
  fi

  # mapping file: required with default
  if [ -n "$MAPPING_FILE" ]; then
    if [ ! -f "$MAPPING_FILE" ]; then
      fc_error "No such mapping file '$MAPPING_FILE'!"
      return 3
    fi
  elif [ -f "$DEFAULT_MAPPING_FILE" ]; then
    MAPPING_FILE="$DEFAULT_MAPPING_FILE"
  else
    fc_error 'No mapping file available!'
    return 3
  fi

  # include file: optional with default
  if [ -n "$INCLUDE_FILE" ]; then
    if [ ! -f "$INCLUDE_FILE" ]; then
      fc_error "No such include file '$INCLUDE_FILE'!"
      return 3
    fi
  elif [ -f "$DEFAULT_INCLUDE_FILE" ]; then
    INCLUDE_FILE="$DEFAULT_INCLUDE_FILE"
  fi

  # exclude file: optional with default
  if [ -n "$EXCLUDE_FILE" ]; then
    if [ ! -f "$EXCLUDE_FILE" ]; then
      fc_error "No such exclude file '$EXCLUDE_FILE'!"
      return 3
    fi
  elif [ -f "$DEFAULT_EXCLUDE_FILE" ]; then
    EXCLUDE_FILE="$DEFAULT_EXCLUDE_FILE"
  fi
}

# Handles the parameters (arguments that aren't an option) and checks if their count is valid.
handleParameter () {
  # 1. parameter: config file
  if [ -z "$CONFIG_FILE" ]; then
    CONFIG_FILE="$1"
  # 2. parameter: mapping file
  elif [ -z "$MAPPING_FILE" ]; then
    MAPPING_FILE="$1"
  else
    # too many parameters
    return 1
  fi
}

###############################
# main script function section
###############################

# Initializes relevant environment variables to unlock the user's SSH key.
fc_init_ssh () {
  #TODO compatibility? test if new bash opened here has SSH_AUTH_SOCK set
  SSH_AUTH_SOCK=$(ls -t1 /run/user/"$UID"/keyring*/ssh | head -n 1)
  export SSH_AUTH_SOCK
}

fc_expand_source () {
  local source="$1"
  eval source="$source"
  if [[ "$source" != */ ]]; then
    source="$source/"
  fi
  echo "$source"
}
fc_expand_target () {
  local target
  target="$1"
  if [ "$target" == "." ]; then
    target=
  fi
  if [[ "$target" != /* ]]; then
    target="${BACKUP_LOCATION%/}/$target"
  fi
  echo "${target%/}"
}

# Pushes a directory structure from one location to another.
# Supports NB_EXCLUSION_FILE and NB_DRY_RUN.
fc_push () {
  local SOURCE=$( fc_expand_source "$1" )
  local TARGET=$( fc_expand_target "$2" )
  local ARGS=()
  fc_info "Backing up '$SOURCE' to '$TARGET':"

  # output: human readable, change summary, progress bar
  ARGS+=('-h' '-i' '--progress')
  # transfer: archive files, no space-splitting, skip files if target newer, compress
  ARGS+=('-a' '-s' '-u' '-z')
  # inclusion file
  if [ -n "$INCLUDE_FILE" ]; then
    ARGS+=("--include-from=$INCLUDE_FILE")
  fi
  # exclusion file
  if [ -n "$EXCLUDE_FILE" ]; then
    ARGS+=("--exclude-from=$EXCLUDE_FILE")
  fi
  # dry run
  if "$DRY_RUN"; then
    fc_warn 'THIS IS A DRY RUN - NO CHANGES WILL BE PERFORMED!'
    ARGS+=('-n')
  fi

  if [ -n "$REMOTE_HOST" ]; then
    ARGS+=('-e' 'ssh' "$SOURCE")

    # connect to ssh-agent
    fc_info "SSH mode enabled, using keys of user '$USER'"
    fc_init_ssh

    # specify SSH remote (and username)
    if [ -n "$REMOTE_USERNAME" ]; then
      ARGS+=("$REMOTE_USERNAME@$REMOTE_HOST:$TARGET")
    else
      ARGS+=("$REMOTE_HOST:$TARGET")
    fi
  fi
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

## load the config file
source "$CONFIG_FILE"

## backup all mapping entries
grep -v -e '^$' -e '^#' "$MAPPING_FILE" | while read from to; do
  fc_push "$from" "$to"
done
fc_info 'Backup process completed.'

## remove lock file and trapping
rm -f "$LOCKPATH"
trap - INT TERM EXIT
