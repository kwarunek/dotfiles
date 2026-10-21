#!/usr/bin/env bash
# Not in the Debian archive, installed from extrepo.
# To drop a repository later: extrepo disable <name>

apt-get update
apt-get install extrepo

extrepo enable librewolf
extrepo update librewolf
apt-get update
apt-get install librewolf
extrepo disable librewolf
