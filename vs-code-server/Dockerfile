USER root

# Install basic tools + sudo
RUN apt-get update && apt-get install -y \
    sudo \
    git \
    curl \
    wget \
    vim \
    nano \
    build-essential \
    python3 \
    python3-pip \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Enable passwordless sudo
RUN usermod -aG sudo openvscode-server && \
    echo 'openvscode-server ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/openvscode-server && \
    chmod 0440 /etc/sudoers.d/openvscode-server

# Fix workspace permission
RUN mkdir -p /home/workspace && \
    chown -R openvscode-server:openvscode-server /home/workspace

USER openvscode-server
