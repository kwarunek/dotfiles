#!/usr/bin/env bash

apt-get update
apt-get install dunst libnotify-bin
apt-get install network-manager network-manager-gnome
apt-get install keepassxc gimp libreoffice

# recommends pull yelp with WebKitGTK
apt-get install --no-install-recommends gedit
