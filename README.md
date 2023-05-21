# gameci-docker-extras

GameCI images based on [nvidia/cuda:12.1.0-base-ubuntu22.04](https://hub.docker.com/layers/nvidia/cuda/12.1.0-base-ubuntu22.04/images/sha256-972305a2572b3d905756c3ee60364277834d1955d7c8ff4c331e27e4dac9c5cc?context=explore) which provide GPU-acceleration on NVIDIA GPU's via the [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/overview.html). The images still reqire manual installation of the user-space nvidia driver unless used with the [nvidia-gpu-operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/overview.html).

<img width="986" alt="Screenshot 2023-04-20 at 08 09 37" src="https://user-images.githubusercontent.com/84841307/233273510-3e01bb58-1dd6-4e1c-9a0e-405ba8f74dbd.png">

## Dockerhub Links:

- [Base](https://hub.docker.com/repository/docker/deserializeme/gcicudabase) - 228.58 MB
- [Hub](https://hub.docker.com/repository/docker/deserializeme/gcicudahub) - 503.9 MB
- [Editor](https://hub.docker.com/repository/docker/deserializeme/gcicudaeditor) - 3.83 GB

## Manually install user-space driver

See [entrypoint.sh](https://github.com/selkies-project/docker-nvidia-glx-desktop/blob/main/entrypoint.sh) from the [docker-nvidia-glx-desktop](https://github.com/selkies-project/docker-nvidia-glx-desktop) for example.

## Host Preparation

> Tested on Ubuntu22.04 and Debain12 hosts.

Requires Nvidia drivers + Container Runtime, or GPU Operator to be installed on the host. See https://github.com/small-hack/smol-metal for instructions.

## Example

1. Log into the docker-host

2. Generate a License

  - from https://github.com/buildstar-online/unity-webgl-nginx

    ```bash
    # Create a temporary directoy to work in
    mkdir -p /tmp/scratch
    cd /tmp/scratch

    # Export important variables
    export EDITOR_VERSION="2022.1.23f1"
    export EDITOR_IMAGE="udeserializeme/gcicudaeditor:latest"
    export SLENIUM_IMAGE="deserializeme/gcicudaselenium:latest"
    export USERNAME="YOUR_EMAIL_HERE"
    export PASSWORD="YOUR_PASSWORD_HERE"
  
    # Change ownership of local dir so the container user can save data to mounted volumes
    chown 1000:1000 .
    touch Unity_v${EDITOR_VERSION}.alf

    # Generate the ALF file using the Editor 
    docker run --rm -it -v $(pwd)/Unity_v${EDITOR_VERSION}.alf:/Unity_v${EDITOR_VERSION}.alf \
        --user root \
       $EDITOR_IMAGE \
       unity-editor -quit \
       -batchmode \
       -nographics \
       -logFile /dev/stdout \
       -createManualActivationFile \
       -username "$USERNAME" \
       -password "$PASSWORD"
    ```
  
3. Authorize the License or Answer 2FA prompt

  - Next try to authorize the license. This may fail due to a 2Factor prompt from Unity. If that happens, you will need to run the [grafical login process].

    ```bash
    docker run --rm -it --user 1000:1000 \
        --mount type=bind,source="$(pwd)",target=/home/player1/unity-self-auth/Downloads \
        -e USERNAME="$USERNAME" \
        -e PASSWORD="$PASSWORD" \
        -e HEADLESS="True" \
        $SLENIUM_IMAGE \
        ./license.py "./Downloads/Unity_v${EDITOR_VERSION}.alf"
    ```
  
4. Run the Unity Editor container 

  - Mount your project's repo directory as a volume. I'm using https://github.com/buildstar-online/unity-webgl-nginx as an example below.

    ```bash
    docker run --gpus all --rm -it \
      -p 5900:5900 \
      -p 2222:22 \
      --mount type=bind,source=$(pwd),target=/home/player1/Downloads \
      --mount type=bind,source=$(pwd)/unity-webgl-nginx,target=/home/player1/unity-webgl-nginx \
      --user root \
      $EDITOR_IMAGE
    ```

5. Install GPU user-space driver, create xorg.conf, and start X sevices

```bash
wget https://raw.githubusercontent.com/buildstar-online/gameci-docker-extras/main/gpu-enable.sh
export DISPLAY=:0
bash gpu-enable.sh
```

6. Connect to container using VNC

7. Sign-in and start Unity

```bash
# Sign-in
sudo /opt/unity/Editor/Unity -quit \
    -batchmode \
    -logFile /dev/stdout \
    -manualLicenseFile /home/player1/Downloads/*.ulf

# Start Editor
sudo /opt/unity/Editor/Unity
```
