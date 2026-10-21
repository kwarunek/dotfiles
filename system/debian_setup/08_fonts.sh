#!/usr/bin/env bash
# Droid Sans Mono and MesloLGS Nerd Font are not packaged in Debian.

apt-get update
apt-get install fontconfig xz-utils

tmp=$(mktemp -d)

# Droid Sans Mono from AOSP, served base64 encoded
mkdir -p /usr/local/share/fonts/droid
curl -fsSL "https://android.googlesource.com/platform/frameworks/base/+/refs/tags/android-4.4_r1/data/fonts/DroidSansMono.ttf?format=TEXT" -o "$tmp/DroidSansMono.b64"
base64 -d "$tmp/DroidSansMono.b64" > /usr/local/share/fonts/droid/DroidSansMono.ttf

mkdir -p /usr/local/share/fonts/meslo
curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.tar.xz -o "$tmp/Meslo.tar.xz"
tar -xJf "$tmp/Meslo.tar.xz" -C /usr/local/share/fonts/meslo --wildcards 'MesloLGSNerdFont*'

rm -rf "$tmp"

fc-cache -f
fc-list | grep -i -e 'Droid Sans Mono' -e 'MesloLGS Nerd Font'
