#----------------WIP-WIP-WIP-WIP-WIP--------------#

# SUCS – Das Benutzerverwaltungsskript / The User Management Script

~~~
  ____  _    _  ____  ____
 / ___|| |  | |/ ___|/ ___|
 \___ \| |  | | |    \___ \ 
  ___) | |__| | |___  ___) |
 |____/ \____/ \____||____/
~~~

Dieses Repository enthält **SUCS**(*:S:sh,:U:ser,:C:reation,:S:cript*) ein Bash-Skript, das die Erstellung eines neuen Systembenutzers vereinfacht. Dabei wird der Benutzer ausschließlich über SSH-Key-Authentifizierung eingerichtet – inklusive Fail2Ban-Integration zum Schutz vor Brute-Force-Angriffen.

This repository contains SUCS (:S:sh, :U:ser, :C:reation, :S:cript), a Bash script that simplifies the creation of a new system user. The user is set up exclusively with SSH key authentication, including Fail2Ban integration for protection against brute-force attacks.


TBD Key Assistant.
Deutsch:
Die geplante Funktionalität ermöglicht es, einen Schlüssel aus einer Auswahl sicherer Schlüsseltypen auszuwählen. Zur Gewährleistung maximaler Sicherheit und Funktionalität wird die Validierung der Schlüssel in zwei Schritten durchgeführt: Zunächst überprüft das Skript das Syntaktische Format des Schlüssels, um sicherzustellen, dass er den erforderlichen Standards entspricht und das der Nutzer keinen Fehler gemacht hat. Anschließend wird der Schlüssel wenn möglich in einem tatsächlichen Test geprüft bei dem eine Testverbindung mit dem User hergestellt wird um seine Funktionalität zu verifizieren.
Zusätzlich sieht der User wie die Formatierung des ausgewählten Schlüssels aussehen soll um Fehler zu verhindern.

Englisch:
The planned functionality allows users to select a key from a set of secure key types. To ensure maximum security, the validation process consists of two steps: First, the script checks the key format to confirm it meets the required standards. Then, the key undergoes an actual test to verify its functionality.



**Repository:** [https://github.com/FMR-Hub/Lunas-adventure.git](https://github.com/FMR-Hub/Lunas-adventure.git)

---

## Deutsch

### Beschreibung

**SUCS** ist ein Bash-Skript, das die Erstellung eines neuen Systembenutzers automatisiert. Der neu angelegte Benutzer erhält ausschließlich Zugang über SSH-Key-Authentifizierung. Zusätzlich wird Fail2Ban integriert, um das System vor Brute-Force-Angriffen zu schützen und so die Systemsicherheit zu erhöhen.

### Voraussetzungen

- **Betriebssystem:** Linux (Ubuntu, Debian oder vergleichbare Distributionen)
- **Software:** Git, Bash
- **Benutzerrechte:** Sudo-Rechte (für die Installation)

### Installation und Einrichtung

1. **Repository klonen:**

   Öffne ein Terminal und führe folgenden Befehl aus:

   ~~~bash
   git clone https://github.com/FMR-Hub/Lunas-adventure.git && cd Lunas-adventure
   ~~~

2. **Installationsskript ausführen:**

   Im Repository findest du das Installationsskript `install.sh`. Führe es mit Sudo-Rechten aus:

   ~~~bash
   sudo ./install.sh
   ~~~

   Das Skript kopiert das Hauptskript (`sucs.sh`) in ein Verzeichnis (z. B. `/usr/local/bin`), das in deinem `PATH` liegt, und macht es ausführbar. Nach erfolgreicher Installation ist **SUCS** systemweit unter dem Befehl `SUCS` verfügbar.

### Nutzung

Nach der Installation startest du **SUCS** einfach über das Terminal:

~~~bash
SUCS
~~~

Folge den Anweisungen, um einen neuen Benutzer anzulegen und den SSH-Schlüssel zu konfigurieren.

### Hinweise

- **One-Liner Installation:**

  Für eine direkte Installation kannst du auch diesen Einzeiler verwenden:

  ~~~bash
  curl -s https://raw.githubusercontent.com/FMR-Hub/Lunas-adventure/master/install.sh | sudo bash
  ~~~

- **Logs:**

  Bei Problemen oder zur Überprüfung der Aktionen schaust du in die generierten Logdateien.

---

## English

### Description

**SUCS** is a Bash script that automates the creation of a new system user with SSH key authentication only. In addition, it integrates Fail2Ban to protect against brute-force attacks, thereby enhancing system security.

### Prerequisites

- **Operating System:** Linux (Ubuntu, Debian, or similar distributions)
- **Software:** Git, Bash
- **Permissions:** Sudo privileges (required for installation)

### Installation and Setup

1. **Clone the Repository:**

   Open a terminal and run:

   ~~~bash
   git clone https://github.com/FMR-Hub/Lunas-adventure.git && cd Lunas-adventure
   ~~~

2. **Run the Installation Script:**

   In the repository, you will find the installation script `install.sh`. Execute it with sudo:

   ~~~bash
   sudo ./install.sh
   ~~~

   The script copies the main script (`sucs.sh`) to a directory (e.g., `/usr/local/bin`) that is in your `PATH` and makes it executable. After installation, **SUCS** is available system-wide as `SUCS`.

### Usage

Once installed, simply start **SUCS** by entering:

~~~bash
SUCS
~~~

Follow the on-screen instructions to create a new user and configure the SSH key.

### Notes

- **One-Liner Installation:**

  For a direct installation, you can also use this one-liner:

  ~~~bash
  curl -s https://raw.githubusercontent.com/FMR-Hub/Lunas-adventure/master/install.sh | sudo bash
  ~~~

- **Logs:**

  In case of issues or to review the actions performed, check the generated log files.