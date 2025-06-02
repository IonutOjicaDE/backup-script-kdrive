
![Backup Script](https://send.papamica.fr/f.php?h=3Ms9ymej&p=1)

[![en](https://img.shields.io/badge/lang-en-red.svg)](https://github.com/IonutOjicaDE/backup-script-kdrive/blob/master/README.md)

# Prezentare
*BackupScript* este un script bash care îți permite să faci backup unui server sau al unei mașini Linux direct în kDrive-ul Infomaniak. *RestoreScript* este, de asemenea, un script bash care îți permite să restaurezi cel mai recent backup din kDrive pe serverul local.

# Cerințe preliminare
La prima rulare folosește `--install` pentru ca scriptul să poată instala cerințele necesare pentru a rula (curl și rclone):
```sh
./backup-script.sh --install
```
sau
```sh
./restore-script.sh --install
```

# Configurarea `backup-script.sh`
Trebuie să personalizezi următoarele linii în fișierul script `backup-script.sh`:

Configurează calea folderului de backup:
```sh
SOURCE="/srv/dev-disk-by-uuid-$(blkid -s UUID -o value /dev/sdX)" # Folderul sursă pentru backup // înlocuiește /dev/sdX cu identificatorul discului tău
```

Configurează folderul de destinație pe kDrive pentru Backup și, de asemenea, pentru fișierele vechi:
```sh
DESTINATION='kDrive:/Backup' # Folderul pe kDrive unde se vor stoca backup-urile
OLD='kDrive:/Old'            # Folderul pe kDrive unde se vor stoca versiunile vechi
```

Folosește dosarul `Upload-directly-to-kDrive` din `DESTINATION` pentru a copia fișiere direct în kDrive și ulterior să le ai disponibile și local. Aceste fișiere vor fi copiate pe discul tău local în dosarul `Uploaded` înainte ca sincronizarea întregului dosar `DESTINATION` să înceapă.
```sh
DEST_UPLOAD="${DESTINATION}/Upload-directly-to-kDrive"  # Dosarul de pe kDrive unde pot fi copiate fișiere direct și vor fi copiate pe discul local
SOURCE_UPLOADED="${SOURCE}/Uploaded" # Dosarul de pe discul local unde vor fi descărcate fișierele din dosarul Upload-directly-to-kDrive din kDrive
```

Configurează câte versiuni de backup să fie păstrate pe cloud, înainte ca fișierele să fie complet șterse de script (aceste fișiere pot fi încă disponibile din backup-ul kDrive și după alte 60 de zile vor fi complet șterse; te rugăm să consulți kDrive pentru perioada exactă de păstrare după ce fișierele sunt șterse):
```sh
VERSIONS=5                   # Numărul de versiuni de backup de păstrat pe cloud
```

## kDrive
Introdu credențialele tale kDrive:
```sh
kd_user=''   # Email-ul tău Infomaniak
kd_pass=''   # Parola aplicației: https://manager.infomaniak.com/v3/profile/application-password
kd_folder='' # Exemplu: "https://12345678.connect.kdrive.infomaniak.com" : https://www.infomaniak.com/en/support/faq/2409/connect-to-kdrive-via-webdav
```

## Cont email pentru notificări
În caz de erori, va fi trimis un email. Introdu adresa de email care va primi notificările, precum și credențialele SFTP ale adresei de email de la care vor fi trimise emailurile:
```sh
# adresa de email a administratorului, care va primi emailurile când apar erori
TO_EMAIL='admin@'       # ex: admin@example.com

# adresa de email care va trimite emailurile
FROM_EMAIL='install@'   # ex: install@example.com
# serverul și portul pentru conectare SMTP
FROM_SERVER_PORT=':587' # ex: example.com:587
# utilizatorul și parola pentru contul SMTP
FROM_USER='install@'    # ex: install@example.com
FROM_PASS=''            # ex: MfE4KrGf%fH7PsW2$
```

# Configurarea `restore-script.sh`
Poți copia majoritatea liniilor de configurare din `backup-script.sh`.

Atenție să introduci corect `SOURCE` și `DESTINATION`. La final, destinația va fi identică cu sursa. Sursa va rămâne intactă. Destinația va fi modificată, fără notificări sau avertismente suplimentare. Toate fișierele modificate sau șterse vor fi mutate în dosarul `OLD`.

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
