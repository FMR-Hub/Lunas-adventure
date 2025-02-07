#!/bin/bash
set -euo pipefail

# Prüfen, ob das Skript als root ausgeführt wird (für den Kopiervorgang)
if [ "$EUID" -ne 0 ]; then
  echo "Bitte führe dieses Skript als root aus (z.B. mit sudo)."
  exit 1
fi

# Zielverzeichnis (in der Regel ist /usr/local/bin im PATH)
TARGET_DIR="/usr/local/bin"
TARGET_NAME="SUCS"

# Kopiere das Skript in das Zielverzeichnis
cp SUCS.sh "$TARGET_DIR/$TARGET_NAME"
chmod +x "$TARGET_DIR/$TARGET_NAME"

echo -e "\e[32mInstallation abgeschlossen! Du kannst jetzt 'SUCS' von der Kommandozeile ausführen.\e[0m"

echo -e "\e[34mDieses Repository enthält **SUCS**(*:S:sh,:U:ser,:C:reation,:S:cript*) ein Bash-Skript, das die Erstellung eines neuen Systembenutzers vereinfacht. Dabei wird der Benutzer ausschließlich über SSH-Key-Authentifizierung eingerichtet – inklusive Fail2Ban-Integration zum Schutz vor Brute-Force-Angriffen.\e[0m"

echo -e "\e[34mThis repository contains SUCS (:S:sh, :U:ser, :C:reation, :S:cript), a Bash script that simplifies the creation of a new system user. The user is set up exclusively with SSH key authentication, including Fail2Ban integration for protection against brute-force attacks.\e[0m"

echo -e "\e[33m~~~\n  ____  _    _  ____  ____\n / ___|| |  | |/ ___|/ ___|\n \\___ \\| |  | | |    \\___ \\ \n  ___) | |__| | |___  ___) |\n |____/ \\____/ \\____||____/\n~~~\e[0m"

echo -e "\e[32mUm einen Benutzer zu erstellen (z.B. um einem Dienstleister, externen Mitarbeiter o.ä. Zugriff zu geben) kannst du den Walkthrough wählen. Dafür musst du nur 'SUCS' eingeben. Oder du bist dir sicher, alles zu wissen und willst Zeit sparen, dann:\e[0m"

echo -e "\e[31mSUCS username \"ssh Key\"\e[0m"

echo -e "\e[32mDer SSH-Key sollte wie üblich formatiert werden. Erlaubt sind nur RSA und ED25519 Keys. Du kannst die Ausgabe von PuttyGen nutzen.\e[0m"
