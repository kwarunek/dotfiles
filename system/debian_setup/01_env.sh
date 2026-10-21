#!/usr/bin/env bash

apt-get update
apt-get install bash vim mc jq yq crudini 7zip bat tmux screen fzf ncal sudo
apt-get install bzip2 gzip tar unzip
apt-get install curl wget ca-certificates
apt-get install gnupg gpg
apt-get install starship atuin
apt-get install cups cups-browsed avahi-daemon

# Debian ships bat as batcat, xargs and sh -c (batdiff, batman) don't see aliases
ln -sf /usr/bin/batcat /usr/local/bin/bat

# printer admin in the CUPS web UI (http://localhost:631), run with sudo
usermod -aG lpadmin "$SUDO_USER"
