# gameci-docker-extras

GameCI images based on [nvidia/cuda:12.1.0-base-ubuntu22.04](https://hub.docker.com/layers/nvidia/cuda/12.1.0-base-ubuntu22.04/images/sha256-972305a2572b3d905756c3ee60364277834d1955d7c8ff4c331e27e4dac9c5cc?context=explore) which provide GPU-acceleration on NVIDIA GPU's via the [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/overview.html). The images still reqire manual installation of the user-space nvidia driver unless used with the [nvidia-gpu-operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/overview.html).

<img width="986" alt="Screenshot 2023-04-20 at 08 09 37" src="https://user-images.githubusercontent.com/84841307/233273510-3e01bb58-1dd6-4e1c-9a0e-405ba8f74dbd.png">

## Dockerhub Links:

- [Base](https://hub.docker.com/repository/docker/deserializeme/gcicudabase) - 228.58 MB
- [Hub](https://hub.docker.com/repository/docker/deserializeme/gcicudahub) - 503.9 MB
- [Editor](https://hub.docker.com/repository/docker/deserializeme/gcicudaeditor) - 3.83 GB
- [Hub + Selenium](https://hub.docker.com/repository/docker/deserializeme/gcicudaselenium) - 716.25 MB

## ALF file creation

```bash
EDITOR_VERSION="2022.1.23f1"
CHANGE_SET="9636b062134a"
HUB_VERSION="3.3.0"

touch Unity_v${EDITOR_VERSION}.alf

# Get an alf file
docker run --rm -it -v $(pwd):/home/player1 \
    -v $(pwd)/Unity_v${EDITOR_VERSION}.alf:/Unity_v${EDITOR_VERSION}.alf \
    deserializeme/gcicudaeditor:latest \
    unity-editor -quit \
    -batchmode \
    -nographics \
    -logFile /dev/stdout \
    -createManualActivationFile \
    -username "YOUR_EMAIL_HERE" \
    -password "YOUR_PASSWORD_HERE" 
```

## Convert ALF to License file

Populate the config.json

```bash
docker run --rm -it -v $(pwd):/home/player1 \
    -v $(pwd)/Unity_v${EDITOR_VERSION}.alf:/Unity_v${EDITOR_VERSION}.alf \
    -v $(pwd)/config.json:/home/player1/config.json \
    deserializeme/gcicudaselenium:main \
    ./license.py *.alf config.json
```

## Manually install user-space driver

See [entrypoint.sh](https://github.com/selkies-project/docker-nvidia-glx-desktop/blob/main/entrypoint.sh) from the [docker-nvidia-glx-desktop](https://github.com/selkies-project/docker-nvidia-glx-desktop) for example.

## Host Preparation

Tested on Ubuntu22.04 and Debain12 hosts. See https://github.com/small-hack/smol-metal for instructions.


