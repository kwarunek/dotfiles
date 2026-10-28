#!/usr/bin/env bash
# ws (throwaway sandboxes, https://gitlab.com/kwarunek/ws), latest .deb from the GitLab releases.
# apt-get installs it through dpkg and pulls its dependencies. Run with sudo.

curl -fsSL https://gitlab.com/kwarunek/ws/-/releases/permalink/latest/downloads/ws_latest.deb -o /tmp/ws_latest.deb
apt-get install /tmp/ws_latest.deb
rm /tmp/ws_latest.deb
