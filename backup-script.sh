#!/bin/bash

###############################################################################################
#####                                   BACKUP SCRIPT                                     #####
#####                                    BY IONUT OJICA                                   #####
#####                                     IONUTOJICA.RO                                   #####
###############################################################################################


# Inspiration from:
# https://github.com/PAPAMICA/Backup-Script
# https://forums.koozali.org/index.php?topic=53562.0


###############################################################################################
#####                                GENERAL CONFIGURATION                                #####
###############################################################################################

SOURCE="/srv/dev-disk-by-uuid-$(blkid -s UUID -o value /dev/sdX)/OMV" # Source folder to backup // replace /dev/sdX with your disk identifier
DESTINATION='kDrive:/Backup' # Folder on kDrive where to store backups
OLD='kDrive:/Old'            # Folder on kDrive where to store old versions
VERBOSE='-v'                 # Add more v's for more verbosity: -v = info, -vv = debug
VERSIONS=5                   # Number of backup versions to keep on cloud
LOG='/var/log/rclone.log'    # Log file
SPEED_LIMIT='5M'             # Speed limit for upload
RETRIES='3'                  # Number of retries for each rclone command
RETRIES_SLEEP='10s'          # Sleep time between retries
SCRIPT_NAME='BackupScript'


###############################################################################################
#####                                 KDRIVE CONFIGURATION                                #####
###############################################################################################

kd_user=''   # Your Infomaniak's mail
kd_pass=''   # App's password : https://manager.infomaniak.com/v3/profile/application-password
kd_folder='' # Exemple : 'https://12345678.connect.kdrive.infomaniak.com' : https://www.infomaniak.com/en/support/faq/2409/connect-to-kdrive-via-webdav


###############################################################################################
#####                              NOTIFICATION CONFIGURATION                             #####
###############################################################################################

# email address of the admin, that will receive the emails when error occurs
TO_EMAIL='admin@'       # eg: admin@example.com

# which email address will send the emails
FROM_EMAIL='install@'   # eg: install@example.com
# server and port to connect trough SMTP
FROM_SERVER_PORT=':587' # eg: example.com:587
# username and password for the SMTP account
FROM_USER='install@'    # eg: install@example.com
FROM_PASS=''            # eg: MfE4KrGf%fH7PsW2$


###############################################################################################
#####                                  show_info function                                 #####
###############################################################################################

function show_info() {
  echo "[$(date +%Y-%m-%d_%H:%M:%S)]  ${SCRIPT_NAME}  ${1}"
}


###############################################################################################
#####                                  CHECK IF --dry-run                                 #####
###############################################################################################

if [[ "$*" =~ '--dry-run' ]]; then
  DRY='echo ['$(date +%Y-%m-%d_%H:%M:%S)']--${SCRIPT_NAME}--🚧--DRY RUN : [ '
  DRY2=' ]'
  DRY_RUN='yes'
else
  DRY=''
  DRY2=''
  DRY_RUN='no'
fi


###############################################################################################
#####                                  CHECK IF --output                                  #####
###############################################################################################

if [[ ! "$*" =~ '--output' ]]; then
  # Check if the log file is writable (or can be created)
  if ! touch "$LOG" &> /dev/null; then
    show_info "❌  ERROR: Cannot write to log file: $LOG"
    show_info '🛑  Please run the script as root or ensure write access.'
    exit 1
  fi

  # Redirect all output to the log file
  exec &>> "$LOG"
fi


###############################################################################################
#####                           PREVENT MULTIPLE SCRIPT INSTANCES                         #####
###############################################################################################

SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_NAME=$(basename "$SCRIPT_PATH")
LOCKFILE="/tmp/${SCRIPT_NAME%.sh}.lock"

# Check if the script is already running
if [ -f "$LOCKFILE" ]; then
  old_pid=$(cat "$LOCKFILE")
  if [ -d "/proc/$old_pid" ]; then
    show_info "❌  ERROR: Script is already running with PID $old_pid."
    show_info '🛑  Exiting to prevent multiple instances.'
    exit 1
  else
    show_info '⚠️  Stale lock found. Cleaning up...'
    rm -f "$LOCKFILE"
  fi
fi

# Create new lockfile with current PID
echo $$ > "$LOCKFILE"
trap "rm -f $LOCKFILE; exit" INT TERM EXIT


###############################################################################################
#####                                 INSTALL REQUIREMENTS                                #####
###############################################################################################

if [[ "$*" =~ "--install" ]]; then
  apt update
  apt upgrade
  DEBIAN_FRONTEND=noninteractive apt -yq install sendemail
  DEBIAN_FRONTEND=noninteractive apt -yq install curl
  curl https://rclone.org/install.sh | sudo bash
  show_info '✅  All requirements are installed.'
  echo ''
  printf '=%.0s' {1..100}
  echo ''
}


###############################################################################################
#####                             Sending errors over email                               #####
###############################################################################################

function Send-Error-over-Email {
  local log_extract="/tmp/${SCRIPT_NAME}.log"
  local lines=1000

  # Extract last $lines lines from main log file
  if [ -f "$LOG" ]; then
    tail -n "$lines" "$LOG" > "$log_extract"
  else
    echo "[No log file found at $LOG]" > "$log_extract"
  fi

  email_subject="Error on OMV ${SCRIPT_NAME} on $(date +'%Y-%m-%d %H:%M')"
  email_content=$(cat <<EOL
Hello,

there is an error on your OMV server, ${SCRIPT_NAME}, on $(date +'%Y-%m-%d %H:%M') .
${1}

Please check the attached log extract (${lines} last lines).

Have a great day!
The automated ${SCRIPT_NAME} created by
Ionut Ojica

EOL
)

  sendemail -f "${FROM_EMAIL}" -s "${FROM_SERVER_PORT}" -xu "${FROM_USER}" -xp "${FROM_PASS}" -t "${TO_EMAIL}" -m "${email_content}" -a "${log_extract}" -u "${email_subject}" -o message-charset=utf-8 >/dev/null

  if [ $? -eq 0 ]; then
    show_info "✅  Email '${email_subject}' sent to ${TO_EMAIL}."
  else
    show_info "❌  ERROR : The email '${email_subject}' was NOT sent to ${TO_EMAIL}."
  fi
  
  rm -f "$log_extract"
}


###############################################################################################
#####                           CREATE RCLONE CONFIG FOR KDRIVE                           #####
###############################################################################################

function Create-Rclone-Config-kDrive {
  RCLONE_CHECK_KDRIVE=$(rclone config show | grep kDrive)
  if [ -n "$RCLONE_CHECK_KDRIVE" ]; then
    show_info '🌀  kDrive config already exist.'
  else
    show_info '🌀  Create kDrive config for rclone.'
    $DRY rclone config create kDrive webdav url "$kd_folder" vendor other user "$kd_user" $DRY2
    $DRY rclone config password kDrive pass "$kd_pass" $DRY2
    if [[ $DRY_RUN == 'yes' ]]; then
      $DRY Create Rclone config for kDrive $DRY2
    else
      RCLONE_CHECK_KDRIVE=$(rclone config show | grep kDrive)
      if [ -n "$RCLONE_CHECK_KDRIVE" ]; then
        show_info '✅  kDrive config created for rclone.'
      else
        show_info '❌  ERROR : kDrive config is not created, please check that !'
        Send-Error-over-Email '❌  ERROR : kDrive config is not created, please check that !'
        exit 1
      fi
    fi
  fi
  echo ''
  printf '=%.0s' {1..100}
  echo ''
}


###############################################################################################
#####                             CHECK IF LOCAL SOURCE IS VALID                          #####
###############################################################################################

function Check-Local-Source {
  show_info "🧪  Check local source: $SOURCE"

  if [ ! -d "$SOURCE" ]; then
    show_info "❌  ERROR: Source folder does not exist: $SOURCE"
    show_info '🛑  It is possible that HDD is disconected. Exiting.'
    Send-Error-over-Email '🛑  It is possible that HDD is disconected. Exiting.'
    exit 1
  fi

  num_files=$(find "$SOURCE" -type f ! -path '*/.*' | wc -l)
  if [ "$num_files" -eq 0 ]; then
    show_info '⚠️  WARNING: Source folder exist but it is empty.'
    show_info '❌  Possible that the HDD is damaged. Exiting.'
    Send-Error-over-Email '❌  Possible that the HDD is damaged. Exiting.'
    exit 1
  fi

  show_info '✅  Local source found.'
  echo ''
}


###############################################################################################
#####                                 PURGE OLDEST VERSION                                #####
###############################################################################################

function Purge-Oldest-Version {
  show_info "🌀   Purge oldest version ${VERSION} from kDrive started."
  if rclone lsd "${OLD}${VERSION}" > /dev/null 2>&1; then
    $DRY nice rclone purge "${OLD}${VERSION}" \
      ${VERBOSE} \
      --retries ${RETRIES} \
      --retries-sleep ${RETRIES_SLEEP} \
      $DRY2

    status=$?
    if test $status -eq 0; then
      show_info "✅  Oldest version ${VERSION} purged from kDrive."
    else
      show_info '❌  ERROR : A problem was encountered during the purge from kDrive.'
    fi
  else
    show_info "✅  Oldest version ${VERSION} not found on kDrive."
  fi
  echo ''
  printf '=%.0s' {1..100}
  echo ''
}


###############################################################################################
#####                  RENAME OLD VERSIONS, MAKE ROOM FOR A NEW VERSION                   #####
###############################################################################################

function Rename-Old-Versions {
  show_info '🌀   Rename old versions on kDrive started.'
  while [ $VERSION -gt 1 ]; do
    (( OLDV=$VERSION-1 ))
    if rclone lsd "${OLD}${OLDV}" > /dev/null 2>&1; then
      $DRY nice rclone move "${OLD}${OLDV}" "${OLD}${VERSION}" \
        ${VERBOSE} \
        --retries ${RETRIES} \
        --retries-sleep ${RETRIES_SLEEP} \
        $DRY2

      status=$?
      if test $status -eq 0; then
        show_info "✅  Version ${OLDV} renamed to ${VERSION} on kDrive."
      else
        show_info "❌  ERROR : A problem was encountered during the rename of Version ${OLDV} to ${VERSION} on kDrive."
      fi
    else
      show_info "✅  Version ${OLDV} not found on kDrive."
    fi
    (( VERSION = $OLDV ))
  done
  echo ''
  printf '=%.0s' {1..100}
  echo ''
}


###############################################################################################
#####                                    SEND TO KDRIVE                                   #####
###############################################################################################

function Send-to-kDrive {
  show_info '🌀   Send to kDrive started.'
  $DRY nice rclone sync "${SOURCE}" "${DESTINATION}" \
    --bwlimit ${SPEED_LIMIT} \
    --fast-list \
    --track-renames \
    --track-renames-strategy size \
    --check-first \
    --delete-after \
    --backup-dir "${OLD}1" \
    ${VERBOSE} \
    --skip-links \
    --transfers 1 \
    --retries ${RETRIES} \
    --retries-sleep ${RETRIES_SLEEP} \
    $DRY2

  status=$?
  if test $status -eq 0; then
    show_info '✅  Files are uploaded to kDrive.'
  else
    show_info '❌  ERROR : A problem was encountered during the upload to kDrive.'
    Send-Error-over-Email '❌  ERROR : A problem was encountered during the upload to kDrive.'
  fi
  echo ''
  printf '=%.0s' {1..100}
  echo ''
}


###############################################################################################
#####                                      EXECUTION                                      #####
###############################################################################################

START_TIME=$(date +%s)

Create-Rclone-Config-kDrive

Check-Local-Source

VERSION=$VERSIONS

Purge-Oldest-Version

Rename-Old-Versions

Send-to-kDrive

# Clean up lockfile
rm -f "$LOCKFILE"

END_TIME=$(date +%s)
RUN_TIME=$((END_TIME-START_TIME))
RUN_TIME_H=$(eval "echo $(date -ud "@$RUN_TIME" +'$((%s/3600/24)) days %H hours %M minutes %S seconds')")

show_info "✅  Finished in $RUN_TIME_H."
echo ''
printf '=%.0s' {1..100}
echo ''
