# FROM tensorflow/tensorflow:latest-gpu
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

LABEL version="0.1" \
      description="ComfyUI development using VSCode remote development over tailscale." \
      tag="latest"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    SHELL=/bin/bash

# Create workspace directory
WORKDIR /workspace

# Install system packages in a single RUN command to reduce layers
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        python3-apt \
        python3-distutils && \
    apt-get update -y && \
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
        bash && \
    ln -s /usr/lib/python3/dist-packages/apt_pkg.cpython-*-x86_64-linux-gnu.so /usr/lib/python3/dist-packages/apt_pkg.so && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb && \
    apt-get update

# Need cuda 12.4 for ComfyUI-3D-Pack
RUN apt-get -y install cuda-toolkit-12-4
ENV CPLUS_INCLUDE_PATH=/usr/local/cuda/include
ENV PATH=/usr/local/cuda/bin:$PATH

# Set shell options
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Create user and setup SSH
RUN useradd -m -s /bin/bash comfy && \
    echo "comfy ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    # Setup SSH directory
    mkdir -p /home/comfy/.ssh && \
    chown -R comfy:comfy /home/comfy/.ssh && \
    chmod 700 /home/comfy/.ssh && \
    mkdir -p /home/comfy/startup

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Copy and setup entrypoint scripts
COPY ./container/entrypoint.sh /entrypoint.sh
COPY ./container/setup.sh /home/comfy/startup/setup.sh
COPY ./container/start.sh /home/comfy/startup/start.sh
COPY ./container/utils.sh /home/comfy/startup/utils.sh
RUN chmod +x \
    /entrypoint.sh \
    /home/comfy/startup/setup.sh \
    /home/comfy/startup/start.sh \
    /home/comfy/startup/utils.sh 

# Setup workspace permissions
VOLUME /workspace
RUN chown -R comfy:comfy /workspace

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]