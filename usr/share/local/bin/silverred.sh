#!/bin/bash
# script by JohnJayMcKaye
# silverred.sh permissions `chmod u+x silverred.sh`
# Version 2026-07-21.1


echo "----------------------------------------------------------------"
echo "     wenn alles gut geht, ist dein PC nachher nicht kaputt      "
echo "----------------------------------------------------------------"

#sudo systemctl enable bootc-fetch-apply-updates.timer

echo "Drücke [ENTER] wenn du online bist, um fortzufahren..."
read
echo "Los geht's..."

echo "bereite System für Script vor und aktiviere Software-Quellen Flathub "
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --user --if-not-exists fedora oci+https://registry.fedoraproject.org
flatpak remote-add --user --if-not-exists rhel https://flatpaks.redhat.io/rhel.flatpakrepo

echo "Aktiviere Erweiterungen"
gnome-extensions enable caffeine@patapon.info
gnome-extensions enable gjsosk@vishram1123.com
gnome-extensions enable battery-usage-wattmeter@halfmexicanhalfamazing.gmail.com
gnome-extensions disable background-logo@fedorahosted.org

#echo "==> Setze System-Locale auf de_DE.UTF-8..."
#localectl set-locale LANG=de_DE.UTF-8
#gsettings set org.gnome.system.locale region 'de_DE.UTF-8'

#echo "==> Setze Konsolen-Tastaturlayout auf 'de' (deutsches Layout)..."
#localectl set-keymap de
#gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'de'), ('xkb', 'de+neo')]"

#echo "==> Setze X11-Tastaturlayout auf 'de' (für grafische Oberflächen)..."
#localectl set-x11-keymap de pc105 nodeadkeys

echo
echo "==> Firefox wird installiert"

flatpak install -y flathub org.mozilla.firefox


echo "Optimiere Stromverbrauch"
#tuned-adm active
#tuned-adm list
tuned-adm profile balanced

echo "Füge Minimieren Knopf zur Fensterleiste hinzu"
gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,close"

echo "Lautstärke Booster für Lautsprecher aktivieren"
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent 'true'

echo "sonstige tweaks"
gsettings set org.gnome.desktop.interface enable-animations false
gsettings set org.gnome.desktop.interface clock-show-weekday true
gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.SessionManager auto-save-session true
gsettings set org.gnome.desktop.interface accent-color 'red'

echo "Installiere ein paar Flatpaks für den Start"
flatpak install -y --user flathub org.mozilla.firefox com.mattjakeman.ExtensionManager io.missioncenter.MissionCenter com.github.jeromerobert.pdfarranger com.github.junrrein.PDFSlicer com.github.tchx84.Flatseal com.rawtherapee.RawTherapee com.valvesoftware.Steam de.bund.ausweisapp.ausweisapp2 im.riot.Riot org.audacityteam.Audacity org.audacityteam.Audacity.Codecs org.blender.Blender org.blender.Blender.Codecs org.darktable.Darktable org.freecad.FreeCAD org.gimp.GIMP org.gnome.NetworkDisplays org.gnome.SimpleScan org.gnome.Snapshot org.gnome.SoundRecorder org.gnome.gThumb org.gpodder.gpodder org.inkscape.Inkscape org.kde.kdenlive org.kde.krita org.keepassxc.KeePassXC org.libreoffice.LibreOffice org.mozilla.thunderbird org.videolan.VLC com.spotify.Client org.gnome.Firmware
#flatpak install -y --user fedora org.jpilot.JPilot

echo "----------------------------------------------------------------"
echo "                 Fertig, danke für deine Geduld                 "
echo "                 Silverred ist jetzt einsatzbereit.             "
echo "                 Extrem schnell, stromsparend und               "
echo "                 bis zu 10 Jahren Support                       "
echo "----------------------------------------------------------------"

echo "Wenn du dein System bei Red Hat registrieren möchtest nutze den Befehl:"
echo "sudo subscription-manager register --username BENUTZERNAME --password PASSWORT"
echo "BENUTZERNAME und PASSWORT musst du natürlich anpassen"
echo "----------------------------------------------------------------"

echo ""
read
echo "KABUM!"
#gnome-session-quit --logout


