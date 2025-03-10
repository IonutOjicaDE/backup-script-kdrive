
![Backup Script](https://send.papamica.fr/f.php?h=3Ms9ymej&p=1)

[![ro](https://img.shields.io/badge/lang-ro-blue.svg)](https://github.com/IonutOjicaDE/backup-script-kdrive/blob/master/README_RO.md)

# Presentation
BackupScript is a bash script that allows you to backup a Linux server or machine directly in Infomaniak's kDrive.

# Prerequisites
At the first run use `--install` so the script can install the requirements needed for the script to run (curl and rclone):
```sh
./backup-script.sh --install
```

# Configuration
You must customize following lines in the script file `backup-script.sh` :

Configure the path of the folder to backup:
```sh
20  SOURCE="/srv/dev-disk-by-uuid-$(blkid -s UUID -o value /dev/sdX)" # Source folder to backup // replace /dev/sdX with your disk identifier
```

Configure the destination folder on kdrive for the Backup and also for the old files:
```sh
21 DESTINATION="kDrive:/Backup" # Folder on kDrive where to store backups
22 OLD="kDrive:/Old"            # Folder on kDrive where to store old versions
```

Configure how many backup versions to keep still on the cloud, before the files will be completely deleted by the script (these files may be still be available from kdrive backup and after another 60 days will be completelly deleted; please consult kdrive for the exact keeping period after the files are deleted):
```sh
24 VERSIONS=16                  # Number of backup versions to keep on cloud
```

## kDrive
Enter your kdrive credentials:
```sh
34 kd_user="" # Your Infomaniak's mail
35 kd_pass="" # App's password : https://manager.infomaniak.com/v3/profile/application-password
36 kd_folder="" # Exemple : "https://12345678.connect.kdrive.infomaniak.com" : https://www.infomaniak.com/en/support/faq/2409/connect-to-kdrive-via-webdav
```

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
