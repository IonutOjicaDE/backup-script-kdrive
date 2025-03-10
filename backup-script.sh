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


SOURCE="/srv/dev-disk-by-uuid-$(blkid -s UUID -o value /dev/sdX)" # Source folder to backup // replace /dev/sdX with your disk identifier
DESTINATION="kDrive:/Backup" # Folder on kDrive where to store backups
OLD="kDrive:/Old"            # Folder on kDrive where to store old versions
VERBOSE="-v"                 # Add more v's for more verbosity: -v = info, -vv = debug
VERSIONS=16                  # Number of backup versions to keep on cloud
LOG="/var/log/rclone.log"    # Local log file
RETRIES="3"                  # Number of retries for each rclone command
RETRIES_SLEEP="10s"          # Sleep time between retries


###############################################################################################
#####                                 KDRIVE CONFIGURATION                                #####
###############################################################################################

kd_user="" # Your Infomaniak's mail
kd_pass="" # App's password : https://manager.infomaniak.com/v3/profile/application-password
kd_folder="" # Exemple : "https://12345678.connect.kdrive.infomaniak.com" : https://www.infomaniak.com/en/support/faq/2409/connect-to-kdrive-via-webdav


###############################################################################################
#####                                  CHECK IF --dry-run                                 #####
###############################################################################################
if [[ "$*" =~ "--dry-run" ]]; then
  DRY='echo ['$(date +%Y-%m-%d_%H:%M:%S)']---BackupScript---🚧---DRY RUN : [ '
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
  exec &>> ${LOG}
fi

###############################################################################################
#####                                 INSTALL REQUIREMENTS                                #####
###############################################################################################

if [[ "$*" =~ "--install" ]]; then
  apt update
  apt upgrade
  apt install -y curl
  curl https://rclone.org/install.sh | sudo bash
  echo "[$(date +%Y-%m-%d_%H:%M:%S)]   BackupScript   ✅  All requirements are installed."
  echo ""
  printf '=%.0s' {1..100}
  echo ""
fi


###############################################################################################
#####                           CREATE RCLONE CONFIG FOR KDRIVE                           #####
###############################################################################################

function Create-Rclone-Config-kDrive {
  RCLONE_CHECK_KDRIVE=$(rclone config show | grep kDrive)
  if [ -n "$RCLONE_CHECK_KDRIVE" ]; then
    echo "[$(date +%Y-%m-%d_%H:%M:%S)]   BackupScript   🌀   kDrive config already exist."
  else
    echo "[$(date +%Y-%m-%d_%H:%M:%S)]   BackupScript   🌀   Create kDrive config for rclone."
    $DRY rclone config create kDrive webdav url "$kd_folder" vendor other user "$kd_user" $DRY2
    $DRY rclone config password kDrive pass "$kd_pass" $DRY2
    if [[ $DRY_RUN == "yes" ]]; then
      $DRY Create Rclone config for kDrive $DRY2
    else
      RCLONE_CHECK_KDRIVE=$(rclone config show | grep kDrive)
      if [ -n "$RCLONE_CHECK_KDRIVE" ]; then
        echo "[$(date +%Y-%m-%d_%H:%M:%S)]   BackupScript   ✅   kDrive config created for rclone."
      else
        echo "[$(date +%Y-%m-%d_%H:%M:%S)]   BackupScript   ❌   ERROR : kDrive config didn't created, please check that !"
        exit
      fi
    fi
  fi
  echo ""
  printf '=%.0s' {1..100}
  echo ""
}


###############################################################################################
#####                                 PURGE OLDEST VERSION                                #####
###############################################################################################

function Purge-Oldest-Version {
  echo "[$(date +%Y-%m-%d_%H:%M:%S)]   BackupScript   🌀   Purge oldest version ${VERSION} from kDrive started."
  if rclone lsd "${OLD}${VERSION}" > /dev/null 2>&1; then
    $DRY nice rclone purge "${OLD}${VERSION}" ${VERBOSE} --retries $RETRIES --retries-sleep $RETRIES_SLEEP $DRY2
    status=$?
    if test $status -eq 0; then
      BACKUP_STATUS=$(echo "$BACKUP_STATUS 🟢 kDrive")
      ZB_BACKUP_STATUS=$(echo "$ZB_BACKUP_STATUS kDrive")
      echo "[$(date +%Y-%m-%d_%H:%M:%S)]   BackupScript   ✅   Oldest version ${VERSION} purged from kDrive."
    else
      BACKUP_STATUS=$(echo "$BACKUP_STATUS 🔴 kDrive")
      echo "[$(date +%Y-%m-%d_%H:%M:%S)]   BackupScript   ❌   ERROR : A problem was encountered during the purge from kDrive."
      ((BACKUP_ERROS++))
    fi
  else
    echo "[$(date +%Y-%m-%d_%H:%M:%S)]   BackupScript   ✅   Oldest version ${VERSION} not found on kDrive."
  fi
  echo ""
  printf '=%.0s' {1..100}
  echo ""
}


###############################################################################################
#####                  RENAME OLD VERSIONS, MAKE ROOM FOR A NEW VERSION                   #####
###############################################################################################

function Rename-Old-Versions {
  echo "[$(date +%Y-%m-%d_%H:%M:%S)]   BackupScript   🌀   Rename old versions on kDrive started."
  while [ $VERSION -gt 1 ]; do
    (( OLDV=$VERSION-1 ))
    if rclone lsd "${OLD}${OLDV}" > /dev/null 2>&1; then
      $DRY nice rclone move "${OLD}${OLDV}" "${OLD}${VERSION}" ${VERBOSE} --retries $RETRIES --retries-sleep $RETRIES_SLEEP $DRY2
      status=$?
      if test $status -eq 0; then
        BACKUP_STATUS=$(echo "$BACKUP_STATUS 🟢 kDrive")
        ZB_BACKUP_STATUS=$(echo "$ZB_BACKUP_STATUS kDrive")
        echo "[$(date +%Y-%m-%d_%H:%M:%S)]   BackupScript   ✅   Version ${OLDV} renamed to ${VERSION} on kDrive."
      else
        BACKUP_STATUS=$(echo "$BACKUP_STATUS 🔴 kDrive")
        echo "[$(date +%Y-%m-%d_%H:%M:%S)]   BackupScript   ❌   ERROR : A problem was encountered during the rename of Version ${OLDV} to ${VERSION} on kDrive."
        ((BACKUP_ERROS++))
      fi
    else
      echo "[$(date +%Y-%m-%d_%H:%M:%S)]   BackupScript   ✅   Version ${OLDV} not found on kDrive."
    fi
    (( VERSION = $OLDV ))
  done
  echo ""
  printf '=%.0s' {1..100}
  echo ""
}


###############################################################################################
#####                                    SEND TO KDRIVE                                   #####
###############################################################################################

function Send-to-kDrive {
  echo "[$(date +%Y-%m-%d_%H:%M:%S)]   BackupScript   🌀   Send to kDrive started."
  $DRY nice rclone sync "${SOURCE}" "${DESTINATION}" --bwlimit 3M:off --fast-list --track-renames --track-renames-strategy size --check-first --delete-after --backup-dir "${OLD}1" ${VERBOSE} --skip-links --retries $RETRIES --retries-sleep $RETRIES_SLEEP $DRY2
  status=$?
  if test $status -eq 0; then
    BACKUP_STATUS=$(echo "$BACKUP_STATUS 🟢 kDrive")
    ZB_BACKUP_STATUS=$(echo "$ZB_BACKUP_STATUS kDrive")
    echo "[$(date +%Y-%m-%d_%H:%M:%S)]   BackupScript   ✅   Files are uploaded to kDrive."
  else
    BACKUP_STATUS=$(echo "$BACKUP_STATUS 🔴 kDrive")
    echo "[$(date +%Y-%m-%d_%H:%M:%S)]   BackupScript   ❌   ERROR : A problem was encountered during the upload to kDrive."
    ((BACKUP_ERROS++))
  fi
  echo ""
  printf '=%.0s' {1..100}
  echo ""
}


###############################################################################################
#####                                      EXECUTION                                      #####
###############################################################################################

START_TIME=$(date +%s)

Create-Rclone-Config-kDrive

VERSION=$VERSIONS

Purge-Oldest-Version

Rename-Old-Versions

Send-to-kDrive

END_TIME=$(date +%s)
RUN_TIME=$((END_TIME-START_TIME))
RUN_TIME_H=$(eval "echo $(date -ud "@$RUN_TIME" +'$((%s/3600/24)) days %H hours %M minutes %S seconds')")

echo "[$(date +%Y-%m-%d_%H:%M:%S)]   BackupScript   ✅   Finished in $RUN_TIME_H."
echo ""
printf '=%.0s' {1..100}
echo ""
