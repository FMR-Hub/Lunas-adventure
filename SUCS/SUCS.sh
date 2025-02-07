#!/bin/bash
set -euo pipefail

# Verzeichnis für das Skript und die Logs erstellen
SCRIPT_DIR="/Lunas-adventure/SSH/SUCS/scripts"
LOG_DIR="/Lunas-adventure/SSH/SUCS/logs"

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

# Validierung des SSH Public Keys
validate_ssh_key() {
  local key="$1"
  # Es werden nur die Schlüsseltypen ssh-ed25519 und ssh-rsa unterstützt.
  if [[ "$key" =~ ^(ssh-ed25519|ssh-rsa)[[:space:]]+([A-Za-z0-9+/]+={0,2})([[:space:]].*)?$ ]]; then
    return 0
  else
    return 1
  fi
}

# Interaktive Abfrage und Validierung des SSH Public Keys mit Schlüsselauswahl
prompt_for_valid_ssh_key() {
  local selected_type
  local example_key
  local input_key
  local key_choice

  while true; do
    echo "Bitte wählen Sie den SSH-Schlüsseltyp:"
    echo "  1) ssh-ed25519 (empfohlen)"
    echo "  2) ssh-rsa (4096 Bit)"
    read -rp "Ihre Auswahl (1 oder 2): " key_choice
    case "$key_choice" in
      1)
        selected_type="ssh-ed25519"
        example_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICexamplekeystring user@example.com"
        ;;
      2)
        selected_type="ssh-rsa"
        example_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCexamplekeystring user@example.com"
        ;;
      *)
        echo "Ungültige Auswahl. Bitte wählen Sie 1 oder 2."
        continue
        ;;
    esac

    echo ""
    echo "Ihr ausgewählter SSH-Schlüsseltyp ist: $selected_type"
    echo "Ein gültiger öffentlicher Schlüssel sollte in etwa so aussehen:"
    echo "$example_key"
    echo ""
    read -rp "Bitte fügen Sie Ihren SSH Public Key ein: " input_key

    # Überprüfen, ob der eingegebene Schlüssel mit dem gewählten Typ beginnt
    if [[ "$input_key" != "$selected_type"* ]]; then
      echo "Fehler: Der Schlüssel beginnt nicht mit '$selected_type'. Bitte versuchen Sie es erneut."
      continue
    fi

    # Gesamtvalidierung des Schlüssels
    if validate_ssh_key "$input_key"; then
      echo "$input_key"
      return 0
    else
      echo "Fehler: Der SSH Public Key ist ungültig. Bitte überprüfen Sie den Aufbau:" 
      echo " - Der Schlüsseltyp (z. B. $selected_type)"
      echo " - Den Base64-codierten Teil (nur Buchstaben, Zahlen, '+' und '/' erlaubt, ggf. '=' am Ende)"
      echo "Bitte versuchen Sie es erneut."
      continue
    fi
  done
}

# Benutzername abfragen (als Argument oder interaktiv)
if [ -n "${1:-}" ]; then
  username="$1"
  validate_username "$username"
  log "Benutzername über Argument übergeben: $username"
else
  read -rp "Geben Sie den Benutzernamen ein: " username
  validate_username "$username"
  log "Benutzername eingegeben: $username"
fi

# SSH Public Key abfragen
if [ -n "${2:-}" ]; then
  candidate="$2"
  if validate_ssh_key "$candidate"; then
    sshkey="$candidate"
    log "SSH Public Key über Argument übergeben."
  else
    log "Fehler: Ungültiger SSH Public Key über Argument. Bitte geben Sie ihn erneut ein."
    sshkey=$(prompt_for_valid_ssh_key)
    log "SSH Public Key eingegeben."
  fi
else
  sshkey=$(prompt_for_valid_ssh_key)
  log "SSH Public Key eingegeben."
fi

# Prüfen, ob der Benutzer bereits existiert
if id "$username" &>/dev/null; then
  log "Fehler: Der Benutzer '$username' existiert bereits."
  exit 1
fi

# Benutzer erstellen
if useradd -m -s /bin/bash "$username"; then
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
  log "Heureka! Fail2Ban ist bereits installiert."
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
echo "Heureka! Skript erfolgreich abgeschlossen. Benutzer '$username' wurde mit '$selected_type' erstellt. Validiere wenn möglich den nutzer mit ssh -i ~/Pfad/Zum/Schlüssel '$username'@localhost -p *port_von_ssh* "
