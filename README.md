# FritzBox 6591 Cable – Custom Firmware mit Freetz-NG

Dieses Repository enthält eine vorkonfigurierte Dev-Container-Umgebung zum Erstellen einer **Custom Firmware** für die **AVM FritzBox 6591 Cable** auf Basis von [Freetz-NG](https://github.com/Freetz-NG/freetz-ng) und dem Docker-Image [pfichtner/freetz](https://github.com/pfichtner/pfichtner-freetz).

---

## Voraussetzungen

| Werkzeug | Hinweis |
|---|---|
| [Docker](https://docs.docker.com/engine/install/) | Engine muss laufen; aktueller Benutzer muss Mitglied der Gruppe `docker` sein |
| [VS Code](https://code.visualstudio.com/) | Ab Version 1.74 |
| [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) | `ms-vscode-remote.remote-containers` |
| Git | Für das Klonen von freetz-ng |
| ≥ 8 GB freier Speicher | Build-Artefakte, Downloads und Toolchain benötigen viel Platz |
| Case-sensitive Dateisystem | Das Verzeichnis, in das freetz-ng ausgecheckt wird, **muss** case-sensitiv sein (Standard auf Linux; auf macOS ggf. APFS-Volume mit `case-sensitive` anlegen) |

---

## Schnellstart mit VS Code Dev Container

### 1. Repository öffnen

```bash
# Falls noch nicht geklont:
git clone <dieses-repo> freetz-workspace
cd freetz-workspace
code .
```

### 2. Im Dev Container öffnen

VS Code zeigt automatisch eine Benachrichtigung an:

> *Folder contains a Dev Container configuration file. Reopen in Container?*

Auf **„Reopen in Container"** klicken – oder über die Command Palette:

```
Ctrl+Shift+P → Dev Containers: Reopen in Container
```

> **Was passiert beim ersten Start:**
> 1. Das Docker-Image `pfichtner/freetz` wird heruntergeladen (~700 MB, einmalig).
> 2. Ein Container wird gestartet; der `builduser` erhält automatisch die UID des Host-Benutzers.
> 3. Das Freetz-NG-Repository wird in `/workspace/freetz-ng` geklont (einmalig, dauert einige Minuten).
> 4. Fehlende Build-Voraussetzungen werden automatisch nachinstalliert.

---

## Firmware erstellen

Alle folgenden Befehle werden im **integrierten Terminal** des Dev Containers ausgeführt.

### 3. In das freetz-ng Verzeichnis wechseln

```bash
cd /workspace/freetz-ng
```

### 4. Firmware konfigurieren

```bash
make menuconfig
```

Ein curses-basiertes Menü öffnet sich. Folgende Einstellungen sind für die **FritzBox 6591 Cable** wichtig:

#### Zielgerät auswählen
```
Firmware → Target → AVM FritzBox 6591 Cable
```

#### Empfohlene Grundkonfiguration
| Kategorie | Einstellung |
|---|---|
| **Target** | `AVM FritzBox 6591 Cable` |
| **Firmware Version** | Passende AVM-Firmware-Version wählen (z. B. `07.57`) |
| **Packages** | Nur benötigte Pakete aktivieren (kleinere Images = stabiler) |
| **Busybox** | Standardmäßig ausreichend; bei Bedarf Applets erweitern |

> **Tipp:** Mit `?` im Menü wird eine Hilfebeschreibung zur aktuell ausgewählten Option angezeigt.

Konfiguration speichern und Menü schließen.

### 5. (Optional) AVM-Firmware-Image herunterladen

Freetz-NG benötigt das originale AVM-Firmware-Image als Basis. Es wird beim Build-Schritt automatisch heruntergeladen, sofern die URL in der Konfiguration hinterlegt ist. Alternativ kann es manuell ins `dl/`-Verzeichnis gelegt werden:

```bash
# Download-Verzeichnis anlegen (falls nicht vorhanden)
mkdir -p /workspace/freetz-ng/dl

# Image manuell hineinkopieren (Name muss exakt dem Konfigurationsnamen entsprechen):
# z. B. fritz.os-06.83-de-6591-Cable.image
cp /pfad/zum/image /workspace/freetz-ng/dl/
```

Das aktuelle Firmware-Image für die FritzBox 6591 Cable ist auf der [AVM-Downloadseite](https://download.avm.de/fritzbox/fritzbox-6591-cable/deutschland/fritz.os/) verfügbar.

### 6. Firmware bauen

```bash
make
```

Der erste Build dauert je nach Hardware **30–90 Minuten**, da die Toolchain und alle Abhängigkeiten kompiliert werden. Folgebuilds sind deutlich schneller.

Das fertige Image liegt anschließend unter:

```
/workspace/freetz-ng/images/
```

---

## Firmware auf die FritzBox flashen

> ⚠️ **Achtung:** Das Flashen einer Custom Firmware kann die Garantie erlöschen lassen und im Fehlerfall die FritzBox unbenutzbar machen. Auf eigene Gefahr!

### Über das AVM-Webinterface (empfohlen)

1. FritzBox-Weboberfläche öffnen: `http://fritz.box`
2. → **System** → **Update** → **Fritz!OS-Datei** → Datei auswählen
3. Das erzeugte `.image`-File aus dem `images/`-Verzeichnis hochladen
4. Update bestätigen und warten bis der Neustart abgeschlossen ist

### Über FTP (Recovery)

Falls die Box nicht mehr über das Webinterface erreichbar ist:

1. FritzBox in den Recovery-Modus versetzen (Recover-Knopf beim Einschalten gedrückt halten)
2. PC mit LAN-Kabel verbinden, statische IP `192.168.178.2` vergeben
3. FTP-Verbindung zu `192.168.178.1` herstellen (User: `adam2`, Pass: `adam2`)
4. Image per FTP übertragen (binär, passive mode)

---

## Alternativer Workflow ohne Dev Container

Falls kein VS Code verwendet wird, kann der Container auch direkt mit Docker gestartet werden:

```bash
# freetz-ng klonen
git clone https://github.com/Freetz-NG/freetz-ng.git
cd freetz-ng

# Interaktive Shell im Build-Container starten
docker run --rm -it \
  --ulimit nofile=262144:262144 \
  -e BUILD_USER_UID=$(id -u) \
  -e BUILD_USER_GID=$(id -g) \
  -v "$PWD":/workspace \
  pfichtner/freetz

# Im Container:
make menuconfig
make
```

Für automatisierte/non-interaktive Builds (z. B. CI):

```bash
docker run --rm \
  --ulimit nofile=262144:262144 \
  -e BUILD_USER_UID=$(id -u) \
  -v "$PWD":/workspace \
  pfichtner/freetz \
  /bin/bash -c "make oldconfig && make"
```

---

## Tipps & Tricks

### Download-Cache zwischen Builds teilen

Um zu vermeiden, dass AVM-Images und Quellen bei jedem Build neu heruntergeladen werden, kann der `dl/`-Ordner außerhalb des Containers gemountet werden:

```bash
docker run --rm -it \
  --ulimit nofile=262144:262144 \
  -e BUILD_USER_UID=$(id -u) \
  -v "$PWD":/workspace \
  -v "$HOME/freetz-dl-cache":/workspace/dl \
  pfichtner/freetz
```

### Build-Artefakte bereinigen

```bash
# Nur Images und temporäre Dateien löschen (Toolchain bleibt erhalten)
make clean

# Alles löschen inkl. Toolchain (nächster Build dauert wieder länger)
make dirclean
```

### Konfiguration versionieren

Die eigene Konfiguration kann in diesem Repository gespeichert werden:

```bash
cp /workspace/freetz-ng/.config /workspace/fritz6591-cable.config
```

Beim nächsten Checkout:

```bash
cp /workspace/fritz6591-cable.config /workspace/freetz-ng/.config
make oldconfig   # Neue Optionen mit Standardwerten auffüllen
```

### Image-Update

```bash
docker pull pfichtner/freetz
```

---

## Troubleshooting

| Problem | Lösung |
|---|---|
| `Too many open files` beim Entpacken | `--ulimit nofile=262144:262144` ist im Dev Container bereits gesetzt |
| Build schlägt fehl wegen fehlender Pakete | `AUTOINSTALL_PREREQUISITES=y` ist gesetzt; ggf. `make prereq` manuell ausführen |
| `Permission denied` auf Dateien | UID-Mapping prüfen; Dev Container liest UID automatisch aus `/workspace` |
| freetz-ng unterstützt FritzBox 6591 nicht | Sicherstellen, dass das aktuellste freetz-ng verwendet wird: `git -C /workspace/freetz-ng pull` |
| Build auf Apple Silicon (M1/M2) | `--platform linux/amd64` zu den `runArgs` in `devcontainer.json` hinzufügen |

---

## Weiterführende Links

- [Freetz-NG GitHub](https://github.com/Freetz-NG/freetz-ng)
- [pfichtner/freetz Docker-Image](https://github.com/pfichtner/pfichtner-freetz)
- [Docker Hub: pfichtner/freetz](https://hub.docker.com/r/pfichtner/freetz/)
- [AVM FritzBox 6591 Cable Downloads](https://download.avm.de/fritzbox/fritzbox-6591-cable/deutschland/fritz.os/)
- [Freetz-NG Wiki](https://freetz-ng.github.io/)
