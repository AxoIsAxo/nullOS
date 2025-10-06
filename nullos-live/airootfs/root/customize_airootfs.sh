#!/bin/bash

# =================================================================================
# TEIL 1: LIVE-SYSTEM KONFIGURIEREN (unverändert)
# =================================================================================
set -e -u # Bricht bei Fehlern ab

systemctl enable sddm.service
systemctl enable polkit

useradd -m -G wheel -s /bin/bash liveuser
echo 'liveuser ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/liveuser

mkdir -p /etc/sddm.conf.d
cat <<EOT > /etc/sddm.conf.d/autologin.conf
[Autologin]
User=liveuser
Session=plasma.desktop
EOT

# =================================================================================
# TEIL 2: CALAMARES INSTALLER KONFIGURIEREN (MIT BRANDING-FIX)
# =================================================================================
mkdir -p /etc/calamares/modules

# --- NEU: Branding-Informationen erstellen ---
# Calamares benötigt diese Datei, um den Namen der Distribution zu kennen.
cat <<EOT > /etc/calamares/branding.desc
componentName: NullOS
productName: NullOS
shortProductName: NullOS
version: 2025.10
shortVersion: 2025.10
EOT

# --- Hauptkonfiguration (settings.conf) MIT DEM WICHTIGEN FIX ---
cat <<EOT > /etc/calamares/settings.conf
# NEU: Diese Zeile ist der entscheidende Fix!
branding: default

modules-search: [ /etc/calamares/modules, /usr/share/calamares/modules ]
instance-name: "NullOS Installer"
window-title: "NullOS Installation"
window-icon: "system-installer"
window-width: 800
window-height: 600

sequence:
  - show:
      - welcome
      - partition
      - users
      - summary
  - exec:
      - mount
      - unpackfs
      - machineid
      - fstab
      - users
      - displaymanager
      - bootloader
      - umount
  - show:
      - finished
EOT

# --- Modul-Konfigurationen (wie in der vorletzten Antwort) ---
cat <<EOT > /etc/calamares/modules/welcome.conf
productName: NullOS
productVersion: 2025.10
shortProductName: NullOS
EOT

cat <<EOT > /etc/calamares/modules/partition.conf
efiSystemPartition: "/boot/efi"
efiSystemPartitionSize: 300MB
swap: "none"
EOT

cat <<EOT > /etc/calamares/modules/unpackfs.conf
unpack:
    - source: "/run/archiso/bootmnt/arch/x86_64/airootfs.sfs"
      sourcefs: "squashfs"
      destination: ""
EOT

touch /etc/calamares/modules/fstab.conf
touch /etc/calamares/modules/users.conf

cat <<EOT > /etc/calamares/modules/displaymanager.conf
sddm:
    enable: "sddm.service"
EOT

cat <<EOT > /etc/calamares/modules/bootloader.conf
bootloader: "systemd-boot"
kernel: "/boot/vmlinuz-linux"
img: "/boot/initramfs-linux.img"
efiBootLoader: "/boot/EFI/systemd/systemd-bootx64.efi"
EOT

cat <<EOT > /etc/calamares/modules/finished.conf
showRestart: true
EOT

# =================================================================================
# TEIL 3: INSTALLER-LAUNCHER (unverändert)
# =================================================================================
mkdir -p /usr/share/applications
cat <<EOT > /usr/share/applications/install-nullos.desktop
[Desktop Entry]
Name=Install NullOS
Comment=Install NullOS to your hard drive
Exec=pkexec calamares
Icon=system-installer
Terminal=false
Type=Application
Categories=System;
StartupNotify=true
EOT
