#!/usr/bin/env bash
# brightness-udev gives the video group write access to the backlight,
# instead of setuid on brightnessctl. Run with sudo, re-login afterwards.

apt-get update
apt-get install brightnessctl brightness-udev

usermod -aG video "$SUDO_USER"
