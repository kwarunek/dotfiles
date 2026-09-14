FROM ws:latest

# Same default as the base image, so paths below match the baked-in user.
ARG USERNAME=user

USER root

# zstd lets the Claude Code installer take its compressed download path.
RUN apt-get update && apt-get install -y --no-install-recommends \
    zstd \
    && rm -rf /var/lib/apt/lists/*

USER ${USERNAME}
ENV HOME=/home/${USERNAME}
ENV PATH="${HOME}/.local/bin:${HOME}/.opencode/bin:${PATH}"

# Bump to force a rebuild of the tool layers below (they install "latest").
ARG LLM_CACHE_BUST=1

# opencode -> $HOME/.opencode/bin/opencode
RUN curl -fsSL https://opencode.ai/install | bash && \
    opencode --version

# claude -> $HOME/.local/bin/claude
RUN curl -fsSL https://claude.ai/install.sh | bash && \
    claude --version

# agentsview -> $HOME/.local/bin/agentsview (single Go binary from GH releases)
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    ver="$(curl -fsSL -o /dev/null -w '%{url_effective}' \
        https://github.com/kenn-io/agentsview/releases/latest | sed 's#.*/tag/v##')"; \
    curl -fsSL "https://github.com/kenn-io/agentsview/releases/download/v${ver}/agentsview_${ver}_linux_${arch}.tar.gz" \
        -o /tmp/agentsview.tar.gz; \
    mkdir -p "${HOME}/.local/bin"; \
    tar -xzf /tmp/agentsview.tar.gz -C "${HOME}/.local/bin" agentsview; \
    chmod +x "${HOME}/.local/bin/agentsview"; \
    rm /tmp/agentsview.tar.gz; \
    agentsview --version

WORKDIR /workspace

CMD ["/bin/bash"]
