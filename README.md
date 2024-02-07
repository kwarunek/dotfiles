dotfiles
========

bash
-----
Some aliases, functions

 - colored grep, ls, diff if possible
 - `extract FILENAME` detect type and try to extract
 - `yaml2json`/`json2yaml`
 - increased history size, shell shared


 - `ip-lan` and `ip-wan` detect local and wan ip
 - `ports` show ports stats
 - `rm-pyc`, `rm-DS` remove python pyc and mac DS files
 - `sha1`, `rot13`, `now`
 - `GET`, `POST`... with url make request


vim
---

Pathongen with installed - check out `.gitmodules`.

**Additional key bindings**:

 - **F1** - toggles cursorline and an indentline marking
 - **F2** - toggles NERDtree
 - **F3** - toggles nopaste
 - **F4** - (un)comments
 - **F7** - flake for py, jshint for js
 - **,**  - leader
 - **,nw** - clear trailing whitespaces
 - **,bc**  - close current buffer, preserve layout
 - **,ev**  - edit vimrc
 - **Ctrl+A**  - select all
 - **left arrow** - go to next buffer
 - **right arrow** - go to prev buffer

pkg
---

**Tooling**

via system package manager:
- general: bash vim mc jq yq crudini 7zip bat
- dev: g++ gcc make automake binutils bison
- debug: gdb strace ltrace delve xdd
- containers: podman runc skopeo
- vcs: subversion git
- net: whois net-tools tcpdump tcpflow dnsutils netcat-openbsd
- db: postgresql-client mysql-client maridb-client sqlite3-tools

via asdf:
- lang: golang rust python nodejs
- k8s: kubectl flux2 helm krew
- sec: sops checkov vault
- cloud: awscli gcloud saml2aws
- db: opensearch-cli redis-cli
- conf/iac: ansible salt terraform

via krew:
- ns ctx

**ws**:
- ui: i3 i3-lock i3status arandr dunst feh xclip
- net: network-manager
- video: brightnessctl
- sound: pulseaudio-utils
- random: ldap-utils
- x: keepassxc firefox gimp libreoffice

Manual stuff
------------

System wide configuration
`system/ > /etc`

Control birghtness without root:
`sudo chmod +s $(which brightnessctl)`
