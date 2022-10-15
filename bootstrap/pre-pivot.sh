#!/bin/bash

# Load common functions
. /usr/local/bin/release-image.sh

# Copy pivot files
cp overlay/etc / -rvf
cp manifests/* /opt/openshift/openshift/ -rvf

# Pivot to new os content
MACHINE_CONFIG_OSCONTENT=$(image_for machine-os-content)
rpm-ostree rebase --experimental "ostree-unverified-registry:${MACHINE_CONFIG_OSCONTENT}"
# Remove mitigations kargs
rpm-ostree kargs --delete mitigations=auto,nosmt
touch /opt/openshift/.pivot-done
rpm-ostree ex apply-live || systemctl reboot
