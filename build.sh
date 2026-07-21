
set -euo pipefail

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
set -euo pipefail

IMAGE_NAME="quay.io/johnjaymckaye/rhel-10-silverred:latest"
OUTPUT_DIR="./output"

echo "==> 1/3 Baue das bootc-Image aus dem Containerfile ..."
sudo podman build --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" -t "${IMAGE_NAME}" .
#sudo podman build -t "${IMAGE_NAME}" .
#sudo podman build --no-cache -t "${IMAGE_NAME}" .


echo "==> 2/3 Pushe zu quay.io"

#sudo podman tag localhost/rhel-10-silverred:latest quay.io/johnjaymckaye/rhel-10-silverred:latest

#sudo podman build --no-cache -t "${IMAGE_NAME}" .
sudo podman push "${IMAGE_NAME}"

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
echo ""
echo "Fertig! Die ISO liegt in: ${OUTPUT_DIR}/bootiso/install.iso"
echo "(bootc-image-builder benennt die Datei bei --type anaconda-iso immer so,"
echo " unabhängig von volume_id/application_id in config.toml.)"
echo "Zum Schreiben auf einen USB-Stick:"
echo "  sudo dd if=${OUTPUT_DIR}/bootiso/install.iso of=/dev/sdX bs=4M status=progress conv=fsync"
