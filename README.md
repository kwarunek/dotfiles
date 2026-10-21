dotfiles
========

bash
-----
Some aliases, functions

 - colored grep, ls if possible
 - `extract FILENAME` detect type and try to extract
 - `yaml2json`/`json2yaml`
 - increased history size, shell shared


 - `ip-lan` and `ip-wan` detect local and wan ip
 - `ports` show ports stats
 - `rm-pyc`, `rm-DS` remove python pyc and mac DS files
 - `sha1`, `rot13`, `now`
 - `aws-use PROFILE [force]` - switch `AWS_PROFILE`, log in first when the session is gone
   (SSO when the profile has `sso_session`, saml2aws otherwise), with profile completion
 - `ws` - start a sandboxed podman workspace container, see `ws -h` and `ws/container/README.md`

vim/neovim
----------

**Common key bindings** (vim and nvim):

 - **,**  - leader
 - **F2** - toggles NERDTree/nvim-tree
 - **,nw** - clear trailing whitespaces
 - **Ctrl+A**  - select all
 - **left arrow** - go to prev buffer
 - **right arrow** - go to next buffer

**vim**: pathogen, plugins in `.gitmodules` (NERDTree, nerdcommenter, airline, fugitive, indentLine, flake8, ...)

 - **F1** - toggles cursorcolumn and an indentline marking
 - **F3** - toggles paste
 - **F4** - (un)comments
 - **,bc**  - close current buffer, preserve layout

**nvim**: lazy.nvim, plugins in `.config/nvim/lua/kwarunek/lazy/` (telescope, treesitter, nvim-tree, nvim-cmp + LuaSnip, Comment.nvim, cloak, fugitive, kanagawa, hardline)

 - **F1** - toggles paste
 - **gcc** / **gc** - (un)comments line / selection (Comment.nvim)
 - **,ff** - telescope: find files
 - **,fs** - telescope: live grep
 - **,pws** / **,pWs** - telescope: grep word / WORD under cursor
 - **Ctrl+P** - telescope: git files
 - **gyb** / **gB** - base64 decode / encode in place (endec)

pkg
---

**Tooling**

via system package manager (Debian: `system/debian_setup/*.sh`, run in order, `10a`/`10b` are alternatives):
- env (`01_env.sh`):
  - general: bash vim mc jq yq crudini 7zip bat (+ `bat` -> `batcat` link) tmux screen fzf ncal sudo
  - archives: bzip2 gzip tar unzip
  - download: curl wget ca-certificates
  - crypto: gnupg gpg
  - shell: starship atuin
- programming (`02_programming.sh`):
  - dev: build-essential g++ gcc make automake binutils bison
  - debug: gdb strace ltrace delve xxd
  - python: python3 python3-pip python3-venv python3-yaml python3-requests
- vcs (`03_vcs.sh`): git subversion mercurial glab meld
- network (`04_network.sh`):
  - diagnostics: iproute2 net-tools whois dnsutils netcat-openbsd
  - sniffing: tcpdump tcpflow
  - remote: openssh-client ldap-utils
- containers (`05_containers.sh`): podman runc skopeo fuse-overlayfs slirp4netns uidmap
- db (`06_db.sh`): postgresql-client sqlite3 sqlite3-tools
- nvim (`07_nvim.sh`): ripgrep fd-find, neovim and tree-sitter cli from upstream releases
- fonts (`08_fonts.sh`): Droid Sans Mono (AOSP) and MesloLGS Nerd Font (nerd-fonts), into `/usr/local/share/fonts`

via asdf:
- lang: golang rust python nodejs
- k8s: kubectl flux2 helm krew
- sec: sops checkov vault
- cloud: awscli gcloud saml2aws
- db: opensearch-cli redis-cli
- conf/iac: ansible salt terraform

via krew:
- ns ctx

**desktop**:
- x11 (i3, `system/debian_setup/10a_x11_i3.sh`):
  - ui: i3 i3lock xss-lock i3status arandr feh xclip xinput rofi x11-xserver-utils
  - term: lxterminal
  - sound: pasystray (tray)
- wayland (sway, `system/debian_setup/10b_wayland_sway.sh`):
  - ui: sway swaybg swayidle swaylock waybar fuzzel wl-clipboard
  - display: wdisplays wlr-randr kanshi
  - term: foot
- common:
  - sound (`system/debian_setup/09_sound.sh`): pipewire-audio pulseaudio-utils pavucontrol
  - browsers (`system/debian_setup/11_browsers.sh`, via extrepo): librewolf
  - brightness (`system/debian_setup/12_brightness.sh`, no root needed, user added to `video`): brightnessctl brightness-udev
  - misc (`system/debian_setup/13_misc.sh`):
    - notifications: dunst libnotify-bin
    - net: network-manager network-manager-gnome
    - apps: keepassxc gimp libreoffice gedit (without recommends)

Manual stuff
------------

System wide (`system/`, run or copy as root):
- `drivers/<vendor>/etc/` - configuration to copy into `/etc`
- `disable-ksm.sh` - disables Kernel Samepage Merging now and across reboots
- `debian_setup/` - package installation scripts, see **pkg**

`installer.sh` does not link `bin/` on purpose, link or copy the needed scripts into `~/bin` by hand.

Fonts `Droid Sans Mono` and `MesloLGS Nerd Font`: `system/debian_setup/08_fonts.sh`
