#!/bin/bash
set -euo pipefail

# Verzeichnisse und Log-Datei definieren
SCRIPT_DIR="/Lunas-adventure/SUCS/scripts"
LOG_DIR="/Lunas-adventure/SUCS/logs"
LOGFILE="$LOG_DIR/user_creation.log"

# Benötigte Verzeichnisse erstellen
mkdir -p "$SCRIPT_DIR"
mkdir -p "$LOG_DIR"

#######################################
# Schreibt eine Log-Nachricht in die Log-Datei und an stderr.
# Globals:
#   LOGFILE
# Arguments:
#   Nachricht (String)
# Returns:
#   None
#######################################
log() {
  local message="$1"
  # Log-Nachrichten gehen an stderr, damit sie nicht in stdout landen
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOGFILE" >&2
}

#######################################
# Prüft, ob das Skript als root ausgeführt wird.
#######################################
ensure_root() {
  if [ "$EUID" -ne 0 ]; then
    log "Fehler: Bitte dieses Skript als root ausführen."
    exit 1
  fi
}

#######################################
# Validiert den Benutzernamen.
# Erlaubt sind Kleinbuchstaben, Zahlen, Unterstriche und Bindestriche.
# Arguments:
#   Benutzername
# Returns:
#   0, wenn der Name gültig ist, sonst 1.
#######################################
validate_username() {
  local username="$1"
  if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]{2,31}$ ]]; then
    log "Fehler: Ungültiger Benutzername: $username. Erlaubt sind Kleinbuchstaben, Zahlen, Unterstriche und Bindestriche."
    return 1
  fi
  return 0
}

#######################################
# Liest den Benutzernamen ein (falls nicht als Argument übergeben) und validiert ihn.
# Arguments:
#   Optional: Benutzername als erstes Argument
# Returns:
#   Der reine Benutzername (über stdout)
#######################################
get_username() {
  local username
  if [ -n "${1:-}" ]; then
    username="$1"
    if ! validate_username "$username"; then
      exit 1
    fi
    log "Benutzername über Argument: $username"
  else
    read -rp "Geben Sie den Benutzernamen ein: " username
    if ! validate_username "$username"; then
      exit 1
    fi
    log "Benutzername eingegeben: $username"
  fi
  # Nur der Benutzername wird ausgegeben – Logs landen über stderr!
  echo "$username"
}

#######################################
# Validiert den übergebenen SSH Public Key.
# Akzeptiert Schlüssel, die mit "ssh-ed25519" oder "ssh-rsa" beginnen und einen Base64-Block enthalten.
# Arguments:
#   SSH Key (String)
# Returns:
#   0, wenn der Key gültig ist, sonst 1.
#######################################
validate_ssh_key() {
  local key="$1"
  if [[ "$key" =~ ^(ssh-ed25519|ssh-rsa)[[:space:]]+[A-Za-z0-9+/]+={0,2} ]]; then
    return 0
  else
    return 1
  fi
}

#######################################
# Fragt den SSH Public Key interaktiv ab, bis ein gültiger Key eingegeben wurde.
# Returns:
#   Der gültige SSH Public Key (über stdout)
#######################################
get_ssh_key() {
  local key
  while true; do
    read -rp "Fügen Sie Ihren SSH Public Key ein: " key
    if validate_ssh_key "$key"; then
      log "Gültiger SSH Public Key eingegeben."
      echo "$key"
      return
    else
      echo "Ungültiger SSH Key. Ein Beispiel könnte so aussehen:"
      echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICexamplekeystring user@example.com"
      log "Ungültiger SSH Public Key eingegeben."
    fi
  done
}

#######################################
# Erstellt den Benutzer, richtet das Home-Verzeichnis ein und fügt den SSH Key hinzu.
# Arguments:
#   Benutzername, SSH Key
#######################################
create_user() {
  local username="$1"
  local sshkey="$2"
  local ssh_dir="/home/$username/.ssh"

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

  # SSH-Verzeichnis erstellen und Berechtigungen setzen
  if mkdir -p "$ssh_dir" && chmod 700 "$ssh_dir"; then
    log "SSH-Verzeichnis für '$username' erstellt."
  else
    log "Fehler: SSH-Verzeichnis konnte nicht erstellt werden."
    exit 1
  fi

  # SSH Public Key hinzufügen
  if echo "$sshkey" > "$ssh_dir/authorized_keys" && chmod 600 "$ssh_dir/authorized_keys" && chown -R "$username:$username" "$ssh_dir"; then
    log "SSH Public Key für '$username' hinzugefügt."
  else
    log "Fehler: SSH Public Key konnte nicht hinzugefügt werden."
    exit 1
  fi
}

#######################################
# Installiert und aktiviert Fail2Ban.
#######################################
install_fail2ban() {
  if ! command -v fail2ban-client &>/dev/null; then
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

  if systemctl enable fail2ban && systemctl start fail2ban; then
    if systemctl is-active --quiet fail2ban; then
      log "Fail2Ban wurde erfolgreich gestartet und aktiviert."
    else
      log "Fehler: Fail2Ban ist nicht aktiv."
      exit 1
    fi
  else
    log "Fehler: Fail2Ban konnte nicht aktiviert werden."
    exit 1
  fi
}

#######################################
# Hauptfunktion: Steuert den Ablauf des Skripts.
# Arguments:
#   Optional: Benutzername und SSH Key als Parameter
#######################################
main() {
  ensure_root

  local username sshkey
  username=$(get_username "${1:-}")

  if [ -n "${2:-}" ]; then
    sshkey="$2"
    if ! validate_ssh_key "$sshkey"; then
      log "Der als Argument übergebene SSH Key ist ungültig. Bitte interaktiv eingeben."
      sshkey=$(get_ssh_key)
    else
      log "SSH Key wurde über Argument übergeben."
    fi
  else
    sshkey=$(get_ssh_key)
  fi

  create_user "$username" "$sshkey"
  install_fail2ban

  log "Skript erfolgreich abgeschlossen. Benutzer '$username' wurde erstellt."
  echo "Skript erfolgreich abgeschlossen. Benutzer '$username' wurde erstellt."
}

# Hauptprogramm starten – alle übergebenen Argumente werden weitergereicht
main "$@"
