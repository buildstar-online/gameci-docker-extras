#!/bin/bash -e

# Source:
# https://github.com/selkies-project/docker-nvidia-glx-desktop/blob/main/entrypoint.sh
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Make all NVIDIA GPUs visible by default
export NVIDIA_VISIBLE_DEVICES=all
export DEBIAN_FRONTEND=noninteractive
export NVIDIA_DRIVER_CAPABILITIES=all
export APPIMAGE_EXTRACT_AND_RUN=1

# System defaults that should not be changed
export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp/runtime-user
#export PULSE_SERVER=unix:/run/pulse/native
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# Default environment variables (password is "mypasswd")
export TZ=UTC
export SIZEW=1920
export SIZEH=1080
export REFRESH=60
export DPI=96
export CDEPTH=24
export VIDEO_PORT=DFP
export PASSWD=mypasswd
export NOVNC_ENABLE=false
export WEBRTC_ENCODER=nvh264enc
export WEBRTC_ENABLE_RESIZE=false
export ENABLE_AUDIO=true
export ENABLE_BASIC_AUTH=true


init(){
        sudo apt-get update && \
                sudo apt-get install -y kmod \
                pkg-config \
                make \
                libvulkan1 \
                dbus \
                dbus-x11 \
                tmux \
                x11vnc \
                xvfb \
                xorg \
                htop \
                xfce4

        useradd -ms /bin/bash player1 && \
        usermod -aG sudo player1 && \
        echo 'player1 ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \

        # Start DBus without systemd
        sudo /etc/init.d/dbus start

        # Change time zone from environment variable
        sudo ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" | sudo tee /etc/timezone > /dev/null

        # This symbolic link enables running Xorg inside a container with `-sharevts`
        sudo ln -snf /dev/ptmx /dev/tty7

        # Allow starting Xorg from a pseudoterminal instead of strictly on a tty console
        if [ ! -f /etc/X11/Xwrapper.config ]; then
            echo -e "allowed_users=anybody\nneeds_root_rights=yes" | sudo tee /etc/X11/Xwrapper.config > /dev/null
        fi
        if grep -Fxq "allowed_users=console" /etc/X11/Xwrapper.config; then
          sudo sed -i "s/allowed_users=console/allowed_users=anybody/;$ a needs_root_rights=yes" /etc/X11/Xwrapper.config
        fi

        # Remove existing Xorg configuration
        if [ -f "/etc/X11/xorg.conf" ]; then
          sudo rm -f "/etc/X11/xorg.conf"
        fi
}

install_driver() {
        # Install NVIDIA userspace driver components including X graphic libraries
        if ! command -v nvidia-xconfig &> /dev/null; then
          # Driver version is provided by the kernel through the container toolkit
          export DRIVER_VERSION=$(head -n1 </proc/driver/nvidia/version | awk '{print$8}')
          cd /tmp
          # If version is different, new installer will overwrite the existing components
          if [ ! -f "/tmp/NVIDIA-Linux-x86_64-$DRIVER_VERSION.run" ]; then
            # Check multiple sources in order to probe both consumer and datacenter driver versions
            curl --progress-bar -fL -O "https://us.download.nvidia.com/XFree86/Linux-x86_64/$DRIVER_VERSION/NVIDIA-Linux-x86_64-$DRIVER_VERSION.run" || curl --progress-bar -fL -O "https://us.download.nvidia.com/tesla/$DRIVER_VERSION/NVIDIA-Linux-x86_64-$DRIVER_VERSION.run" || { echo "Failed NVIDIA GPU driver download. Exiting."; exit 1; }
          fi
          # Extract installer before installing
          sudo sh "NVIDIA-Linux-x86_64-$DRIVER_VERSION.run" -x
          cd "NVIDIA-Linux-x86_64-$DRIVER_VERSION"
          # Run installation without the kernel modules and host components
          sudo ./nvidia-installer --silent \
                            --no-kernel-module \
                            --install-compat32-libs \
                            --no-nouveau-check \
                            --no-nvidia-modprobe \
                            --no-rpms \
                            --no-backup \
                            --no-check-for-alternate-installs || true
          sudo rm -rf /tmp/NVIDIA* && cd ~
        fi
}


find_gpu(){
        # Get first GPU device if all devices are available or `NVIDIA_VISIBLE_DEVICES` is not set
        if [ "$NVIDIA_VISIBLE_DEVICES" == "all" ]; then
          export GPU_SELECT=$(sudo nvidia-smi --query-gpu=uuid --format=csv | sed -n 2p)
        elif [ -z "$NVIDIA_VISIBLE_DEVICES" ]; then
          export GPU_SELECT=$(sudo nvidia-smi --query-gpu=uuid --format=csv | sed -n 2p)
        # Get first GPU device out of the visible devices in other situations
        else
          export GPU_SELECT=$(sudo nvidia-smi --id=$(echo "$NVIDIA_VISIBLE_DEVICES" | cut -d ',' -f1) --query-gpu=uuid --format=csv | sed -n 2p)
          if [ -z "$GPU_SELECT" ]; then
            export GPU_SELECT=$(sudo nvidia-smi --query-gpu=uuid --format=csv | sed -n 2p)
          fi
        fi

        if [ -z "$GPU_SELECT" ]; then
          echo "No NVIDIA GPUs detected or nvidia-container-toolkit not configured. Exiting."
          exit 1
        fi

        # Setting `VIDEO_PORT` to none disables RANDR/XRANDR, do not set this if using datacenter GPUs
        if [ "${VIDEO_PORT,,}" = "none" ]; then
          export CONNECTED_MONITOR="--use-display-device=None"
        # The X server is otherwise deliberately set to a specific video port despite not
        # being plugged to enable RANDR/XRANDR, monitor will display the screen if plugged to the
        # specific port
        else
          export CONNECTED_MONITOR="--connected-monitor=${VIDEO_PORT}"
        fi
}

create_xorg_conf(){
        # Bus ID from nvidia-smi is in hexadecimal format, should be converted to decimal
        # format which Xorg understands, required because nvidia-xconfig doesn't work as intended in
        # a container
        HEX_ID=$(sudo nvidia-smi --query-gpu=pci.bus_id --id="$GPU_SELECT" --format=csv |sed -n 2p)
        IFS=":." ARR_ID=($HEX_ID)
        unset IFS
        BUS_ID=PCI:$((16#${ARR_ID[1]})):$((16#${ARR_ID[2]})):$((16#${ARR_ID[3]}))

        # A custom modeline should be generated because there is no monitor to fetch this
        # information normally
        export MODELINE=$(cvt -r "${SIZEW}" "${SIZEH}" "${REFRESH}" | sed -n 2p)

        # Generate /etc/X11/xorg.conf with nvidia-xconfig
        sudo nvidia-xconfig --virtual="${SIZEW}x${SIZEH}" --depth="$CDEPTH" --mode=$(echo "$MODELINE" | awk '{print $2}' | tr -d '"') \
                --allow-empty-initial-configuration \
                --no-probe-all-gpus \
                --busid="$BUS_ID" \
                --no-multigpu \
                --no-sli \
                --no-base-mosaic \
                --only-one-x-screen ${CONNECTED_MONITOR}

        # Guarantee that the X server starts without a monitor by adding more options to
        # the configuration
        sudo sed -i '/Driver\s\+"nvidia"/a\    Option         "ModeValidation" "NoMaxPClkCheck, NoEdidMaxPClkCheck, NoMaxSizeCheck, NoHorizSyncCheck, NoVertRefreshCheck, NoVirtualSizeCheck, NoExtendedGpuCapabilitiesCheck, NoTotalSizeCheck, NoDualLinkDVICheck, NoDisplayPortBandwidthCheck, AllowNon3DVisionModes, AllowNonHDMI3DModes, AllowNonEdidModes, NoEdidHDMI2Check, AllowDpInterlaced"\n    Option         "HardDPMS" "False"' /etc/X11/xorg.conf

        # Add custom generated modeline to the configuration
        sudo sed -i '/Section\s\+"Monitor"/a\    '"$MODELINE" /etc/X11/xorg.conf
}

start_app(){
        tmux new-session -d -s "xorg"
        tmux send-keys -t "xorg" "export DISPLAY=:0 && Xorg vt7 -noreset -novtswitch -sharevts -dpi ${DPI} +extension GLX +extension RANDR +extension RENDER +extension MIT-SHM ${DISPLAY}" ENTER
        
        echo "Waiting for X socket"
        until [ -S "/tmp/.X11-unix/X${DISPLAY/:/}" ]; do sleep 1; done
        echo "X socket is ready"
        
        tmux new-session -d -s "x11vnc"
        tmux send-keys -t "x11vnc" "export DISPLAY=:0 && sudo x11vnc -display ${DISPLAY} -shared -loop -repeat -xkb -snapfb -threads -xrandr resize -rfbport 5900 ${NOVNC_VIEWONLY}" ENTER
        
        tmux new-session -d -s "app"
        tmux send-keys -t "app" "startxfce4" ENTER
}

init
find_gpu
install_driver
create_xorg_conf
start_app
/bin/bash
