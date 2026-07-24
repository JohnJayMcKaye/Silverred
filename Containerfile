# =============================================================================
# RHEL 10 Image Mode – GNOME Notebook/Laptop-Image "Silvered"
# =============================================================================
#
# Voraussetzung: podman login registry.redhat.io
# (ein kostenloser Red Hat Developer Account reicht für den Image-Zugriff)
# =============================================================================

# -----------------------------------------------------------------------------
# 0) Build-Argumente & Basis-Image
# -----------------------------------------------------------------------------
ARG BASE_IMAGE=registry.redhat.io/rhel10/rhel-bootc
ARG BASE_TAG=latest

FROM ${BASE_IMAGE}:${BASE_TAG}

# Metadaten – BUILD_DATE kommt aus build.sh (--build-arg BUILD_DATE=...).
ARG BUILD_DATE
ARG VERSION=10.2
ARG VCS_REF=""

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.title="silverred-workstation"

# GRUB übernimmt seinen Menü-Titel für OSTree/bootc-Deployments 1:1 aus
# PRETTY_NAME hier. 
# BUILD_DATE macht jeden Build eindeutig erkennbar (offiziell von Red Hat
# so für RHEL-10-bootc-Images empfohlen).
RUN sed -i "s/^PRETTY_NAME=.*/PRETTY_NAME=\"Silverred ${VERSION} (Build ${BUILD_DATE})\"/" /usr/lib/os-release


RUN echo -e "fastestmirror=True\nmax_parallel_downloads=10\ninstall_weak_deps=False" >> /etc/dnf/dnf.conf

# -----------------------------------------------------------------------------
# 1) Zusätzliche Repositories aktivieren (CRB + EPEL)
# -----------------------------------------------------------------------------
# CRB für -devel-Pakete, EPEL für Community-Pakete (u.a. Build-Dependencies
# für OpenDoas weiter unten).
RUN dnf config-manager --set-enabled codeready-builder-for-rhel-10-x86_64-rpms && \
    dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm

# -----------------------------------------------------------------------------
# 2) OpenDoas aus dem Quellcode bauen
# -----------------------------------------------------------------------------
# Build-Abhängigkeiten (gcc/make/byacc) werden danach wieder entfernt, damit
# sie nicht dauerhaft im Image landen.
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y gcc make byacc --allowerasing && \
    curl -L -o /tmp/opendoas.tar.gz https://github.com/Duncaen/OpenDoas/archive/refs/tags/v6.8.2.tar.gz && \
    tar -xzf /tmp/opendoas.tar.gz -C /tmp && \
    cd /tmp/OpenDoas-6.8.2 && \
    ./configure --prefix=/usr --with-timestamp && \
    make && make install && \
    cd / && rm -rf /tmp/OpenDoas-6.8.2 /tmp/opendoas.tar.gz && \
    dnf remove -y gcc make byacc

# -----------------------------------------------------------------------------
# 3) Paketinstallation
# -----------------------------------------------------------------------------
#DNF-Pakete
# 3a) Handverlesene Kernpakete für den Desktop-Betrieb, nach Zweck gruppiert.
# 3b) Das vollständige RHEL-10-Workstation-Paketset darunter.
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf -y install \
        # --- GNOME Desktop ---
        gdm \
        gnome-shell \
        ptyxis \
        gnome-control-center \
        nautilus \
        glibc-langpack-de \
        gnome-text-editor \
        gnome-software \
        xdg-desktop-portal \
        xdg-desktop-portal-gtk \
        xdg-user-dirs \
        # --- Netzwerk / WLAN / Bluetooth ---
        NetworkManager \
        NetworkManager-wifi \
        NetworkManager-bluetooth \
        bluez \
        # --- Audio ---
        pipewire \
        pipewire-pulseaudio \
        pipewire-alsa \
        wireplumber \
        # --- Virtualisierung ---
        virt-manager \
        libvirt-daemon-kvm \
        libvirt-daemon-config-network \
        libvirt-client \
        qemu-kvm \
        # --- Laptop-spezifisch: Stromverwaltung, Firmware, Thermal ---
        # power-profiles-daemon wurde in RHEL 10 entfernt, tuned-ppd ist der
        # offizielle Drop-in-Ersatz mit derselben API/GNOME-Integration.
        tuned \
        tuned-ppd \
        fwupd \
        thermald \
        zram-generator \
        # --- Drucken ---
        cups \
        cups-browsed \
        # --- Basis-Tools ---
        nano \
        git \
        wget \
        curl \
        tar \
        unzip \
        # --- Restliches RHEL-10-Workstation-Paketset ---
        ModemManager \
        ModemManager-glib \
        NetworkManager-adsl \
        NetworkManager-libnm \
        NetworkManager-tui \
        NetworkManager-wwan \
        PackageKit \
        PackageKit-command-not-found \
        PackageKit-glib \
        PackageKit-gstreamer-plugin \
        PackageKit-gtk3-module \
        aardvark-dns \
        accountsservice \
        accountsservice-libs \
        acl \
        adcli \
        adcli-selinux \
        adobe-mappings-cmap \
        adobe-mappings-cmap-deprecated \
        adobe-mappings-pdf \
        adwaita-cursor-theme \
        adwaita-icon-theme \
        alsa-lib \
        alsa-sof-firmware \
        alsa-ucm \
        alsa-utils \
        alternatives \
        amd-gpu-firmware \
        amd-ucode-firmware \
        anthy-unicode \
        appstream \
        appstream-data \
        at \
        at-spi2-atk \
        at-spi2-core \
        atheros-firmware \
        atk \
        attr \
        audit \
        audit-libs \
        audit-rules \
        authselect \
        authselect-libs \
        avahi \
        avahi-glib \
        avahi-libs \
        avahi-tools \
        baobab \
        basesystem \
        bash \
        bash-color-prompt \
        bash-completion \
        bc \
        bind-libs \
        bind-license \
        bind-utils \
        binutils \
        binutils-gold \
        blktrace \
        bluez-libs \
        bluez-obexd \
        bolt \
        bpftool \
        brcmfmac-firmware \
        brlapi \
        brltty \
        bubblewrap \
        bzip2 \
        bzip2-libs \
        c-ares \
        ca-certificates \
        cairo \
        cairo-gobject \
        cairomm1.16 \
        catatonit \
        checkpolicy \
        chrony \
        cifs-utils \
        cirrus-audio-firmware \
        cldr-emoji-annotation \
        cldr-emoji-annotation-dtd \
        clevis \
        clevis-luks \
        clevis-pin-tpm2 \
        cockpit \
        cockpit-bridge \
        cockpit-machines \
        cockpit-packagekit \
        cockpit-storaged \
        cockpit-system \
        cockpit-ws \
        cockpit-ws-selinux \
        color-filesystem \
        colord \
        colord-gtk4 \
        colord-libs \
        command-line-assistant \
        command-line-assistant-selinux \
        composefs-libs \
        conmon \
        container-selinux \
        containers-common \
        containers-common-extra \
        coreutils \
        coreutils-common \
        cpio \
        cracklib \
        cracklib-dicts \
        criu \
        criu-libs \
        cronie \
        cronie-anacron \
        crontabs \
        crun \
        crypto-policies \
        crypto-policies-scripts \
        cryptsetup \
        cryptsetup-libs \
        cups-client \
        cups-filesystem \
        cups-filters \
        cups-filters-driverless \
        cups-ipptool \
        cups-libs \
        cups-pk-helper \
        cyrus-sasl-gssapi \
        cyrus-sasl-lib \
        cyrus-sasl-plain \
        dbus \
        dbus-broker \
        dbus-common \
        dbus-daemon \
        dbus-libs \
        dbus-tools \
        dconf \
        default-fonts-am \
        default-fonts-ar \
        default-fonts-as \
        default-fonts-ast \
        default-fonts-be \
        default-fonts-bg \
        default-fonts-bn \
        default-fonts-bo \
        default-fonts-br \
        default-fonts-chr \
        default-fonts-cjk-mono \
        default-fonts-cjk-sans \
        default-fonts-cjk-serif \
        default-fonts-core-emoji \
        default-fonts-core-math \
        default-fonts-core-mono \
        default-fonts-core-sans \
        default-fonts-core-serif \
        default-fonts-dv \
        default-fonts-dz \
        default-fonts-el \
        default-fonts-eo \
        default-fonts-eu \
        default-fonts-fa \
        default-fonts-gu \
        default-fonts-he \
        default-fonts-hi \
        default-fonts-hy \
        default-fonts-ia \
        default-fonts-iu \
        default-fonts-ka \
        default-fonts-km \
        default-fonts-kn \
        default-fonts-ku \
        default-fonts-lo \
        default-fonts-mai \
        default-fonts-ml \
        default-fonts-mni \
        default-fonts-mr \
        default-fonts-my \
        default-fonts-nb \
        default-fonts-ne \
        default-fonts-nn \
        default-fonts-nr \
        default-fonts-nso \
        default-fonts-or \
        default-fonts-other-mono \
        default-fonts-other-sans \
        default-fonts-other-serif \
        default-fonts-pa \
        default-fonts-ru \
        default-fonts-sat \
        default-fonts-si \
        default-fonts-ss \
        default-fonts-ta \
        default-fonts-te \
        default-fonts-th \
        default-fonts-tn \
        default-fonts-ts \
        default-fonts-uk \
        default-fonts-ur \
        default-fonts-ve \
        default-fonts-vi \
        default-fonts-xh \
        default-fonts-yi \
        default-fonts-zu \
        dejavu-sans-fonts \
        dejavu-sans-mono-fonts \
        dejavu-serif-fonts \
        desktop-file-utils \
        device-mapper \
        device-mapper-event \
        device-mapper-event-libs \
        device-mapper-libs \
        device-mapper-multipath \
        device-mapper-multipath-libs \
        device-mapper-persistent-data \
        diffutils \
        dmidecode \
        dnf \
        dnf-data \
        dnf-plugins-core \
        dnsmasq \
        dos2unix \
        dosfstools \
        dotconf \
        dracut \
        dracut-config-rescue \
        dracut-network \
        dracut-squash \
        duktape \
        e2fsprogs \
        e2fsprogs-libs \
        ed \
        editorconfig-libs \
        efi-filesystem \
        efibootmgr \
        efivar-libs \
        elfutils-debuginfod-client \
        elfutils-default-yama-scope \
        elfutils-libelf \
        elfutils-libs \
        emacs-filesystem \
        enchant2 \
        enscript \
        erofs-utils \
        espeak-ng \
        ethtool \
        evolution-data-server \
        evolution-data-server-langpacks \
        exempi \
        exfatprogs \
        exiv2 \
        exiv2-libs \
        expat \
        fdk-aac-free \
        fftw-libs-single \
        fido2-tools \
        file \
        file-libs \
        filesystem \
        findutils \
        firewalld \
        firewalld-filesystem \
        flac-libs \
        flashrom \
        flatpak \
        flatpak-libs \
        flatpak-selinux \
        flatpak-session-helper \
        fontconfig \
        fonts-filesystem \
        foomatic \
        foomatic-db \
        foomatic-db-filesystem \
        foomatic-db-ppds \
        fprintd \
        fprintd-pam \
        freerdp-libs \
        freetype \
        fribidi \
        fstrm \
        fuse-common \
        fuse-libs \
        fuse3 \
        fuse3-libs \
        fwupd-efi \
        fwupd-plugin-flashrom \
        gawk \
        gawk-all-langpacks \
        gcr \
        gcr-libs \
        gcr3 \
        gcr3-base \
        gd \
        gdbm \
        gdbm-libs \
        gdk-pixbuf2 \
        gdk-pixbuf2-modules \
        geoclue2 \
        geoclue2-libs \
        geocode-glib \
        gettext \
        gettext-envsubst \
        gettext-libs \
        gettext-runtime \
        ghostscript \
        ghostscript-tools-fonts \
        ghostscript-tools-printing \
        giflib \
        git-core \
        git-core-doc \
        gjs \
        glib-networking \
        glib2 \
        glibc \
        glibc-all-langpacks \
        glibc-common \
        glibc-gconv-extra \
        glibmm2.68 \
        glx-utils \
        glycin-loaders \
        gmp \
        gnome-autoar \
        gnome-bluetooth \
        gnome-bluetooth-libs \
        gnome-browser-connector \
        gnome-calculator \
        gnome-characters \
        gnome-clocks \
        gnome-color-manager \
        gnome-control-center-filesystem \
        gnome-desktop3 \
        gnome-desktop4 \
        gnome-disk-utility \
        gnome-font-viewer \
        gnome-initial-setup \
        gnome-keyring \
        gnome-keyring-pam \
        gnome-menus \
        gnome-online-accounts \
        gnome-remote-desktop \
        gnome-session \
        gnome-session-wayland-session \
        gnome-settings-daemon \
        gnome-shell-extension-background-logo \
        gnome-software-fedora-langpacks \
        gnome-system-monitor \
        gnome-tour \
        gnome-user-docs \
        gnupg2 \
        gnupg2-smime \
        gnutls \
        gobject-introspection \
        google-droid-sans-fonts \
        google-noto-color-emoji-fonts \
        google-noto-emoji-fonts \
        google-noto-fonts-common \
        google-noto-naskh-arabic-vf-fonts \
        google-noto-sans-arabic-vf-fonts \
        google-noto-sans-armenian-vf-fonts \
        google-noto-sans-bengali-vf-fonts \
        google-noto-sans-canadian-aboriginal-vf-fonts \
        google-noto-sans-cherokee-vf-fonts \
        google-noto-sans-cjk-vf-fonts \
        google-noto-sans-devanagari-vf-fonts \
        google-noto-sans-ethiopic-vf-fonts \
        google-noto-sans-georgian-vf-fonts \
        google-noto-sans-gujarati-vf-fonts \
        google-noto-sans-gurmukhi-vf-fonts \
        google-noto-sans-hebrew-vf-fonts \
        google-noto-sans-kannada-vf-fonts \
        google-noto-sans-khmer-vf-fonts \
        google-noto-sans-lao-vf-fonts \
        google-noto-sans-math-fonts \
        google-noto-sans-meetei-mayek-vf-fonts \
        google-noto-sans-mono-cjk-vf-fonts \
        google-noto-sans-mono-vf-fonts \
        google-noto-sans-ol-chiki-vf-fonts \
        google-noto-sans-oriya-vf-fonts \
        google-noto-sans-sinhala-vf-fonts \
        google-noto-sans-symbols-2-fonts \
        google-noto-sans-symbols-vf-fonts \
        google-noto-sans-tamil-vf-fonts \
        google-noto-sans-telugu-vf-fonts \
        google-noto-sans-thaana-vf-fonts \
        google-noto-sans-thai-vf-fonts \
        google-noto-sans-vf-fonts \
        google-noto-serif-armenian-vf-fonts \
        google-noto-serif-bengali-vf-fonts \
        google-noto-serif-cjk-vf-fonts \
        google-noto-serif-devanagari-vf-fonts \
        google-noto-serif-ethiopic-vf-fonts \
        google-noto-serif-georgian-vf-fonts \
        google-noto-serif-gujarati-vf-fonts \
        google-noto-serif-gurmukhi-vf-fonts \
        google-noto-serif-hebrew-vf-fonts \
        google-noto-serif-kannada-vf-fonts \
        google-noto-serif-khmer-vf-fonts \
        google-noto-serif-lao-vf-fonts \
        google-noto-serif-oriya-vf-fonts \
        google-noto-serif-sinhala-vf-fonts \
        google-noto-serif-tamil-vf-fonts \
        google-noto-serif-telugu-vf-fonts \
        google-noto-serif-thai-vf-fonts \
        google-noto-serif-vf-fonts \
        gpgme \
        gpgmepp \
        graphene \
        graphite2 \
        grep \
        groff-base \
        grub2-common \
        grub2-efi-x64 \
        grub2-tools \
        grub2-tools-extra \
        grub2-tools-minimal \
        grubby \
        gsettings-desktop-schemas \
        gsm \
        gsound \
        gssproxy \
        gstreamer1 \
        gstreamer1-plugins-bad-free \
        gstreamer1-plugins-bad-free-libs \
        gstreamer1-plugins-base \
        gstreamer1-plugins-good \
        gstreamer1-plugins-ugly-free \
        gtk-update-icon-cache \
        gtk3 \
        gtk4 \
        gtkmm4.0 \
        gtksourceview5 \
        gutenprint \
        gutenprint-cups \
        gutenprint-doc \
        gutenprint-libs \
        gvfs \
        gvfs-client \
        gvfs-fuse \
        gvfs-goa \
        gvfs-gphoto2 \
        gvfs-mtp \
        gvfs-smb \
        gzip \
        harfbuzz \
        hdparm \
        hicolor-icon-theme \
        hostname \
        hplip-common \
        hplip-libs \
        hunspell \
        hunspell-de \
        hunspell-en-GB \
        hunspell-en-US \
        hunspell-filesystem \
        hwdata \
        hyperv-daemons \
        hyperv-daemons-license \
        hypervfcopyd \
        hypervkvpd \
        hypervvssd \
        ibus \
        ibus-anthy \
        ibus-anthy-python \
        ibus-gtk3 \
        ibus-hangul \
        ibus-libpinyin \
        ibus-libs \
        ibus-libzhuyin \
        ibus-m17n \
        ibus-setup \
        ibus-typing-booster \
        iio-sensor-proxy \
        ima-evm-utils \
        inih \
        inih-cpp \
        initscripts-rename-device \
        initscripts-service \
        insights-client \
        insights-core \
        insights-core-selinux \
        intel-audio-firmware \
        intel-gpu-firmware \
        intel-vsc-firmware \
        ipp-usb \
        iproute \
        iproute-tc \
        ipset \
        ipset-libs \
        iptables-libs \
        iptables-nft \
        iputils \
        irqbalance \
        iscsi-initiator-utils \
        iscsi-initiator-utils-iscsiuio \
        isns-utils-libs \
        iso-codes \
        itstool \
        iw \
        iwlwifi-dvm-firmware \
        iwlwifi-mvm-firmware \
        jansson \
        jbig2dec-libs \
        jbigkit-libs \
        jomolhari-fonts \
        jose \
        jq \
        json-c \
        json-glib \
        kasumi-common \
        kasumi-unicode \
        kbd \
        kbd-legacy \
        kbd-misc \
        kdump-utils \
        kernel \
        kernel-core \
        kernel-modules \
        kernel-modules-core \
        kernel-modules-extra \
        kernel-tools \
        kernel-tools-libs \
        kexec-tools \
        keyutils \
        keyutils-libs \
        kmod \
        kmod-libs \
        kpartx \
        kpatch \
        kpatch-dnf \
        krb5-libs \
        kyotocabinet-libs \
        lame-libs \
        langpacks-core-de \
        langpacks-de \
        langpacks-fonts-de \
        langtable \
        lcms2 \
        ledmon \
        ledmon-libs \
        less \
        libICE \
        libSM \
        libX11 \
        libX11-common \
        libX11-xcb \
        libXau \
        libXcomposite \
        libXcursor \
        libXdamage \
        libXdmcp \
        libXext \
        libXfixes \
        libXfont2 \
        libXft \
        libXi \
        libXinerama \
        libXpm \
        libXrandr \
        libXrender \
        libXres \
        libXtst \
        libXv \
        libXxf86vm \
        liba52 \
        libacl \
        libadwaita \
        libaio \
        libao \
        libarchive \
        libassuan \
        libasyncns \
        libatasmart \
        libatomic \
        libattr \
        libbabeltrace \
        libbasicobjects \
        libblkid \
        libblockdev \
        libblockdev-crypto \
        libblockdev-fs \
        libblockdev-loop \
        libblockdev-lvm \
        libblockdev-mdraid \
        libblockdev-nvme \
        libblockdev-part \
        libblockdev-smart \
        libblockdev-swap \
        libblockdev-utils \
        libbpf \
        libbrotli \
        libbytesize \
        libcamera \
        libcamera-ipa \
        libcanberra \
        libcanberra-gtk3 \
        libcap \
        libcap-ng \
        libcap-ng-python3 \
        libcbor \
        libcdio \
        libcollection \
        libcom_err \
        libcomps \
        libconfig \
        libcupsfilters \
        libcurl \
        libdaemon \
        libdatrie \
        libdecor \
        libdex \
        libdhash \
        libdisplay-info \
        libdnf \
        libdnf-plugin-subscription-manager \
        libdrm \
        libdvdnav \
        libdvdread \
        libeconf \
        libedit \
        libei \
        libeis \
        libepoxy \
        liberation-fonts-common \
        liberation-mono-fonts \
        libertas-firmware \
        libestr \
        libev \
        libevdev \
        libevent \
        libexif \
        libfastjson \
        libfdisk \
        libffi \
        libfido2 \
        libfontenc \
        libfprint \
        libgcc \
        libgcrypt \
        libgee \
        libgexiv2 \
        libglvnd \
        libglvnd-egl \
        libglvnd-gles \
        libglvnd-glx \
        libglvnd-opengl \
        libgomp \
        libgpg-error \
        libgphoto2 \
        libgs \
        libgsf \
        libgtop2 \
        libgudev \
        libgusb \
        libgweather \
        libgxps \
        libhandy \
        libhangul \
        libibverbs \
        libical \
        libical-glib \
        libicu \
        libidn2 \
        libieee1284 \
        libijs \
        libini_config \
        libinput \
        libipa_hbac \
        libiptcdata \
        libjcat \
        libjose \
        libjpeg-turbo \
        libkcapi \
        libkcapi-hasher \
        libkcapi-hmaccalc \
        libksba \
        liblc3 \
        libldac \
        libldb \
        liblerc \
        liblouis \
        liblouis-tables \
        libluksmeta \
        libmaxminddb \
        libmbim \
        libmbim-utils \
        libmnl \
        libmodulemd \
        libmount \
        libmpc \
        libmpeg2 \
        libmspack \
        libmtp \
        libndp \
        libnet \
        libnetfilter_conntrack \
        libnfnetlink \
        libnfsidmap \
        libnftnl \
        libnghttp2 \
        libnl3 \
        libnma \
        libnma-gtk4 \
        libnotify \
        libnvme \
        liboeffis \
        libogg \
        libosinfo \
        libpaper \
        libpath_utils \
        libpcap \
        libpciaccess \
        libpinyin \
        libpinyin-data \
        libpipeline \
        libpkgconf \
        libpng \
        libportal \
        libportal-gtk4 \
        libppd \
        libproxy \
        libpsl \
        libpwquality \
        libqmi \
        libqmi-utils \
        libqrtr-glib \
        libref_array \
        librelp \
        librepo \
        librhsm \
        librsvg2 \
        librsvg2-tools \
        libsamplerate \
        libsane-airscan \
        libsane-hpaio \
        libsbc \
        libseccomp \
        libsecret \
        libselinux \
        libselinux-utils \
        libsemanage \
        libsepol \
        libshout \
        libsigc++30 \
        libsmartcols \
        libsmbclient \
        libsndfile \
        libsolv \
        libsoup3 \
        libspelling \
        libsrtp \
        libss \
        libssh \
        libssh-config \
        libsss_certmap \
        libsss_idmap \
        libsss_nss_idmap \
        libsss_sudo \
        libstdc++ \
        libstoragemgmt \
        libsysfs \
        libtalloc \
        libtasn1 \
        libtdb \
        libtevent \
        libthai \
        libtheora \
        libtiff \
        libtirpc \
        libtool-ltdl \
        libtraceevent \
        libtracker-sparql \
        libudisks2 \
        libunistring \
        liburing \
        libusb1 \
        libutempter \
        libuuid \
        libuv \
        libv4l \
        libva \
        libverto \
        libverto-libev \
        libvorbis \
        libvpx \
        libwacom \
        libwacom-data \
        libwayland-client \
        libwayland-cursor \
        libwayland-egl \
        libwayland-server \
        libwbclient \
        libwebp \
        libwinpr \
        libwnck3 \
        libxcb \
        libxcrypt \
        libxcvt \
        libxkbcommon \
        libxkbcommon-x11 \
        libxkbfile \
        libxml2 \
        libxmlb \
        libxshmfence \
        libxslt \
        libyaml \
        libzhuyin \
        libzstd \
        linux-firmware \
        linux-firmware-whence \
        llvm-filesystem \
        llvm-libs \
        lmdb-libs \
        lockdev \
        logrotate \
        loupe \
        low-memory-monitor \
        lrzsz \
        lshw \
        lsof \
        lsscsi \
        lua-libs \
        luksmeta \
        lvm2 \
        lvm2-libs \
        lz4-libs \
        lzo \
        m17n-db \
        m17n-lib \
        madan-fonts \
        mailcap \
        makedumpfile \
        mallard-rng \
        man-db \
        man-pages \
        mcelog \
        mdadm \
        memstrack \
        mesa-dri-drivers \
        mesa-filesystem \
        mesa-libEGL \
        mesa-libGL \
        mesa-libgbm \
        mesa-vulkan-drivers \
        microcode_ctl \
        mobile-broadband-provider-info \
        mokutil \
        mozilla-filesystem \
        mpdecimal \
        mpfr \
        mpg123-libs \
        mt7xxx-firmware \
        mtdev \
        mtools \
        mtr \
        mutter \
        mutter-common \
        nautilus-extensions \
        ncurses \
        ncurses-base \
        ncurses-libs \
        net-snmp-libs \
        net-tools \
        netavark \
        netronome-firmware \
        nettle \
        newt \
        nfs-utils \
        nftables \
        nm-connection-editor \
        nmap-ncat \
        npth \
        nspr \
        nss \
        nss-softokn \
        nss-softokn-freebl \
        nss-sysinit \
        nss-util \
        numactl-libs \
        nvidia-gpu-firmware \
        nvme-cli \
        nxpwireless-firmware \
        oniguruma \
        open-vm-tools \
        open-vm-tools-desktop \
        openjpeg2 \
        openldap \
        openssh \
        openssh-clients \
        openssh-server \
        openssl \
        openssl-fips-provider \
        openssl-fips-provider-so \
        openssl-libs \
        opus \
        orc \
        orca \
        os-prober \
        osinfo-db \
        osinfo-db-tools \
        ostree-libs \
        p11-kit \
        p11-kit-client \
        p11-kit-server \
        p11-kit-trust \
        paktype-naskh-basic-fonts \
        pam \
        pam-libs \
        pango \
        pangomm2.48 \
        papers \
        papers-libs \
        papers-nautilus \
        papers-previewer \
        papers-thumbnailer \
        paps \
        parted \
        passt \
        passt-selinux \
        pcaudiolib \
        pciutils \
        pciutils-libs \
        pcre2 \
        pcre2-syntax \
        pcre2-utf16 \
        pcre2-utf32 \
        pcsc-lite \
        pcsc-lite-ccid \
        pcsc-lite-libs \
        perl-AutoLoader \
        perl-B \
        perl-Carp \
        perl-Class-Struct \
        perl-Data-Dumper \
        perl-Digest \
        perl-Digest-MD5 \
        perl-DynaLoader \
        perl-Encode \
        perl-Errno \
        perl-Error \
        perl-Exporter \
        perl-Fcntl \
        perl-File-Basename \
        perl-File-Find \
        perl-File-Path \
        perl-File-Temp \
        perl-File-stat \
        perl-FileHandle \
        perl-Getopt-Long \
        perl-Getopt-Std \
        perl-Git \
        perl-HTTP-Tiny \
        perl-IO \
        perl-IO-Socket-IP \
        perl-IO-Socket-SSL \
        perl-IPC-Open3 \
        perl-MIME-Base64 \
        perl-Mozilla-CA \
        perl-NDBM_File \
        perl-Net-SSLeay \
        perl-POSIX \
        perl-PathTools \
        perl-Pod-Escapes \
        perl-Pod-Perldoc \
        perl-Pod-Simple \
        perl-Pod-Usage \
        perl-Scalar-List-Utils \
        perl-SelectSaver \
        perl-Socket \
        perl-Storable \
        perl-Symbol \
        perl-Term-ANSIColor \
        perl-Term-Cap \
        perl-TermReadKey \
        perl-Text-ParseWords \
        perl-Text-Tabs+Wrap \
        perl-Time-Local \
        perl-URI \
        perl-base \
        perl-constant \
        perl-if \
        perl-interpreter \
        perl-lib \
        perl-libnet \
        perl-libs \
        perl-locale \
        perl-mro \
        perl-overload \
        perl-overloading \
        perl-parent \
        perl-podlators \
        perl-vars \
        pigz \
        pinentry \
        pinentry-gnome3 \
        pipewire-gstreamer \
        pipewire-jack-audio-connection-kit \
        pipewire-jack-audio-connection-kit-libs \
        pipewire-libs \
        pipewire-plugin-libcamera \
        pipewire-utils \
        pixman \
        pkcs11-provider \
        pkgconf \
        pkgconf-m4 \
        pkgconf-pkg-config \
        plocate \
        plymouth \
        plymouth-core-libs \
        plymouth-graphics-libs \
        plymouth-plugin-label \
        plymouth-plugin-two-step \
        plymouth-scripts \
        plymouth-system-theme \
        plymouth-theme-spinner \
        pnm2ppa \
        podman \
        podman-sequoia \
        policycoreutils \
        policycoreutils-python-utils \
        polkit \
        polkit-libs \
        polkit-pkla-compat \
        poppler \
        poppler-cpp \
        poppler-data \
        poppler-glib \
        poppler-utils \
        popt \
        prefixdevname \
        procps-ng \
        protobuf-c \
        psacct \
        psmisc \
        pt-sans-fonts \
        publicsuffix-list-dafsa \
        pulseaudio-libs \
        pulseaudio-libs-glib2 \
        python-unversioned-command \
        python3 \
        python3-argcomplete \
        python3-attrs \
        python3-audit \
        python3-brlapi \
        python3-cairo \
        python3-charset-normalizer \
        python3-cloud-what \
        python3-cups \
        python3-dasbus \
        python3-dateutil \
        python3-dbus \
        python3-decorator \
        python3-distro \
        python3-dnf \
        python3-dnf-plugins-core \
        python3-enchant \
        python3-file-magic \
        python3-firewall \
        python3-gobject \
        python3-gobject-base \
        python3-gobject-base-noarch \
        python3-greenlet \
        python3-hawkey \
        python3-idna \
        python3-iniparse \
        python3-inotify \
        python3-jsonschema \
        python3-jsonschema-specifications \
        python3-langtable \
        python3-libcomps \
        python3-libdnf \
        python3-librepo \
        python3-libs \
        python3-libselinux \
        python3-libsemanage \
        python3-libstoragemgmt \
        python3-libxml2 \
        python3-linux-procfs \
        python3-louis \
        python3-lxml \
        python3-markdown \
        python3-nftables \
        python3-packaging \
        python3-pam \
        python3-perf \
        python3-pexpect \
        python3-pip-wheel \
        python3-policycoreutils \
        python3-ptyprocess \
        python3-pyatspi \
        python3-pyudev \
        python3-pyxdg \
        python3-pyyaml \
        python3-referencing \
        python3-requests \
        python3-rpds-py \
        python3-rpm \
        python3-setools \
        python3-setuptools \
        python3-six \
        python3-speechd \
        python3-sqlalchemy \
        python3-subscription-manager-rhsm \
        python3-systemd \
        python3-typing-extensions \
        python3-urllib3 \
        qemu-guest-agent \
        qpdf-libs \
        qt6-filesystem \
        qt6-qtbase \
        qt6-qtbase-common \
        qt6-qtbase-gui \
        qt6-qtdeclarative \
        qt6-qtsvg \
        qt6-qttranslations \
        qt6-qtwayland \
        quota \
        quota-nls \
        readline \
        realmd \
        realtek-firmware \
        redhat-backgrounds \
        redhat-display-vf-fonts \
        #redhat-flatpak-repo \
        redhat-logos \
        redhat-mono-vf-fonts \
        redhat-release \
        redhat-release-eula \
        redhat-text-vf-fonts \
        rest \
        rhc \
        rhsm-icons \
        rit-meera-new-fonts \
        rit-rachana-fonts \
        rootfiles \
        rpcbind \
        rpm \
        rpm-build-libs \
        rpm-libs \
        rpm-plugin-audit \
        rpm-plugin-selinux \
        rpm-plugin-systemd-inhibit \
        rpm-sequoia \
        rpm-sign-libs \
        rsvg-pixbuf-loader \
        rsync \
        rsyslog \
        rsyslog-gnutls \
        rsyslog-gssapi \
        rsyslog-relp \
        rtkit \
        samba-client-libs \
        samba-common \
        samba-common-libs \
        sane-airscan \
        sane-backends \
        sane-backends-drivers-cameras \
        sane-backends-drivers-scanners \
        sane-backends-libs \
        sed \
        selinux-policy \
        selinux-policy-targeted \
        sequoia-sq \
        setroubleshoot \
        setroubleshoot-plugins \
        setroubleshoot-server \
        setup \
        sg3_utils \
        sg3_utils-libs \
        shadow-utils \
        shadow-utils-subid \
        shared-mime-info \
        shim-x64 \
        sil-padauk-fonts \
        slang \
        smartmontools \
        smartmontools-selinux \
        snappy \
        snapshot \
        sos \
        sound-theme-freedesktop \
        soundtouch \
        speech-dispatcher \
        speech-dispatcher-espeak-ng \
        speex \
        spice-vdagent \
        spirv-tools-libs \
        sqlite-libs \
        sscg \
        sssd \
        sssd-ad \
        sssd-client \
        sssd-common \
        sssd-common-pac \
        sssd-ipa \
        sssd-kcm \
        sssd-krb5 \
        sssd-krb5-common \
        sssd-ldap \
        sssd-nfs-idmap \
        sssd-proxy \
        startup-notification \
        stix-fonts \
        strace \
        subscription-manager \
        subscription-manager-cockpit \
        subscription-manager-rhsm-certificates \
        sudo \
        sudo-python-plugin \
        switcheroo-control \
        symlinks \
        system-config-printer-libs \
        system-config-printer-udev \
        systemd \
        systemd-libs \
        systemd-pam \
        systemd-udev \
        taglib \
        tcpdump \
        tecla \
        telnet \
        time \
        tiwilink-firmware \
        toolbox \
        tpm2-tools \
        tpm2-tss \
        tpm2-tss-fapi \
        traceroute \
        tracker \
        tracker-miners \
        tree \
        twolame-libs \
        tzdata \
        udisks2 \
        udisks2-iscsi \
        udisks2-lvm2 \
        unicode-ucd \
        upower \
        upower-libs \
        urw-base35-bookman-fonts \
        urw-base35-c059-fonts \
        urw-base35-d050000l-fonts \
        urw-base35-fonts \
        urw-base35-fonts-common \
        urw-base35-gothic-fonts \
        urw-base35-nimbus-mono-ps-fonts \
        urw-base35-nimbus-roman-fonts \
        urw-base35-nimbus-sans-fonts \
        urw-base35-p052-fonts \
        urw-base35-standard-symbols-ps-fonts \
        urw-base35-z003-fonts \
        usbutils \
        userspace-rcu \
        util-linux \
        util-linux-core \
        vazirmatn-vf-fonts \
        vim-common \
        vim-data \
        vim-enhanced \
        vim-filesystem \
        vim-minimal \
        virt-what \
        volume_key-libs \
        vte-profile \
        vte291 \
        vte291-gtk4 \
        vulkan-loader \
        wavpack \
        webrtc-audio-processing \
        which \
        wireguard-tools \
        wireless-regdb \
        wireplumber-libs \
        words \
        wpa_supplicant \
        wsdd \
        xcb-util \
        xcb-util-cursor \
        xcb-util-image \
        xcb-util-keysyms \
        xcb-util-renderutil \
        xcb-util-wm \
        xdg-dbus-proxy \
        xdg-desktop-portal-gnome \
        xdg-user-dirs-gtk \
        xdg-utils \
        xfsdump \
        xfsprogs \
        xkbcomp \
        xkeyboard-config \
        xml-common \
        xmlsec1 \
        xmlsec1-openssl \
        xorg-x11-server-Xwayland \
        xprop \
        xxd \
        xz \
        xz-libs \
        yelp-tools \
        yelp-xsl \
        yggdrasil \
        yggdrasil-worker-package-manager \
        yum \
        zip \
        zlib-ng-compat \
    && dnf clean all
RUN rm -rf /var/cache/dnf/*

######

######

# -----------------------------------------------------------------------------
# System-weit: Default-Tuned-Profil einmalig setzen
# -----------------------------------------------------------------------------
RUN mkdir -p /usr/libexec /usr/lib/systemd/system

RUN cat > /usr/libexec/system-firstboot-setup <<'EOF'
#!/bin/bash
set -euo pipefail

STAMP="/var/lib/silverred/firstboot-setup.done"
[ -f "$STAMP" ] && exit 0
mkdir -p "$(dirname "$STAMP")"

tuned-adm profile balanced

touch "$STAMP"
EOF

RUN chmod +x /usr/libexec/system-firstboot-setup

RUN cat > /usr/lib/systemd/system/system-firstboot-setup.service <<'EOF'
[Unit]
Description=Einmaliges System-Setup nach dem ersten Boot
After=tuned.service
Requires=tuned.service
ConditionPathExists=!/var/lib/silverred/firstboot-setup.done

[Service]
Type=oneshot
ExecStart=/usr/libexec/system-firstboot-setup
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

RUN systemctl enable system-firstboot-setup.service

# -----------------------------------------------------------------------------
# Per-User: lokale Desktop-Einstellungen via dconf-Defaults (Best Practice)
# -----------------------------------------------------------------------------
# Statt eines "gsettings"-Skripts als systemd --user Oneshot-Service (Race
# Condition mit D-Bus/graphical-session.target, braucht Stamp-Datei, greift
# erst NACH dem ersten Login): dconf-System-Defaults gelten sofort für jeden
# über gnome-initial-setup angelegten Benutzer, ohne Skript, ohne Session-
# Abhängigkeit. Es sind Defaults (kein "dconf update"-Lock), Benutzer können
# sie in den Einstellungen jederzeit selbst überschreiben.
RUN mkdir -p /etc/dconf/db/local.d /etc/dconf/profile

RUN cat > /etc/dconf/profile/user <<'EOF'
user-db:user
system-db:local
EOF

RUN cat > /etc/dconf/db/local.d/00-silverred-defaults <<'EOF'
[org/gnome/shell]
enabled-extensions=['caffeine@patapon.info', 'gjsosk@vishram1123.com', 'battery-usage-wattmeter@halfmexicanhalfamazing.gmail.com']
disabled-extensions=['background-logo@fedorahosted.org']

[org/gnome/desktop/wm/preferences]
button-layout=':minimize,close'

[org/gnome/desktop/sound]
allow-volume-above-100-percent=true

[org/gnome/desktop/interface]
enable-animations=false
clock-show-weekday=true
show-battery-percentage=true
accent-color='red'

EOF

# dconf update kompiliert die Textdateien in /etc/dconf/db/local.d/ zur
# binären local-DB (/etc/dconf/db/local) - ohne diesen Schritt bleiben die
# Defaults wirkungslos.
RUN dconf update

# -----------------------------------------------------------------------------
# Flatpak - AUSSCHLIESSLICH --user
# -----------------------------------------------------------------------------
# Kein "set -e": ein einzelner fehlgeschlagener Remote/Download soll nicht
# alles Weitere verhindern. Der Stamp wird erst gesetzt, wenn WIRKLICH alle
# Schritte durchgelaufen sind - schlägt z.B. das Netzwerk beim ersten Login
# fehl (Laptop noch ohne WLAN), versucht es der Service beim nächsten Login
# einfach erneut, statt für immer im Fehlerzustand zu hängen.
# -----------------------------------------------------------------------------
# Flatpak User-Repositories für neu angelegte Benutzer initialisieren
# -----------------------------------------------------------------------------

RUN install -d /usr/lib/systemd/user && \
cat > /usr/lib/systemd/user/flatpak-user-setup.service <<'EOF'
[Unit]
Description=Initialize Flatpak user repositories
ConditionPathExists=!%h/.local/share/flatpak/.repos-initialized

[Service]
Type=oneshot
ExecStart=/usr/bin/bash -c '\
mkdir -p "$HOME/.local/share/flatpak" && \
flatpak remote-add --user --if-not-exists fedora oci+https://registry.fedoraproject.org && \
flatpak remote-add --user --if-not-exists rhel https://flatpaks.redhat.io/rhel.flatpakrepo && \
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo && \
flatpak install -y --user flathub org.mozilla.firefox && \
touch "$HOME/.local/share/flatpak/.repos-initialized"'

[Install]
WantedBy=default.target
#WantedBy=graphical-session.target
EOF

RUN install -d /etc/systemd/user/default.target.wants && \
ln -sf /usr/lib/systemd/user/flatpak-user-setup.service \
          /etc/systemd/user/default.target.wants/flatpak-user-setup.service


######
# -----------------------------------------------------------------------------
# 4) Locale, Tastatur & Zeitzone
# -----------------------------------------------------------------------------
# 1. Neo2-Konsolenkeymap besorgen
RUN curl -fsSL "https://neo-layout.org/download/console.tar.xz" \
    | tar -C /usr/lib/kbd/keymaps/ -xJ

## 2. vconsole.conf setzen
#RUN cat <<'EOF' > /etc/vconsole.conf
#KEYMAP=neo
#EOF

# 3. sicherstellen, dass dracut das i18n-Modul (vconsole-Setup) einbaut
RUN cat <<'EOF' > /usr/lib/dracut/dracut.conf.d/99-i18n.conf
add_dracutmodules+=" i18n "
EOF

# 4. initrd für den im Image enthaltenen Kernel neu bauen passiert zentral am ende
#RUN set -x; kver=$(cd /usr/lib/modules && echo #*); \
#    dracut -vf /usr/lib/modules/$kver/#initramfs.img $kver

RUN mkdir -p /usr/lib/systemd/system/bootc-fetch-apply-updates.service.d && \
    cat > /usr/lib/systemd/system/bootc-fetch-apply-updates.service.d/no-forced-reboot.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/bootc upgrade
EOF

# zram-Swap (komprimiertes RAM statt/zusätzlich zu klassischer Swap-Partition)
RUN mkdir -p /etc/systemd && \
    cat <<'EOF' > /etc/systemd/zram-generator.conf
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
swap-priority = 100
EOF

# -----------------------------------------------------------------------------
# 5) Desktop als Standard-Ziel setzen & Dienste aktivieren
# -----------------------------------------------------------------------------
RUN systemctl set-default graphical.target && \
    systemctl enable gdm.service && \
    systemctl enable NetworkManager.service && \
    systemctl enable bluetooth.service && \
    systemctl enable thermald.service && \
    systemctl enable tuned.service && \
    systemctl enable cups.service && \
    systemctl enable fstrim.timer && \
    systemctl enable virtqemud.socket && \
    systemctl enable virtnetworkd.socket && \
    systemctl enable bootc-fetch-apply-updates.timer && \
    systemctl enable ostree-finalize-staged.service

# -----------------------------------------------------------------------------
# 6) FIDO2-Unterstützung & Plymouth-Bootscreen
# -----------------------------------------------------------------------------
RUN echo 'add_dracutmodules+=" fido2 "' > /etc/dracut.conf.d/fido2.conf

RUN plymouth-set-default-theme spinner

RUN mkdir -p /usr/lib/bootc/kargs.d && \
    cat <<'EOF' >> /usr/lib/bootc/kargs.d/01-plymouth.toml
kargs = ["rhgb", "quiet"]
match-architectures = ["x86_64", "aarch64"]
EOF

# EIN einziger, finaler Dracut-Lauf für ALLE initramfs-relevanten Änderungen
RUN set -x; kver=$(cd /usr/lib/modules && echo *); \
    dracut --force -v /usr/lib/modules/${kver}/initramfs.img ${kver}

# -----------------------------------------------------------------------------
# 7) Passwortloses sudo & doas für die "wheel"-Gruppe
# -----------------------------------------------------------------------------
COPY --chmod=0440 etc/sudoers.d/wheel-nopasswd /etc/sudoers.d/wheel-nopasswd
COPY --chmod=0600 --chown=root:root etc/doas.conf /etc/doas.conf

# SELinux Fix für doas
RUN restorecon -v /usr/bin/doas

# -----------------------------------------------------------------------------
# 8) Hostname
# -----------------------------------------------------------------------------
COPY --chmod=0644 etc/hostname /etc/hostname

#ARG CACHE_BUST=1

# -----------------------------------------------------------------------------
# 9) Branding: Hintergründe, Logos, Bootscreen-Wasserzeichen, Icon
# -----------------------------------------------------------------------------
COPY --chmod=0644 usr/share/backgrounds/rhel10-iso-d.png /usr/share/backgrounds/rhel10-iso-d.png
COPY --chmod=0644 usr/share/backgrounds/rhel10-iso-l.png /usr/share/backgrounds/rhel10-iso-l.png
COPY --chmod=0644 usr/share/backgrounds/rhel10-3D-d.png /usr/share/backgrounds/rhel10-3D-d.png
COPY --chmod=0644 usr/share/backgrounds/rhel10-3D-l.png /usr/share/backgrounds/rhel10-3D-l.png
COPY --chmod=0644 usr/share/backgrounds/rhel10-blobs-d.png /usr/share/backgrounds/rhel10-blobs-d.png
COPY --chmod=0644 usr/share/backgrounds/rhel10-blobs-l.png /usr/share/backgrounds/rhel10-blobs-l.png
#COPY --chmod=0644 usr/share/pixmaps/fedora-logo.png /usr/share/pixmaps/fedora-logo.png
#COPY --chmod=0644 usr/share/pixmaps/fedora-logo.ico /usr/share/pixmaps/fedora-logo.ico
#COPY --chmod=0644 usr/share/plymouth/themes/spinner/watermark.png /usr/share/plymouth/themes/spinner/watermark.png
#COPY --chmod=0644 usr/share/icons/hicolor/scalable/apps/start-here.svg /usr/share/icons/hicolor/scalable/apps/start-here2.svg


# -----------------------------------------------------------------------------
# 10) Setup-Skript & GNOME-Erweiterungen
# -----------------------------------------------------------------------------
COPY --chmod=0644 usr/share/applications/update.desktop /usr/share/applications/update.desktop
COPY --chmod=0755 usr/local/bin/update.sh /usr/local/bin/update.sh
COPY --chmod=0755 usr/share/gnome-shell/extensions/ /usr/share/gnome-shell/extensions/


# -----------------------------------------------------------------------------
# 11) gnome-initial-setup
# -----------------------------------------------------------------------------

COPY --chmod=0644 etc/gdm/custom.conf /etc/gdm/custom.conf
RUN mkdir -p /var/lib/gdm
RUN touch /var/lib/gdm/run-initial-setup

RUN mkdir -p /etc/gnome-initial-setup && \
    cat > /etc/gnome-initial-setup/vendor.conf <<'EOF'
[pages]
EOF


# --- Firewallregeln

RUN firewall-offline-cmd --add-service=cockpit

# -----------------------------------------------------------------------------
# 12) Abschließende Prüfung
# -----------------------------------------------------------------------------
# bootc container lint erst hier ausgeführt (vorher mitten im Build, vor
# Branding/Setup-Skripten) – so wird wirklich der fertige, komplette
# Image-Zustand geprüft und nicht nur ein Zwischenstand.
RUN bootc container lint

# CMD wird beim bootc-Deployment auf ein reales System ignoriert, ist aber
# nötig, damit das Image auch als gewöhnlicher Container (zum Testen mit
# `podman run`) startet.
CMD ["/sbin/init"]
