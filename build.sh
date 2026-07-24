#!/usr/bin/env bash
# =============================================================================
# Baut das RHEL 10 bootc-Image und erzeugt daraus eine installierbare ISO.
#
# Voraussetzungen:
#   - podman + container-tools installiert
#   - Angemeldet bei registry.redhat.io:  podman login registry.redhat.io
#     (kostenloser Red Hat Developer Account reicht)
#   - config.toml an deine Bedürfnisse angepasst (Benutzername/Passwort/Key)
# =============================================================================

#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+#
echo "Melde dich vorher bei deinem Red Hat Konto und deiner Registry an"
echo "sudo podman login registry.redhat.io --username BENUTZERNAME --password PASSWORT"
echo "sudo podman login -u='BENUTZERNAME' -p='PASSWORTTOKENDERREGISTRY' quay.io"
#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+#

set -euo pipefail
IMAGE_NAME="quay.io/johnjaymckaye/rhel-10-silverred:latest"
OUTPUT_DIR="./output"

# -----------------------------------------------------------------------
# Abfrage, welche Schritte ausgeführt werden sollen
# -----------------------------------------------------------------------
read -rp "Schritt 2 (Push zu quay.io) ausführen? [j/N] " ANTWORT_PUSH
case "${ANTWORT_PUSH}" in
    [jJ]|[jJ][aA]) RUN_PUSH=true ;;
    *) RUN_PUSH=false ;;
esac

read -rp "Schritt 3 (ISO mit bootc-image-builder erzeugen)? [j/N] " ANTWORT_ISO
case "${ANTWORT_ISO}" in
    [jJ]|[jJ][aA]) RUN_ISO=true ;;
    *) RUN_ISO=false ;;
esac

echo "==> 1/3 Baue das bootc-Image aus dem Containerfile ..."
sudo podman build --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" -t "${IMAGE_NAME}" .
#sudo podman build -t "${IMAGE_NAME}" .
#sudo podman build --no-cache -t "${IMAGE_NAME}" .

if [ "${RUN_PUSH}" = true ]; then
    echo "==> 2/3 Pushe zu quay.io"
    #sudo podman tag localhost/rhel-10-silverred:latest quay.io/johnjaymckaye/rhel-10-silverred:latest
    #sudo podman build --no-cache -t "${IMAGE_NAME}" .
    sudo podman push "${IMAGE_NAME}"
else
    echo "==> 2/3 Übersprungen (Push zu quay.io)"
fi

if [ "${RUN_ISO}" = true ]; then
    echo "==> 3/3 Erzeuge die bootfähige ISO mit bootc-image-builder ..."
    mkdir -p "${OUTPUT_DIR}"
    sudo podman run --rm -it --privileged --pull=newer \
        --security-opt label=type:unconfined_t \
        -v "${OUTPUT_DIR}:/output" \
        -v "$(pwd)/config.toml:/config.toml:ro" \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        registry.redhat.io/rhel10/bootc-image-builder:latest \
        --type anaconda-iso \
        --config /config.toml \
        "${IMAGE_NAME}"
    sudo podman system prune -a -f --volumes

    # -------------------------------------------------------------------
    # ISO umbenennen in Silverred(Datum).iso
    # -------------------------------------------------------------------
    ISO_DATUM="$(date +%Y-%m-%d)"
    ISO_NEUER_NAME="Silverred-${ISO_DATUM}.iso"
    sudo mv "${OUTPUT_DIR}/bootiso/install.iso" "${OUTPUT_DIR}/bootiso/${ISO_NEUER_NAME}"

    echo ""
    echo "Fertig! Die ISO liegt in: ${OUTPUT_DIR}/bootiso/${ISO_NEUER_NAME}"
    echo "(bootc-image-builder benennt die Datei bei --type anaconda-iso zunächst immer"
    echo " install.iso, unabhängig von volume_id/application_id in config.toml -"
    echo " daher die Umbenennung im Anschluss.)"
    echo "Zum Schreiben auf einen USB-Stick:"
    echo "  sudo dd if=${OUTPUT_DIR}/bootiso/${ISO_NEUER_NAME} of=/dev/sdX bs=4M status=progress conv=fsync"
else
    echo "==> 3/3 Übersprungen (ISO-Erzeugung)"
fi
