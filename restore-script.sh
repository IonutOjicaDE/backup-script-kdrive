#!/bin/bash

###############################################################################################
#####                                   RESTORE SCRIPT                                    #####
#####                                    BY IONUT OJICA                                   #####
#####                                     IONUTOJICA.RO                                   #####
###############################################################################################


###############################################################################################
#####                                GENERAL CONFIGURATION                                #####
###############################################################################################

SOURCE="kDrive:/Backup"      # Folder on kDrive where the backup is stored
DESTINATION="/srv/dev-disk-by-uuid-$(blkid -s UUID -o value /dev/sdX)/OMV" # Destination local folder to backup // replace /dev/sdX with your disk identifier
VERBOSE="-v"                 # Add more v's for more verbosity: -v = info, -vv = debug
LOG="/var/log/rclone.log"    # Local log file
SPEED_LIMIT="5M"             # Speed limit for upload
RETRIES="3"                  # Number of retries for each rclone command
RETRIES_SLEEP="10s"          # Sleep time between retries
SCRIPT_NAME="RestoreScript"


###############################################################################################
#####                                 KDRIVE CONFIGURATION                                #####
###############################################################################################

kd_user="" # Your Infomaniak's mail
kd_pass="" # App's password : https://manager.infomaniak.com/v3/profile/application-password
kd_folder="" # Exemple : "https://12345678.connect.kdrive.infomaniak.com" : https://www.infomaniak.com/en/support/faq/2409/connect-to-kdrive-via-webdav


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

if [[ "$*" =~ "--dry-run" ]]; then
  DRY='echo ['$(date +%Y-%m-%d_%H:%M:%S)']--${SCRIPT_NAME}--🚧--DRY RUN : [ '
  DRY2=' ]'
  DRY_RUN="yes"
else
  DRY=""
  DRY2=""
  DRY_RUN="no"
fi


###############################################################################################
#####                                  CHECK IF --output                                  #####
###############################################################################################

if [[ ! "$*" =~ "--output" ]]; then
  # Check if the log file is writable (or can be created)
  if ! touch "$LOG" &> /dev/null; then
    show_info "❌  ERROR: Cannot write to log file: $LOG"
    show_info "🛑  Please run the script as root or ensure write access."
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
    show_info "🛑  Exiting to prevent multiple instances."
    exit 1
  else
    show_info "⚠️  Stale lock found. Cleaning up..."
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
  show_info "✅  All requirements are installed."
  echo ""
  printf '=%.0s' {1..100}
  echo ""
fi


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
    show_info "🌀  kDrive config already exist."
  else
    show_info "🌀  Create kDrive config for rclone."
    $DRY rclone config create kDrive webdav url "$kd_folder" vendor other user "$kd_user" $DRY2
    $DRY rclone config password kDrive pass "$kd_pass" $DRY2
    if [[ $DRY_RUN == "yes" ]]; then
      $DRY Create Rclone config for kDrive $DRY2
    else
      RCLONE_CHECK_KDRIVE=$(rclone config show | grep kDrive)
      if [ -n "$RCLONE_CHECK_KDRIVE" ]; then
        show_info "✅  kDrive config created for rclone."
      else
        show_info "❌  ERROR : kDrive config didn't created, please check that !"
        Send-Error-over-Email "❌  ERROR : kDrive config didn't created, please check that !"
        exit 1
      fi
    fi
  fi
  echo ""
  printf '=%.0s' {1..100}
  echo ""
}


###############################################################################################
#####                               RESTORE FROM KDRIVE                                   #####
###############################################################################################

function Restore-from-kDrive {
  show_info "🌀  Restore from kDrive started."

  $DRY nice rclone sync "${SOURCE}" "${DESTINATION}" \
    --bwlimit ${SPEED_LIMIT} \
    --create-empty-src-dirs \
    --fast-list \
    --check-first \
    ${VERBOSE} \
    --skip-links \
    --transfers 1 \
    --retries ${RETRIES} \
    --retries-sleep ${RETRIES_SLEEP} \
    $DRY2 &
  
  RCLONE_PID=$!

  Monitor-Destination-Mount

  wait $RCLONE_PID

  status=$?
  if test $status -eq 0; then
    show_info "✅  Files are downloaded from kDrive."
  else
    show_info "❌  ERROR : A problem was encountered during the download from kDrive."
    Send-Error-over-Email "❌  ERROR : A problem was encountered during the download from kDrive."
  fi
  echo ""
  printf '=%.0s' {1..100}
  echo ""
}


###############################################################################################
#####                          MONITOR DESTINATION MOUNT DURING RESTORE                   #####
###############################################################################################

function Monitor-Destination-Mount {
  local check_interval=60

  while kill -0 "$RCLONE_PID" 2>/dev/null; do
#    if ! findmnt -rno TARGET "$DESTINATION" &>/dev/null; then
#      show_info "❌  ERROR: Destination $DESTINATION is no longer mounted!"
#      show_info "🛑  Terminating rclone process (PID $RCLONE_PID)..."
#      kill -9 "$RCLONE_PID"
#      exit 1
#    fi

    if ! ls "$DESTINATION" &>/dev/null; then
      show_info "❌  ERROR: Destination $DESTINATION is no longer accessible!"
      show_info "🛑  Terminating rclone process (PID $RCLONE_PID)..."
      kill -9 "$RCLONE_PID"
      Send-Error-over-Email "❌  ERROR: Destination $DESTINATION is no longer accessible!"
      exit 1
    fi

    sleep $check_interval
  done
}


###############################################################################################
#####                                      EXECUTION                                      #####
###############################################################################################

START_TIME=$(date +%s)

Create-Rclone-Config-kDrive

Restore-from-kDrive

# Clean up lockfile
rm -f "$LOCKFILE"

END_TIME=$(date +%s)
RUN_TIME=$((END_TIME-START_TIME))
RUN_TIME_H=$(eval "echo $(date -ud "@$RUN_TIME" +'$((%s/3600/24)) days %H hours %M minutes %S seconds')")

show_info "✅  Finished in $RUN_TIME_H."
echo ""
printf '=%.0s' {1..100}
echo ""


###############################################################################################
#####                                     USEFUL STUFF                                    #####
###############################################################################################

# Run with:
# sudo nohup bash /home/pi/restore-script.sh > /home/pi/restore.log 2>&1 &

# Check if the script is running:
# ps aux | grep [r]estore-script.sh
# Output will be something like this:
# root        8329  0.0  0.1   8548  3056 ?        S    11:31   0:00 bash /usr/local/bin/restore-script.sh

# Stop execution of a running script with:
# sudo kill 8329

# Find disk:
# sudo fdisk -l

# Create partition:
# sudo fdisk /dev/sda
# g : new GPT partition table
# n : new partition
# w : write and exit

# Format partition:
# sudo mkfs.ext4 /dev/sda1
