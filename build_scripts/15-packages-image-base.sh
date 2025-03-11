#!/usr/bin/env bash

set -xeuo pipefail

# This is the base for a minimal GNOME system on CentOS Stream.

# This thing slows down downloads A LOT for no reason
dnf remove -y subscription-manager

# The base images take super long to update, this just updates manually for now
dnf -y update kernel
dnf -y install 'dnf-command(versionlock)'
dnf versionlock add kernel kernel-devel kernel-devel-matched kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-uki-virt

dnf -y install epel-release
dnf config-manager --set-enabled crb

# Multimidia codecs
dnf -y install @multimedia gstreamer1-plugins-{bad-free,bad-free-libs,good,base} lame{,-libs} libjxl

# `dnf group info Workstation` without GNOME
dnf group install -y --nobest \
	-x rsyslog* \
	-x cockpit \
	-x cronie* \
	-x crontabs \
	-x PackageKit \
	-x PackageKit-command-not-found \
	"Common NetworkManager submodules" \
	"Core" \
	"Fonts" \
	"Guest Desktop Agents" \
	"Hardware Support" \
	"Printing Client" \
	"Standard" \
	"Workstation product core"

dnf install -y --nobest \
	@"KDE Plasma Workspaces" \
    falkon


systemctl enable \
    sddm.service

dnf -y install \
	plymouth \
	plymouth-system-theme \
	fwupd \
	systemd-{resolved,container,oomd} \
	libcamera{,-{v4l2,gstreamer,tools}} \
	ffmpegthumbnailer

# This package adds "[systemd] Failed Units: *" to the bashrc startup
dnf -y remove console-login-helper-messages
