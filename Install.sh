#!/bin/bash
set -euo pipefail

# Prüfen, ob das Skript als root ausgeführt wird (für den Kopiervorgang)
if [ "$EUID" -ne 0 ]; then
  echo "Bitte führe dieses Skript als root aus (z.B. mit sudo)."
  exit 1
fi

# Zielverzeichnis (in der Regel ist /usr/local/bin im PATH)
TARGET_DIR="/usr/local/bin"
TARGET_NAME="ucsfr"

# Kopiere das Skript in das Zielverzeichnis
cp ucsfr.sh "$TARGET_DIR/$TARGET_NAME"
chmod +x "$TARGET_DIR/$TARGET_NAME"

echo "Installation abgeschlossen! Du kannst jetzt 'ucsfr' von der Kommandozeile ausführen."
