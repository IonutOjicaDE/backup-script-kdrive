
![Backup Script](https://send.papamica.fr/f.php?h=3Ms9ymej&p=1)

[![ro](https://img.shields.io/badge/lang-ro-blue.svg)](https://github.com/IonutOjicaDE/backup-script-kdrive/blob/master/README_RO.md)

# Presentation
*BackupScript* is a bash script that allows you to backup a Linux server or machine directly in Infomaniak's kDrive. *RestoreScript* is also a bash script that allows you to restore the latest backup from kDrive to your local machine.

# Prerequisites
At the first run use `--install` so the script can install the requirements needed for the script to run (sendemail, curl, rclone):
```sh
./backup-script.sh --install
```
or
```sh
./restore-script.sh --install
```

# Configuration of `backup-script.sh`
You must customize following lines in the script file `backup-script.sh` :

Configure the path of the folder to backup:
```sh
SOURCE="/srv/dev-disk-by-uuid-$(blkid -s UUID -o value /dev/sdX)/OMV" # Source folder to backup // replace /dev/sdX with your disk identifier
```

Configure the destination folder on kdrive for the Backup and also for the old files:
```sh
DESTINATION='kDrive:/Backup' # Folder on kDrive where to store backups
OLD='kDrive:/Old'            # Folder on kDrive where to store old versions
```

You use the `Upload-directly-to-kDrive` folder inside `DESTINATION` to upload files directly to your kDrive and to have them also local. These files will be copied to your local drive in `Uploaded` before the synchronization of the whole `DESTINATION` folder will be started.
```sh
DEST_UPLOAD="${DESTINATION}/Upload-directly-to-kDrive"  # Folder on kDrive where files can be directly uploaded and will be fetched to local source
SOURCE_UPLOADED="${SOURCE}/Uploaded" # Local folder where files will be downloaded from kDrive Upload-directly-to-kDrive folder
```

Configure how many backup versions to keep still on the cloud, before the files will be completely deleted by the script (these files may be still be available from kdrive backup and after another 60 days will be completelly deleted; please consult kdrive for the exact keeping period after the files are deleted):
```sh
VERSIONS=5                   # Number of backup versions to keep on cloud
```

## kDrive
Enter your kdrive credentials:
```sh
kd_user=''   # Your Infomaniak's mail
kd_pass=''   # App's password : https://manager.infomaniak.com/v3/profile/application-password
kd_folder='' # Exemple : 'https://12345678.connect.kdrive.infomaniak.com' : https://www.infomaniak.com/en/support/faq/2409/connect-to-kdrive-via-webdav
```

## Email account for notification
In case of errors, an email will be sent. Enter the email address that will receive the emails, and the email SFTP credentials of the email address from which the emails will be sent:
```sh
# email address of the admin, that will receive the emails when error occurs
TO_EMAIL='admin@'       # eg: admin@example.com

# which email address will send the emails
FROM_EMAIL='install@'   # eg: install@example.com
# server and port to connect trough SMTP
FROM_SERVER_PORT=':587' # eg: example.com:587
# username and password for the SMTP account
FROM_USER='install@'    # eg: install@example.com
FROM_PASS=''            # eg: MfE4KrGf%fH7PsW2$
```

# Configuration of `restore-script.sh`
You can copy paste most of the configuration lines from the `backup-script.sh`.

Please pay attention to enter the right `SOURCE` and the right `DESTINATION`. At the end, destination will match source. Source will be intact. Destination will be altered, without extra notification or warning. All modified or deleted files will be moved to `OLD` folder.

# Usage
Clone the script on your machine:
```sh
git clone https://github.com/IonutOjicaDE/backup-script-kdrive
```
Go to the folder:
```sh
cd backup-script-kdrive
```
Edit the file `backup-script.sh` with your settings:
```sh
nano backup-script.sh
```
Run the script:
```sh
./backup-script.sh
```

## Cronjob
Start backup every Sunday at 01h
```sh
crontab -e
00 01 * * 0 /your-folder/backup-script-kdrive/backup-script.sh
```

## The available settings
### Dry run
With  `--dry-run` you can preview what the script will do before you run it. This is in any case very good for the first run.
```sh
./backup-script.sh --dry-run
```
### Output in the shell
With `--output` you can see all output on the command line and nothing will be written in the log file. This is in any case very good for the first run.
```sh
./backup-script.sh --dry-run --output
```
### Install the requirements
With `--install` you can install the requirements needed for the script to run (curl and rclone). This is in any case very good for the first run.
```sh
./backup-script.sh --dry-run --output --install
```

🍓☕ If my work has been useful to you, do not hesitate to offer me a strawberry milk 😃

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/ionutojica)
