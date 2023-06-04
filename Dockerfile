# This is the base unity editor image we will start with
# pick one from https://hub.docker.com/r/unityci/editor
ARG EDITOR_IMAGE="unityci/editor:ubuntu-2021.3.18f1-webgl-1"
FROM $EDITOR_IMAGE

# This is the linux driver version we will install intot he container
# It should match the driver version fo the node exactly
ARG DRIVER_VERSION="525.116.04"

# Unity needs an older version of ssl to work
# ENV OLD_SSL_DEB="http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb"

# Required for setting up non-snap firefox
COPY mozilla-firefox /etc/apt/preferences.d/mozilla-firefox

# Install deps for Nvidia and Desktop
RUN apt-get update && \
	apt-get install -y software-properties-common \
	sudo \
	tmux \
	curl \
	kmod \
	pkg-config \
	make \
	libvulkan1 \
	dbus \
	dbus-x11 \
	xvfb \
	xorg \
	konsole \
	xinit \
	xfce4 \
	xfce4-goodies \
	tzdata \
	wget \
	python3-launchpadlib && \
	add-apt-repository -y ppa:mozillateam/ppa && \
	apt-get update && \
	sudo apt-get install -y firefox-esr && \
	rm -rf /var/lib/apt/lists/*

#  wget ${OLD_SSL_DEB} && \
#  dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb && \
#  rm libssl1.1_1.1.1f-1ubuntu2_amd64.deb && \

#  wget -O /driver.run "https://us.download.nvidia.com/XFree86/Linux-x86_64/$DRIVER_VERSION/NVIDIA-Linux-x86_64-$DRIVER_VERSION.run" && \
#  sh /driver.run -x

# Install NoVNC to expose x11vnc via websocket
ARG NOVNC_VERSION=1.4.0
RUN apt-get update && apt-get install --no-install-recommends -y \
        autoconf \
        automake \
        autotools-dev \
        chrpath \
        debhelper \
        git \
        jq \
        python3 \
        python3-numpy \
        libc6-dev \
        libcairo2-dev \
        libjpeg-turbo8-dev \
        libssl-dev \
        libv4l-dev \
        libvncserver-dev \
        libtool-bin \
        libxdamage-dev \
        libxinerama-dev \
        libxrandr-dev \
        libxss-dev \
        libxtst-dev \
        libavahi-client-dev && \
        rm -rf /var/lib/apt/lists/*

# Build x11vnc for latest
RUN git clone "https://github.com/LibVNC/x11vnc.git" /tmp/x11vnc && \
    cd /tmp/x11vnc && \
    autoreconf -fi && \
    ./configure && \
    make install && \
    cd / && \
    rm -rf /tmp/* && \
    curl -fsSL "https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.tar.gz" |\
    tar -xzf - -C /opt && \
    mv -f "/opt/noVNC-${NOVNC_VERSION}" /opt/noVNC && \
    ln -snf /opt/noVNC/vnc.html /opt/noVNC/index.html && \
    git clone "https://github.com/novnc/websockify.git" /opt/noVNC/utils/websockify


# create a user for non-root operation
ARG USER="player1"
RUN useradd -ms /bin/bash $USER && \
        usermod -aG sudo $USER && \
        echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
        mkdir -p /home/$USER/.local/bin && \
        mkdir -p /home/$USER/.local/lib && \
        chown $USER:$USER /home/$USER/.local/bin && \
        chown $USER:$USER /home/$USER/.local/lib
	# mv /driver.run /home/$USER/driver.run

# Swap to user account
USER $USER
WORKDIR /home/$USER/

# Re-alias to the new unity-editor path
RUN sudo rm /usr/bin/unity-editor && \
  sudo ln -s /opt/unity/Editor/Unity /usr/bin/unity-editor

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/bash", "-x", "/entrypoint.sh"]
