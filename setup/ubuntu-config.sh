
nvidia-smi
sudo docker run --rm --gpus all nvidia/cuda:11.6.2-base-ubuntu20.04 nvidia-smi


# install VSCode
# https://code.visualstudio.com/docs/setup/linux#_rhel-fedora-and-centos-based-distributions

# install Docker
# https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-22-04

#/etc/docker/daemon.json
{
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    },
    "default-runtime": "nvidia"
}


# check docker
sudo systemctl status docker



# install CUDA toolkit
# https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=22.04&target_type=deb_local
# sudo dpkg -i cuda-repo-ubuntu2204-12-0-local_12.0.0-525.60.13-1_amd64.deb


# gpu direct? 
# https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#ubuntu
# 

# Post actions:
# https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#post-installation-actions


# 

distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list



# How to setup the webcam
sudo apt-get install v4l2loopback-utils v4l2loopback-dkms ffmpeg


#  https://github.com/rbreaves/kinto




# https://docs.nvidia.com/datacenter/tesla/tesla-installation-notes/index.html#ubuntu-lts
# I installed with run file but I think better to use 

# https://www.howtogeek.com/devops/how-to-use-an-nvidia-gpu-with-docker-containers/