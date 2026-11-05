FROM node:24-trixie-slim

# Match the container user to the host user.
ARG HOST_UID=1000
ARG HOST_GID=1000

# System dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        git \
        ripgrep \
        procps \
        curl \
        less \
    && rm -rf /var/lib/apt/lists/*

# Configure node user/group IDs
RUN groupmod --non-unique --gid "${HOST_GID}" node \
    && usermod --non-unique --uid "${HOST_UID}" --gid "${HOST_GID}" node

# Install OpenCode (x86-64 baseline)
RUN npm install --global --ignore-scripts \
        opencode-linux-x64-baseline@2.2.5 \
    && ln -s \
        /usr/local/lib/node_modules/opencode-linux-x64-baseline/bin/opencode \
        /usr/local/bin/opencode

# Install Pi
RUN npm install --global --ignore-scripts \
        @earendil-works/pi-coding-agent@1.4.0

# Prepare application directories
RUN mkdir -p \
        /home/node/.local/share/opencode \
        /home/node/.config/opencode \
        /home/node/.config/git \
        /home/node/.pi \
        /workspace \
    && chown -R node:node /home/node /workspace

ENV HOME=/home/node
ENV GIT_CONFIG_GLOBAL=/home/node/.config/git/config

WORKDIR /workspace

USER node

CMD ["sleep", "infinity"]