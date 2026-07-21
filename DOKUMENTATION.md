Mit `--json` bekommst du eine maschinenlesbare Ausgabe für Skripte.

### `bootc upgrade`
Holt eine neue Version des **aktuell konfigurierten** Images. Dabei wird das Container-Image von der konfigurierten Quelle abgefragt und ein aktualisiertes Image für den nächsten Boot vorgemerkt (gestaged).

```bash
sudo bootc upgrade
```

Optionen:
- `--apply` – wendet ausstehende Änderungen automatisch an (bootet neu, falls nötig)
- `--download-only` – lädt das Update nur herunter, ohne es beim nächsten Reboot automatisch zu aktivieren

```bash
sudo bootc upgrade --apply
```

### `bootc switch`
Wechselt zu einem **anderen** Image (z. B. andere Version, anderer Branch/Tag, oder komplett anderes OS-Variant-Image).

Das neue Image wird gestaged und beim nächsten Neustart aktiv; das vorherige Deployment bleibt für ein Rollback erhalten.

```bash
sudo bootc switch registry.example.com/meinsystem:v2
```

Auch mit fester Digest-Angabe möglich (für reproduzierbare, exakte Versionen):

```bash
sudo bootc switch quay.io/beispielos/nutzer@sha256:9cca07...
```

Wird ein fester Tag/Digest gesetzt, ist `bootc upgrade` danach ein No-Op – Updates laufen dann nur noch über weitere `switch`-Befehle.

### `bootc rollback`
Setzt das System auf den vorherigen Boot-Eintrag zurück (vertauscht die Bootloader-Reihenfolge).

```bash
sudo bootc rollback
```

Danach mit `sudo reboot` neu starten, oder direkt:

```bash
sudo bootc rollback --apply
```

**Notfall-Rollback:** Falls das Terminal erreichbar ist, `bootc rollback --apply` aufrufen; startet das System gar nicht mehr, alternativ die ältere Version direkt im GRUB-Bootmenü auswählen.

### `bootc install`
Installiert ein bootc-Image auf ein Gerät (Bare-Metal oder VM).

Zwei Varianten:
- `bootc install to-disk` – komplette Festplatteninstallation
- `bootc install to-filesystem` – Installation direkt auf ein gemountetes Dateisystem, z. B. für angepasste Partitionslayouts

```bash
sudo bootc install to-disk /dev/sda
```

⚠️ Muss privilegiert (root/`--privileged`) ausgeführt werden.

---

## 4. Typischer Alltagsworkflow

| Aufgabe | Befehl |
|---|---|
| Systemstatus prüfen | `sudo bootc status` |
| Nach Updates suchen & anwenden | `sudo bootc upgrade --apply` |
| Update nur laden, später anwenden | `sudo bootc upgrade --download-only` |
| Zu anderem Image/Version wechseln | `sudo bootc switch <image>` |
| Bei Problemen zurückrollen | `sudo bootc rollback --apply` |
| Aktuelle/geplante Konfiguration prüfen | `sudo bootc status --json` |

**Automatische Updates:** Es gibt einen optionalen, vorkonfigurierten `bootc-fetch-apply-updates.timer` samt zugehörigem Service für automatische Hintergrund-Updates.

---

## 5. Wie ändere ich mein System dauerhaft?

Da `/usr` read-only ist, änderst du dein System **nicht** durch direktes Installieren von Paketen am laufenden System, sondern:

1. Du hast (oder baust) eine **Containerfile** (früher: Dockerfile), die dein System beschreibt.
2. Das Containerfile wird zu einem neuen Image gebaut und in eine Container-Registry gepusht (z. B. mit `podman build` + `podman push`).
3. Auf dem System führst du `bootc switch <neues-image>` oder `bootc upgrade` aus.

Für temporäre Testanpassungen am laufenden System gibt es `bootc usroverlay`, das ein beschreibbares Overlay auf `/usr` legt – nützlich zum Debuggen, aber nicht für dauerhafte Änderungen gedacht.

---

## 6. Wichtige Grundprinzipien zum Merken

- **Kein "apt install" mehr am laufenden System** für dauerhafte Änderungen – alles läuft über das Image.
- **Jedes Update ist reversibel** – ein Rollback ist immer nur einen Befehl oder einen GRUB-Menüpunkt entfernt.
- **Nichts passiert "live"** – Updates werden gestaged und erst beim Neustart aktiv (außer mit `--apply`).
- **Bare-Metal-Installation ohne Netzwerk möglich** – z. B. für Air-Gapped-Umgebungen.
- **bootc ist distributionsunabhängig** – die CLI ist nur ein Client, nicht an eine bestimmte Distribution gebunden.

---
---------------------------------------------------------
## 6. CANGELOG

Anpassungen
-----------------------------------------------------------
## 1. Überblick

**Silverred** ist ein bootc-basiertes RHEL-10-Betriebssystem-Image für GNOME-Notebooks.
Es wird aus dem offiziellen `rhel-bootc`-Basis-Image gebaut und um Desktop-,
Laptop- und Branding-Komponenten erweitert.

| Eigenschaft | Wert |
|---|---|
| Basis-Image | `registry.redhat.io/rhel10/rhel-bootc:latest` |
| Desktop-Umgebung | GNOME (Wayland, GDM) |
| Zielgeräte | Notebooks/Laptops |
| Sprache/Layout | Deutsch, Neo2-Tastaturlayout |
| Auto-Updates | Aktiv (`bootc-fetch-apply-updates.timer`) |
| Zusatz-Repos | CRB + EPEL |

**Voraussetzung für den Build:**
```bash
podman login registry.redhat.io
```
Ein kostenloser Red Hat Developer Account reicht für den Image-Zugriff aus.

---

## 2. Architektur des Containerfiles

Das Containerfile ist in 12 getrennte Abschnitte gegliedert:

| Abschnitt | Zweck |
|---|---|
| 0 | Build-Argumente & Basis-Image (`FROM`, Labels, `PRETTY_NAME`) |
| 1 | Zusatz-Repositories aktivieren (CRB, EPEL) |
| 2 | OpenDoas aus Quellcode bauen |
| 3 | Paketinstallation (Desktop, Netzwerk, Audio, Laptop, Drucken, Fonts) |
| 4 | Locale, Tastatur (Neo2) & Zeitzone |
| 5 | Standard-Ziel & Dienste aktivieren |
| 6 | FIDO2-Unterstützung & Plymouth-Bootscreen |
| 7 | Passwortloses sudo & doas für Gruppe "wheel" |
| 8 | Hostname |
| 9 | Branding (Hintergründe, Logos, Icons) |
| 10 | Setup-Skript & GNOME-Erweiterungen |
| 11 | Build-Log |
| 12 | Abschließende Prüfung (`bootc container lint`) |

---

## 3. Abschnitt für Abschnitt

### 3.1 Basis-Image & Metadaten
```dockerfile
ARG BASE_IMAGE=registry.redhat.io/rhel10/rhel-bootc
ARG BASE_TAG=latest
FROM ${BASE_IMAGE}:${BASE_TAG}
```
Im Unterschied zu UBI (Universal Base Image) enthält `rhel-bootc` bereits
**Kernel, Bootloader und Firmware** – zwingende Voraussetzung für ein
bootfähiges Image-Mode-System.

Die `PRETTY_NAME`-Anpassung sorgt dafür, dass jedes Deployment im
GRUB-Menü **eindeutig** anhand von `BUILD_DATE` unterscheidbar ist. Ohne
diesen Schritt zeigen zwei aufeinanderfolgende Builds denselben Menü-Eintrag,
solange sich die Kernel-Version nicht ändert – ein Rollback über das
GRUB-Menü wäre dann kaum zuverlässig möglich.

### 3.2 Zusatz-Repositories
```dockerfile
RUN dnf config-manager --set-enabled codeready-builder-for-rhel-10-x86_64-rpms && \
    dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm
```
- **CRB** (CodeReady Builder) liefert `-devel`-Pakete, u. a. für den
  OpenDoas-Build.
- **EPEL** liefert Community-Pakete außerhalb des offiziellen RHEL-Supports.

> **Hinweis:** Sobald EPEL aktiv ist, verlässt das Image teilweise den
> offiziell von Red Hat supporteten Paketrahmen. Für ein internes/privates
> Notebook-Image unkritisch, sollte bei produktivem/unternehmensweitem
> Einsatz aber bewusst entschieden und dokumentiert werden.

### 3.3 OpenDoas (aus Quellcode)
`doas` ist im Standard-RHEL-Repo nicht enthalten und wird daher manuell
gebaut (`byacc` statt `bison`, da RHEL keinen yacc-kompatiblen Bison
bereitstellt). Build-Abhängigkeiten werden danach entfernt, um das Image
schlank zu halten.

> Da `doas` nicht aus einem RPM stammt, bekommt das Binary **keinen**
> automatischen SELinux-Filecontext. `restorecon -v /usr/bin/doas` setzt ihn
> manuell – ohne diesen Schritt würde `doas` unter dem enforcing SELinux von
> RHEL ggf. mit falschem/keinem Kontext laufen.

### 3.4 Paketinstallation
Handverlesene Kernpakete (GNOME, Netzwerk/WLAN/Bluetooth, Audio via
PipeWire, Laptop-Stromverwaltung, Drucken, Basis-Tools) plus das
vollständige RHEL-10-Workstation-Paketset, alphabetisch und dedupliziert.

Informativ:
- `power-profiles-daemon` wurde in RHEL 10 entfernt → **`tuned-ppd`** ist
  der offizielle Ersatz mit identischer GNOME-Integration.
- Standardschriftarten (`google-noto-*`, `dejavu-sans`) werden bewusst
  **nicht** separat installiert, da das `default-fonts-*`-Set aus dem
  Workstation-Paketset die Grundabdeckung bereits liefert.

### 3.5 Locale, Tastatur & Zeitzone
```dockerfile
ENV LANG=de_DE.UTF-8
ENV LANGUAGE=de_DE:de
ENV LC_ALL=de_DE.UTF-8
ENV TZ=Europe/Berlin
```

> **Wichtig:** Diese `ENV`-Werte wirken **nur** beim Image-Build selbst
> und bei `podman run` zu Testzwecken. Auf einem per bootc gebooteten
> System zählen ausschließlich die Dateien:
> - `/etc/locale.conf`
> - `/etc/vconsole.conf`
> - `/etc/localtime`

Das Neo2-Tastaturlayout wird von `neo-layout.org` heruntergeladen und nach
`/usr/lib/kbd/keymaps/` entpackt.

> ToDo: **Risiko:** Diese Quelle ist kein offizielles RPM/Red-Hat-Mirror.
> Ist die Seite zum Build-Zeitpunkt nicht erreichbar oder ändert sich die
> Archivstruktur, schlägt der Build fehl bzw. das Keymap-Verzeichnis
> passt nicht mehr zu `KEYMAP=neo` in `/etc/vconsole.conf`. Empfehlung:
> Datei in ein eigenes, versioniertes Artefakt-Repo spiegeln.

Zram-Swap wird über `/etc/systemd/zram-generator.conf` konfiguriert
(komprimierter RAM-Swap, `zstd`, bis zu 4 GB, halbe RAM-Größe als Limit).

### 3.6 Dienste & Standard-Ziel
```dockerfile
systemctl set-default graphical.target
systemctl enable gdm.service NetworkManager.service bluetooth.service \
                  thermald.service tuned.service cups.service \
                  bootc-fetch-apply-updates.timer
```

> **Verhaltensänderung gegenüber "nur manuellem" bootc-Betrieb:**
> Da `bootc-fetch-apply-updates.timer` aktiviert ist, prüft und lädt das
> System **automatisch im Hintergrund** neue Updates – nicht erst bei
> manuellem `bootc upgrade`. Angewendet werden sie weiterhin erst beim
> nächsten Neustart (Standardverhalten von bootc), aber der Download läuft
> unbeaufsichtigt.

Aktivieren von Diensten via `systemctl enable` funktioniert im
Build-Container zuverlässig, da ostree-basierte systemd-Systeme das auch
offline (ohne laufenden systemd-Daemon) durch Symlink-Erstellung
unterstützen – das ist der von Red Hat empfohlene Standardweg für
Image-Mode-Builds.

### 3.7 FIDO2 & Plymouth
- `fido2`-Dracut-Modul für Hardware-Sicherheitsschlüssel (z. B. Login/LUKS)
- Plymouth-Theme `spinner` als grafischer Bootscreen
- Kernel-Argumente `rhgb quiet` werden deklarativ über
  `/usr/lib/bootc/kargs.d/01-plymouth.toml` gesetzt (bootc-eigener
  Mechanismus, kein manuelles `grubby` nötig)

**Ein einziger finaler `dracut`-Lauf** bündelt alle initramfs-relevanten
Änderungen. Wichtig dabei:
- Die Kernel-Version wird explizit aus `/usr/lib/modules` ermittelt (nicht
  `uname -r`), da sich der Build-Container sonst am Kernel des **Build-Hosts**
  orientieren würde, der im fertigen Image gar nicht existiert.
- `--regenerate-all` darf **nicht** zusammen mit einer expliziten
  Kernel-Version angegeben werden – dracut bricht sonst mit einem Fehler ab.

### 3.8 sudo & doas
```dockerfile
COPY --chmod=0440 etc/sudoers.d/wheel-nopasswd /etc/sudoers.d/wheel-nopasswd
COPY --chmod=0600 --chown=root:root etc/doas.conf /etc/doas.conf
```
Passwortloses `sudo`/`doas` für die Gruppe `wheel`. Rechte werden direkt
beim `COPY` über `--chmod`/`--chown` gesetzt – unabhängig von den lokalen
Dateirechten im Build-Kontext (Best Practice, verhindert versehentlich zu
offene/zu enge Berechtigungen).

### 3.9 Hostname
```dockerfile
COPY --chmod=0644 etc/hostname /etc/hostname
```
> **Hinweis bei Mehrgeräte-Einsatz:** Der Hostname ist fest im Image
> gebacken. Wird dasselbe Image auf mehrere Geräte ausgerollt, haben alle
> denselben Hostnamen, sofern er nicht nach der Installation manuell (z. B.
> via `hostnamectl` oder Cloud-Init-ähnlichem First-Boot-Mechanismus)
> überschrieben wird.

### 3.10 Branding & Setup
Hintergründe, Logos, Plymouth-Wasserzeichen und ein Startmenü-Icon werden
mit expliziten `0644`-Rechten kopiert (verhindert z. B., dass GDM ein
Hintergrundbild nicht lesen kann, falls es lokal restriktivere Rechte hatte).

Ein First-Setup-Skript (`silverred.sh`) sowie GNOME-Shell-Erweiterungen
werden eingebunden; `gnome-initial-setup` wird über eine leere
`vendor.conf`-`[pages]`-Sektion so konfiguriert, dass keine Einrichtungsseiten
angezeigt werden.

### 3.11 Abschließende Prüfung
```dockerfile
RUN bootc container lint
```
Wird bewusst **ganz am Ende** ausgeführt (nicht mittendrin, wie in einer
früheren Version), damit tatsächlich der fertige, komplette Image-Zustand
geprüft wird – inklusive aller Branding- und Setup-Schritte.

```dockerfile
CMD ["/sbin/init"]
```
Wird bei einem echten bootc-Deployment ignoriert, ermöglicht aber Testläufe
als gewöhnlicher Container via `podman run`.

---

## 4. Build & Deploy Workflow

```bash
# 1. Image bauen
podman build \
  --build-arg BUILD_DATE="$(date -u +%Y%m%d%H%M%S)" \
  --build-arg VCS_REF="$(git rev-parse --short HEAD)" \
  -t silverred-workstation:latest .

# 2. Testweise als Container starten (optional)
podman run --rm -it silverred-workstation:latest bash

# 3. In Registry pushen
podman push silverred-workstation:latest registry.example.com/silverred:latest

# 4a. Neuinstallation auf einem Gerät
sudo bootc install to-disk /dev/nvme0n1

# 4b. Bestehendes bootc-System auf dieses Image umstellen
sudo bootc switch registry.example.com/silverred:latest

# 5. Danach reine Updates
sudo bootc upgrade --apply
```

---

## 5. ToDo

| Thema | Empfehlung |
|---|---|
| Neo2-Keymap-Quelle | Auf eigenes, versioniertes Mirror/Artefakt umstellen statt Live-Download von `neo-layout.org` |
| EPEL/CRB | Bewusst halten, im Team dokumentieren, dass Teile des Images außerhalb des RHEL-Supports liegen |
| Auto-Updates | `bootc-fetch-apply-updates.timer` ist aktiv – bei Bedarf deaktivieren, falls Updates nur manuell laufen sollen |
| Hostname | Bei Mehrgeräte-Rollout per First-Boot-Skript individualisieren statt fix im Image |
| `bootc container lint` | Vor jedem Release-Build laufen lassen (ist hier bereits als letzter Schritt integriert) |
| Rollback | Bei Problemen: `sudo bootc rollback --apply`, alternativ älteren Eintrag direkt im GRUB-Menü wählen |
