#!/usr/bin/env bash

apt-get update
apt-get install ripgrep fd-find

# Debian ships neovim 0.10 and tree-sitter-cli 0.22 (which also pulls nodejs),
# nvim-treesitter (main) needs neovim 0.12+ and tree-sitter-cli 0.26.1+,
# so both come from the upstream releases.
curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz -o /tmp/nvim.tar.gz
rm -rf /opt/nvim /opt/nvim-linux-x86_64
tar -xzf /tmp/nvim.tar.gz -C /opt
mv /opt/nvim-linux-x86_64 /opt/nvim
ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
rm /tmp/nvim.tar.gz

curl -fsSL https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz -o /tmp/tree-sitter.gz
gunzip -f /tmp/tree-sitter.gz
install -m 755 /tmp/tree-sitter /usr/local/bin/tree-sitter
rm /tmp/tree-sitter
