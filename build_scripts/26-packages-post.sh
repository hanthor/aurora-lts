#!/usr/bin/env bash

set -xeuo pipefail

# Fancy CentOS icon on the fastfetch (only if file exists)
if [ -f /usr/share/ublue-os/fastfetch.jsonc ]; then
  sed -i "s/󰣛//g" /usr/share/ublue-os/fastfetch.jsonc
fi

# Fix 1969 date getting returned on Fastfetch (upstream issue)
# FIXME: check if this issue is fixed upstream at some point. (28-02-2025) https://github.com/ostreedev/ostree/issues/1469
if [ -f /usr/share/ublue-os/fastfetch.jsonc ]; then
  sed -i -e "s@ls -alct /@&var/log@g" /usr/share/ublue-os/fastfetch.jsonc
fi

# Add Flathub by default
mkdir -p /etc/flatpak/remotes.d
curl --retry 3 -o /etc/flatpak/remotes.d/flathub.flatpakrepo "https://dl.flathub.org/repo/flathub.flatpakrepo"
install -Dm0644 -t /etc/ublue-os/ /run/context/flatpaks/*.list

/usr/sbin/depmod -a `ls -1 /lib/modules/ | tail -1`

# Fix for Ptyxis Ctrl+Arrow keys not working in Zsh
# https://gitlab.gnome.org/GNOME/ptyxis/-/issues/16
cat >> /etc/zshrc <<EOF

# Fix for Ptyxis Ctrl+Left/Right
bindkey "\e[1;5C" forward-word
bindkey "\e[1;5D" backward-word
bindkey "\e[5C" forward-word
bindkey "\e[5D" backward-word
EOF

# Git clone aurora and get the Bazaar config and copy it over
# mkdir -p "/usr/share/ublue-os"
# echo "Cloning the repository with depth 1..."
# git clone --depth 1 "https://github.com/ublue-os/aurora.git" "/tmp/aurora_repo"
# cp -avf "/tmp/aurora_repo/system_files/shared/etc/bazaar" "/etc"

# Generate initramfs image after installing Aurora branding because of Plymouth subpackage
# Add resume module so that hibernation works
echo "add_dracutmodules+=\" resume \"" >/etc/dracut.conf.d/resume.conf
KERNEL_SUFFIX=""
QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-(|'"$KERNEL_SUFFIX"'-)(\d+\.\d+\.\d+)' | sed -E 's/kernel-(|'"$KERNEL_SUFFIX"'-)//' | tail -n 1)"
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v --add ostree -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
