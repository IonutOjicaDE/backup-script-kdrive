
![Backup Script](https://send.papamica.fr/f.php?h=3Ms9ymej&p=1)

[![en](https://img.shields.io/badge/lang-en-red.svg)](https://github.com/PAPAMICA/Backup-Script/blob/master/README.md)
# Prezentare
BackupScript este un script bash care îți permite să faci backup unui server sau unei mașini Linux direct în kDrive-ul Infomaniak.

# Cerințe preliminare
La prima rulare folosește `--install` pentru ca scriptul să poată instala cerințele necesare pentru a rula (curl și rclone):
```sh
./backup-script.sh --install
```

# Configurare
Trebuie să personalizezi următoarele linii în fișierul script `backup-script.sh`:

Configurează calea folderului de backup:
```sh
20  SOURCE="/srv/dev-disk-by-uuid-$(blkid -s UUID -o value /dev/sdX)" # Folderul sursă pentru backup // înlocuiește /dev/sdX cu identificatorul discului tău
```

Configurează folderul de destinație pe kDrive pentru Backup și, de asemenea, pentru fișierele vechi:
```sh
21 DESTINATION="kDrive:/Backup" # Folderul pe kDrive unde se vor stoca backup-urile
22 OLD="kDrive:/Old"            # Folderul pe kDrive unde se vor stoca versiunile vechi
```

Configurează câte versiuni de backup să fie păstrate pe cloud, înainte ca fișierele să fie complet șterse de script (aceste fișiere pot fi încă disponibile din backup-ul kDrive și după alte 60 de zile vor fi complet șterse; te rugăm să consulți kDrive pentru perioada exactă de păstrare după ce fișierele sunt șterse):
```sh
24 VERSIONS=16                  # Numărul de versiuni de backup de păstrat pe cloud
```

## kDrive
Introdu credențialele tale kDrive:
```sh
34 kd_user="" # Email-ul tău Infomaniak
35 kd_pass="" # Parola aplicației: https://manager.infomaniak.com/v3/profile/application-password
36 kd_folder="" # Exemplu: "https://12345678.connect.kdrive.infomaniak.com" : https://www.infomaniak.com/en/support/faq/2409/connect-to-kdrive-via-webdav
```

# Utilizare
Clonează scriptul pe sistemul tău:
```sh
git clone https://github.com/IonutOjicaDE/backup-script-kdrive
```
Accesează folderul:
```sh
cd backup-script-kdrive
```
Editează fișierul `backup-script.sh` cu setările tale:
```sh
nano backup-script.sh
```
Rulează scriptul:
```sh
./backup-script.sh
```

## Cronjob
Pornește backup-ul în fiecare duminică la ora 01:00
```sh
crontab -e
00 01 * * 0 /your-folder/backup-script-kdrive/backup-script.sh
```

## Setările disponibile
### Simulare
Cu `--dry-run` poți previzualiza ce va face scriptul înainte de a-l rula. Acest lucru este foarte bun pentru prima rulare.
```sh
./backup-script.sh --dry-run
```
### Afișare în shell
Cu `--output` poți vedea toate ieșirile în linia de comandă și nimic nu va fi scris în fișierul de log. Acest lucru este foarte bun pentru prima rulare.
```sh
./backup-script.sh --dry-run --output
```
### Instalarea cerințelor
Cu `--install` poți instala cerințele necesare pentru ca scriptul să ruleze (curl și rclone). Acest lucru este foarte bun pentru prima rulare.
```sh
./backup-script.sh --dry-run --output --install
```

🍓☕ Dacă munca mea ți-a fost de folos, nu ezita să-mi oferi un lapte cu căpșuni 😃

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/ionutojica)
