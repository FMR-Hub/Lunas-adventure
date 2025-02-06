#!/bin/bash

set -euo pipefail

# Verzeichnis für das Skript und die Logs erstellen
SCRIPT_DIR="/Lunas-adventure/SSH/UCS/scripts"
LOG_DIR="/Lunas-adventure/SSH/UCS/logs"

mkdir -p "$SCRIPT_DIR"
mkdir -p "$LOG_DIR"

LOGFILE="$LOG_DIR/user_creation.log"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

# Sicherstellen, dass das Skript als root ausgeführt wird
if [ "$EUID" -ne 0 ]; then 
  log "Fehler: Bitte dieses Skript als root ausführen."
  exit 1
fi

log "Skript gestartet."

# Eingabevalidierung für den Benutzernamen
validate_username() {
  if [[ ! "$1" =~ ^[a-z_][a-z0-9_-]{2,31}$ ]]; then
    log "Fehler: Ungültiger Benutzername. Nur Kleinbuchstaben, Zahlen, Unterstriche und Bindestriche sind erlaubt."
    exit 1
  fi
}

# SSH Key Validierung
validate_ssh_key() {
  if [[ ! "$1" =~ ^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256)\s.+$ ]]; then
    log "Fehler: Ungültiger SSH Public Key."
    exit 1
  fi
}

# Argumente prüfen
if [ -n "${1:-}" ]; then
  username="$1"
  validate_username "$username"
  log "Benutzername über Argument übergeben: $username"
else
  read -p "Geben Sie den Benutzernamen ein: " username
  validate_username "$username"
  log "Benutzername eingegeben: $username"
fi

# SSH Public Key prüfen
if [ -n "${2:-}" ]; then
  sshkey="$2"
  validate_ssh_key "$sshkey"
  log "SSH Public Key über Argument übergeben."
else
  read -p "Fügen Sie den SSH Public Key ein: " sshkey
  validate_ssh_key "$sshkey"
  log "SSH Public Key eingegeben."
fi

# Prüfen, ob der Benutzer bereits existiert
if id "$username" &>/dev/null; then
  log "Fehler: Der Benutzer '$username' existiert bereits."
  exit 1
fi

# Benutzer erstellen
if useradd -m -s /usr/sbin/nologin "$username"; then
  log "Benutzer '$username' wurde erstellt."
else
  log "Fehler: Benutzer '$username' konnte nicht erstellt werden."
  exit 1
fi

# Passwort deaktivieren
if passwd -l "$username"; then
  log "Passwort für '$username' wurde deaktiviert."
else
  log "Fehler: Passwort für '$username' konnte nicht deaktiviert werden."
  exit 1
fi

# SSH-Verzeichnis erstellen
if mkdir -p "/home/$username/.ssh" && chmod 700 "/home/$username/.ssh"; then
  log "SSH-Verzeichnis für '$username' erstellt."
else
  log "Fehler: SSH-Verzeichnis konnte nicht erstellt werden."
  exit 1
fi

# SSH Public Key hinzufügen
if echo "$sshkey" >> "/home/$username/.ssh/authorized_keys" && chmod 600 "/home/$username/.ssh/authorized_keys" && chown -R "$username:$username" "/home/$username/.ssh"; then
  log "SSH Public Key für '$username' hinzugefügt."
else
  log "Fehler: SSH Public Key konnte nicht hinzugefügt werden."
  exit 1
fi

# Validierung, dass der Benutzer wirklich existiert
if id "$username" &>/dev/null; then
  log "Validierung erfolgreich: Der Benutzer '$username' existiert." 
else
  log "Fehler: Der Benutzer '$username' existiert nicht."
  exit 1
fi

# Fail2Ban prüfen und aktivieren
if ! command -v fail2ban-client &> /dev/null; then
  log "Fail2Ban ist nicht installiert. Installation wird gestartet."
  if apt update && apt install -y fail2ban; then
    log "Fail2Ban wurde installiert."
  else
    log "Fehler: Fail2Ban konnte nicht installiert werden."
    exit 1
  fi
else
  log "Fail2Ban ist bereits installiert."
fi

# Fail2Ban Service starten und aktivieren
if systemctl enable fail2ban && systemctl start fail2ban; then
  if systemctl is-active --quiet fail2ban; then
    log "Fail2Ban wurde erfolgreich gestartet und aktiviert."
  else
    log "Fehler: Fail2Ban konnte nicht gestartet werden."
    exit 1
  fi
else
  log "Fehler: Fail2Ban konnte nicht aktiviert werden."
  exit 1
fi

log "Skript erfolgreich abgeschlossen."
