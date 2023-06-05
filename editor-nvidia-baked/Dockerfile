# This is the base unity editor image we will start with
# pick one from https://hub.docker.com/r/unityci/editor
ARG EDITOR_IMAGE="core.harbor.buildstar.online/editor/editor:ubuntu-2022.1.23f1-webgl-1-nvidia"
FROM $EDITOR_IMAGE

# This is the linux driver version we will install intot he container
# It should match the driver version fo the node exactly
ARG DRIVER_VERSION="525.116.04"

RUN wget "https://us.download.nvidia.com/XFree86/Linux-x86_64/$DRIVER_VERSION/NVIDIA-Linux-x86_64-$DRIVER_VERSION.run" && \
	sudo sh NVIDIA* -x && \
    sudo rm -rf NVIDIA*.run && \
	sudo mv NVIDIA* /

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

