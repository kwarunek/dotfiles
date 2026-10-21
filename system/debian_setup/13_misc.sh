#!/usr/bin/env bash

apt-get update
apt-get install dunst libnotify-bin
apt-get install network-manager network-manager-gnome
apt-get install keepassxc gimp

# the libreoffice metapackage also pulls Base, Java and Firebird
apt-get install libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-gtk3

# recommends pull yelp with WebKitGTK
apt-get install --no-install-recommends gedit
