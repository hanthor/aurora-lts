#!/usr/bin/env bash

set -xeuo pipefail

ARCH=$(uname -m)

# This is the base for a minimal GNOME system on CentOS Stream.

# This thing slows down downloads A LOT for no reason
dnf remove -y subscription-manager
dnf -y install 'dnf-command(versionlock)'

/run/context/build_scripts/scripts/kernel-swap.sh



# GNOME 48 backport COPR (Needed for the gtk4 4.18 fix)
dnf copr enable -y "jreilly1821/c10s-gnome"


# This fixes a lot of skew issues on GDX because kernel-devel wont update then
dnf versionlock add kernel kernel-devel kernel-devel-matched kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-uki-virt

dnf -y install "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${MAJOR_VERSION_NUMBER}.noarch.rpm"
dnf config-manager --set-enabled crb

# Multimidia codecs
dnf config-manager --add-repo=https://negativo17.org/repos/epel-multimedia.repo
dnf config-manager --set-disabled epel-multimedia
dnf -y install --enablerepo=epel-multimedia \
	ffmpeg libavcodec @multimedia gstreamer1-plugins-{bad-free,bad-free-libs,good,base} lame{,-libs} libjxl ffmpegthumbnailer

# KDE Plasma installation
dnf group install -y --nobest \
	"KDE Plasma Workspaces" \
	"Common NetworkManager submodules" \
	"Core" \
	"Fonts" \
	"Guest Desktop Agents" \
	"Hardware Support" \
	"Printing Client" \
	"Standard"

# Install KDE apps and tools
dnf -y install \
	plasma-desktop \
	sddm \
	konsole \
	dolphin \
	plymouth \
	plymouth-system-theme \
	fwupd \
	systemd-{resolved,container,oomd} \
	libcamera{,-{v4l2,gstreamer,tools}}

# This package adds "[systemd] Failed Units: *" to the bashrc startup
dnf -y remove console-login-helper-messages
