#!/usr/bin/env bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script theming-lts user 1 || exit 0

set -xeuo pipefail

VEN_ID="$(cat /sys/devices/virtual/dmi/id/chassis_vendor)"

if [[ ":Framework:" =~ :$VEN_ID: ]]; then
	echo 'Setting Framework logo menu'
	echo 'Setting touch scroll type'
	if [[ $SYS_ID == "Laptop ("* ]]; then
		echo 'Applying font fix for Framework 13'
	fi
fi

SYS_ID="$(cat /sys/devices/virtual/dmi/id/product_name)"

if [[ ":Thelio Astra:" =~ :$SYS_ID: ]]; then
	echo 'Setting Ampere Logo'
 fi
