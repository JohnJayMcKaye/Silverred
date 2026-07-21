# Silverred
A RHEL 10 image-mode (immutable) Workstation OS
 
**Silverred** ist ein eigenes RHEL-10-Image-Mode-Image (bootc) für Notebooks/Laptops. Es basiert auf dem offiziellen `rhel10/rhel-bootc`-Image von Red Hat und wird als fertig konfiguriertes, bootfähiges System ausgeliefert – inklusive aller Locales, Tastaturlayout, Laptop-Stromverwaltung und dezentes Branding.
 
Das Image wird über `bootc` verteilt: Es liegt als gewöhnliches Container-Image auf einer Registry (quay.io) und wird auf dem Zielsystem entweder per bootfähiger ISO installiert oder auf bereits laufenden Systemen per `bootc switch`/Update eingespielt.
 
## Inhalt
 
- [Features](#features)
- [Voraussetzungen](#voraussetzungen)
- [Repository-Struktur](#repository-struktur)
- [Image bauen](#image-bauen)
- [Installations-ISO erzeugen](#installations-iso-erzeugen)
- [Installation](#installation)
- [Bestehendes System aktualisieren](#bestehendes-system-aktualisieren)
- [Sicherheitshinweis zu Zugangsdaten](#sicherheitshinweis-zu-zugangsdaten)
- [Weiterführende Dokumentation](#weiterführende-dokumentation)
## Features
 
- **Basis:** `registry.redhat.io/rhel10/rhel-bootc` – enthält bereits Kernel, Bootloader und Firmware (Voraussetzung für Image Mode)
- **Desktop:** GNOME (gdm, gnome-shell, nautilus, gnome-software, …) plus vollständiges RHEL-10-Workstation-Paketset
- **Sprache & Eingabe:** Vollständig
- **Laptop-Stromverwaltung:** `tuned` + `tuned-ppd` (Ersatz für das in RHEL 10 entfernte `power-profiles-daemon`), `thermald`, `fwupd`, zram-Swap statt/zusätzlich zu klassischer Swap-Partition
- **OpenDoas:** wird aus dem Quellcode (v6.8.2) gebaut, da RHEL das Paket nicht bereitstellt; passwortloser `sudo`- und `doas`-Zugriff für die `wheel`-Gruppe
- **Sicherheit:** FIDO2-Unterstützung im Initramfs (dracut-Modul) um LUKS per FIDO2 Stick oder TPM zu entsperren
- **Boot:** Plymouth-Spinner-Theme mit eigenem Wasserzeichen, angepasste `PRETTY_NAME` (zeigt Build-Datum im GRUB-Menü, damit sich aufeinanderfolgende Deployments unterscheiden lassen)
- **Branding:** geänderte Hintergrundbilder, und einige Logos
- **Ersteinrichtung:** `gnome-initial-setup` beim ersten Login und Setup-Skript für Flatpaks und mitgelieferte GNOME-Shell-Extensions
- **Updates:** `bootc-fetch-apply-updates.timer` ist aktiviert, Systeme holen sich Updates automatisch von der Registry
Details und Begründungen zu den einzelnen Anpassungen stehen in [`DOKUMENTATION.md`](./DOKUMENTATION.md).
 
## Voraussetzungen
 
- `podman` + `container-tools`
- Account bei `registry.redhat.io` (ein kostenloser Red Hat Developer Account reicht für den Image-Zugriff)
- Account z.B. bei `quay.io`, falls du das Image selbst veröffentlichen willst
- Für den ISO-Bau: `registry.redhat.io/rhel10/bootc-image-builder` (wird von `build.sh` automatisch gezogen)
## Repository-Struktur
 
```
.
├── Containerfile     # Definition des bootc-Images (siehe DOKUMENTATION.md)
├── build.sh          # Baut das Image, pusht es zu quay.io, erzeugt die Install-ISO
├── config.toml       # Konfiguration für bootc-image-builder (Kickstart/ISO-Metadaten)
├── update.sh         # Wechselt ein bestehendes System per bootc auf dieses Image
├── etc/              # Dateien, die per COPY ins Image kommen (sudoers, doas.conf, hostname, gdm/custom.conf, …)
└── usr/              # Branding, Setup-Skript, GNOME-Extensions, Build-Log (per COPY ins Image)
```
 
## Image bauen
 
> Vorher bei den Registries anmelden:
>
> ```bash
> podman login registry.redhat.io
> podman login quay.io
> ```
 
Danach:
 
```bash
sudo bash build.sh
```
 
Das Skript (siehe [`DOKUMENTATION.md`](./DOKUMENTATION.md) für Details):
 
1. baut das Image aus dem `Containerfile` und setzt `BUILD_DATE` als Build-Argument,
2. pusht das Image nach `quay.io/<dein-namespace>/rhel-10-silverred:latest`,
3. erzeugt daraus mit `bootc-image-builder` eine bootfähige Anaconda-ISO in `./output/bootiso/install.iso`.
## Installations-ISO erzeugen
 
Wird bereits von `build.sh` erledigt. Die Konfiguration dafür steht in `config.toml`:
 
- Das Anaconda-Modul für Benutzeranlage ist deaktiviert (`disable = [...Users]`) – Benutzeranlage übernimmt stattdessen `gnome-initial-setup` beim ersten Boot.
- Das Localization-Modul ist bewusst **nicht** aktiviert – es bringt den Installer unter RHEL 10 aktuell zum Absturz.
- ISO-Metadaten (`volume_id`, `application_id`, `publisher`) sind unter `[customizations.iso]` gesetzt.
## Installation
 
Die ISO liegt nach dem Build unter `output/bootiso/install.iso`. Auf einen USB-Stick schreiben:
 
```bash
sudo dd if=output/bootiso/install.iso of=/dev/sdX bs=4M status=progress conv=fsync
```
 
`/dev/sdX` durch das tatsächliche Zielgerät ersetzen (vorher mit `lsblk` prüfen!).
 
## Bestehendes System aktualisieren
 
Ein bereits laufendes bootc-System kann direkt auf dieses Image wechseln:
 
```bash
sudo bootc switch --transport registry quay.io/<dein-namespace>/rhel-10-silverred:latest
```
 
Da `bootc-fetch-apply-updates.timer` aktiv ist, ziehen sich Systeme neue Image-Versionen danach automatisch.
 
## Weiterführende Dokumentation
 
Eine ausführliche Erklärung aller Anpassungen im `Containerfile` und in `config.toml` – inklusive der Begründungen für einzelne Entscheidungen – findest du in [`DOKUMENTATION.md`](./DOKUMENTATION.md).
