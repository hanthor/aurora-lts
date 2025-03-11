#!/bin/bash

set -xeuo pipefail

mkdir -p /etc/xdg && \
    touch /etc/xdg/system.kdeglobals

# Fancy CentOS icon on the fastfetch
sed -i "s/󰣛//g" /usr/share/ublue-os/fastfetch.jsonc

# Fix 1969 date getting returned on Fastfetch (upstream issue)
# FIXME: check if this issue is fixed upstream at some point. (28-02-2025) https://github.com/ostreedev/ostree/issues/1469
sed -i -e "s@ls -alct /@&var/log@g" /usr/share/ublue-os/fastfetch.jsonc

# Automatic wallpaper changing by month
HARDCODED_RPM_MONTH="12"
#sed -i "/picture-uri/ s/${HARDCODED_RPM_MONTH}/$(date +%m)/" "/usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override"
glib-compile-schemas /usr/share/glib-2.0/schemas

ln -sf /usr/share/icons/hicolor/scalable/distributor-logo.svg /usr/share/icons/hicolor/scalable/apps/aurora-helium-logo-icon.svg && \
ln -sf /usr/share/icons/hicolor/scalable/distributor-logo.svg /usr/share/icons/hicolor/scalable/apps/start-here.svg && \
ln -sf /usr/share/icons/hicolor/scalable/distributor-logo.svg /usr/share/icons/hicolor/scalable/apps/xfce4_xicon1.svg && \
ln -sf /usr/share/icons/hicolor/scalable/distributor-logo.svg /usr/share/pixmaps/fedora-logo-sprite.svg

# Required for bluefin faces to work without conflicting with a ton of packages
# rm -f /usr/share/pixmaps/faces/* || echo "Expected directory deletion to fail"
# mv /usr/share/pixmaps/faces/bluefin/* /usr/share/pixmaps/faces
# rm -rf /usr/share/pixmaps/faces/bluefin

# This should only be enabled on `-dx`
# sed -i "/^show-boxbuddy=.*/d" /usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override
sed -i "/.*io.github.dvlv.boxbuddyrs.*/d" /etc/ublue-os/system-flatpaks.list

# Add Flathub by default
mkdir -p /etc/flatpak/remotes.d
curl --retry 3 -o /etc/flatpak/remotes.d/flathub.flatpakrepo "https://dl.flathub.org/repo/flathub.flatpakrepo"

# move the custom just
mv /usr/share/ublue-os/just/61-lts-custom.just /usr/share/ublue-os/just/60-custom.just 


declare -a plasma_themes=("breeze" "breeze-dark")
declare -a icon_sizes=("16" "22" "32" "64" "96")
declare -a start_here_variants=("start-here-kde-plasma.svg" "start-here-kde.svg" "start-here-kde-plasma-symbolic.svg" "start-here-kde-symbolic.svg" "start-here-symbolic.svg")
for plasma_theme in "${plasma_themes[@]}"
do
    for icon_size in "${icon_sizes[@]}"
    do
        for start_here_variant in "${start_here_variants[@]}"
        do
                ln -sf \
                    /usr/share/icons/hicolor/scalable/distributor-logo.svg \
                    /usr/share/icons/${plasma_theme}/places/${icon_size}/${start_here_variant}
        done
    done
done


curl -o /var/tmp/wallpapers.tar.gz https://codeberg.org/HeliumOS/wallpapers/archive/eccec97df37d4d5aee4f23e1e57b46c0e4e6c484.tar.gz && \
    tar -xzf /var/tmp/wallpapers.tar.gz && \
    mv wallpapers /var/tmp/wallpapers


mkdir -p /usr/share/wallpapers/Andromeda/contents/images && \
cp /var/tmp/wallpapers/andromeda.jpg /usr/share/wallpapers/Andromeda/contents/images/5338x5905.jpg && \
cat <<EOF >>/usr/share/wallpapers/Andromeda/metadata.json
{
    "KPlugin": {
        "Authors": [
            {
                "Name": ""
            }
        ],
        "Id": "Andromeda",
        "Name": "Andromeda"
    }
}
EOF


declare -a lookandfeels=("org.kde.breeze.desktop" "org.kde.breezedark.desktop" "org.kde.breezetwilight.desktop")
for lookandfeel in "${lookandfeels[@]}"
do
   sed -i 's,Image=Next,Image=Andromeda,g' /usr/share/plasma/look-and-feel/${lookandfeel}/contents/defaults
done


sed -i 's,background=/usr/share/wallpapers/Next/contents/images/5120x2880.png,background=/usr/share/wallpapers/Andromeda/contents/images/5338x5905.jpg,g' /usr/share/sddm/themes/breeze/theme.conf
sed -i 's,#Current=01-breeze-fedora,Current=breeze,g' /etc/sddm.conf


dnf remove -y \
    lsb_release
rm /etc/redhat-release
echo "HOMEBREW_OS_VERSION='Aurora Helium (LTS)'" >> /etc/profile

# Generate initramfs image after installing Bluefin branding because of Plymouth subpackage
# Add resume module so that hibernation works
echo "add_dracutmodules+=\" resume \"" >/etc/dracut.conf.d/resume.conf
KERNEL_SUFFIX=""
QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-(|'"$KERNEL_SUFFIX"'-)(\d+\.\d+\.\d+)' | sed -E 's/kernel-(|'"$KERNEL_SUFFIX"'-)//' | tail -n 1)"
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v --add ostree -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
