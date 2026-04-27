FROM ubuntu:24.04

# Install base system packages and development tools
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    gcc \
    python3 \
    python3-pip \
    postgresql-client \
    mysql-client \
    jq \
    tcpdump \
    tcpflow \
    gdb \
    make \
    curl \
    ca-certificates \
    gnupg \
    whois \
    net-tools \
    dnsutils \
    netcat-openbsd \
    sudo \
    unzip \
    tar \
    gzip \
    bzip2 \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

# Install neovim from official releases
RUN curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz -o /tmp/nvim.tar.gz && \
    tar -xzf /tmp/nvim.tar.gz -C /opt && \
    mv /opt/nvim* /opt/nvim && \
    ln -sf /opt/nvim/bin/nvim /usr/bin/nvim && \
    rm /tmp/nvim.tar.gz

# Install yq
RUN curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

# Delete ubuntu user to avoid UID 1000 conflict and create configurable user
ARG USERNAME=user
RUN userdel -r ubuntu 2>/dev/null || true && \
    useradd -m -s /bin/bash -u 1000 "${USERNAME}" && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ${USERNAME}

# Download and run dotfiles installer
RUN curl -fsSL https://raw.githubusercontent.com/kwarunek/dotfiles/master/installer.sh -o /tmp/installer.sh && \
    chmod +x /tmp/installer.sh && \
    bash /tmp/installer.sh && \
    bash /tmp/installer.sh nvim && \
    rm /tmp/installer.sh

ENV ASDF_DIR=/home/${USERNAME}/.asdf
ENV PATH="$ASDF_DIR/shims:$ASDF_DIR/bin:$PATH"

RUN asdf plugin-add flux2 && \
    asdf install flux2 latest && \
    asdf global flux2 latest

RUN asdf plugin-add kubectl && \
    asdf install kubectl latest && \
    asdf global kubectl latest

RUN asdf plugin-add awscli && \
    asdf install awscli latest && \
    asdf global awscli latest

RUN asdf plugin-add terraform && \
    asdf install terraform latest && \
    asdf global terraform latest

RUN asdf plugin-add nodejs && \
    asdf install nodejs latest && \
    asdf global nodejs latest

RUN /opt/nvim/bin/nvim --headless +Lazy! sync +qall

RUN mkdir -p ~/.ssh

WORKDIR /workspace

USER ${USERNAME}

CMD ["/bin/bash"]
