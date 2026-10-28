#!/usr/bin/env bash
# `ws run -t vmm` (Cloud Hypervisor VM sandbox), needs 05_containers.sh for podman.
# Run with sudo, re-login afterwards (kvm group).

apt-get update
apt-get install virtiofsd e2fsprogs iproute2 nftables

# Not packaged in Debian, static binary from the upstream releases.
curl -fsSL https://github.com/cloud-hypervisor/cloud-hypervisor/releases/latest/download/cloud-hypervisor-static -o /tmp/cloud-hypervisor
install -m 755 /tmp/cloud-hypervisor /usr/local/bin/cloud-hypervisor
rm /tmp/cloud-hypervisor

usermod -aG kvm "$SUDO_USER"
