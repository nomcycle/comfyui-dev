# Stage 1: Base system setup
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04 AS base

LABEL version="0.2" \
      description="ComfyUI development using VSCode remote development over tailscale." \
      tag="latest"

ENV DEBIAN_FRONTEND=noninteractive \
    SHELL=/bin/bash

# Initial packages for repository management
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        python3-apt \
        python3-distutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Stage 2: Development dependencies
FROM base AS dev-deps

# Install development tools and dependencies
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        wget \
        git \
        sudo \
        openssh-server \
        curl \
        iptables \
        gnupg \
        tzdata \
        unzip \
        libegl1-mesa-dev \
        vim \
        expect \
        ca-certificates \
        build-essential \
        lsb-release \
        lsyncd \
        rsync \
        bash && \
    ln -s /usr/lib/python3/dist-packages/apt_pkg.cpython-*-x86_64-linux-gnu.so /usr/lib/python3/dist-packages/apt_pkg.so && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Stage 3: CUDA setup
# FROM dev-deps AS cuda-setup

# Install CUDA
# RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb && \
#     dpkg -i cuda-keyring_1.1-1_all.deb && \
#     apt-get update && \
#     apt-get -y install cuda-toolkit-12-4 && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/*

# ENV CPLUS_INCLUDE_PATH=/usr/local/cuda/include
# ENV PATH=/usr/local/cuda/bin:$PATH

# Stage 4: User setup
FROM dev-deps AS user-setup

# Create user and setup SSH
RUN useradd -m -s /bin/bash comfy && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    # Setup SSH directory
    mkdir -p /run/sshd && \
    mkdir -p /home/comfy/.ssh && \
    mkdir -p /home/comfy/startup && \
    chown -R comfy:comfy /home/comfy/.ssh && \
    chmod 700 /home/comfy/.ssh

# Stage 5: Tailscale setup
FROM user-setup AS tailscale-setup

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Stage 6: Final image
FROM tailscale-setup AS final

# Copy startup scripts and configuration files
COPY ./docker/scripts/ /home/comfy/startup/scripts/
COPY ./config/ /home/comfy/startup/config/
RUN chmod +x /home/comfy/startup/scripts/*.sh && \
    chmod +x /home/comfy/startup/scripts/modules/*.sh && \
    ln -sf /home/comfy/startup/scripts/utils.sh /home/comfy/startup/utils.sh && \
    ln -sf /home/comfy/startup/scripts/entrypoint.sh /home/comfy/startup/entrypoint.sh && \
    ln -sf /home/comfy/startup/scripts/setup.sh /home/comfy/startup/setup.sh && \
    ln -sf /home/comfy/startup/scripts/start.sh /home/comfy/startup/start.sh && \
    chown -R comfy:comfy /home/comfy/startup

# Create workspace directory
RUN mkdir -p /workspace && \
    chown -R comfy:comfy /workspace

# Set Tailscale state directory for persistence
ENV TS_STATE_DIR=/var/lib/tailscale/

# Setup workspace as a volume
VOLUME /workspace
VOLUME /var/lib/tailscale

# Install uv for Python package management (as comfy user)
USER comfy
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
USER root

# Set shell options for better script execution
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set the entry point and default command
ENTRYPOINT ["/home/comfy/startup/entrypoint.sh"]
CMD ["bash"]