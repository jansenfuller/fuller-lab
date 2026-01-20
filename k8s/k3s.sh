#!/usr/bin/bash
set -e

# Remove swap fstab line
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Turn off swap manually to continue
sudo swapoff -a

# Update and install NFS utils to allow NFS mounts
sudo apt update
sudo apt install nfs-common

# Change working directory for new bashrc
cd ~

mv .bashrc .bashrc_original || true

# Run install for master nodes
if [ "$1" == "server" ]; then
    # Install K3S
    curl -sfL https://get.k3s.io | K3S_URL=$2 K3S_TOKEN=$3 sh -s - server --disable=traefik --tls-san load_balancer_ip_or_hostname

    # Download and set new .bashrc
    wget -O .bashrc https://raw.githubusercontent.com/jansenfuller/fuller-lab/refs/heads/master/k8s/dev/serverrc.sh

    # Install Helm
    sudo apt install curl gpg apt-transport-https --yes
    curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt update
    sudo apt install helm

    # Make sure url and token are properly set
    echo "export K3S_URL=$1" >> .bashrc
    echo "export K3S_TOKEN=$2" >> .bashrc

# Run install for worker nodes
elif [ "$1" == "agent" ]; then
    # Install K3S Agent
    curl -sfL https://get.k3s.io | K3S_URL=$2 K3S_TOKEN=$3 sh -s - agent
    wget -O .bashrc https://raw.githubusercontent.com/jansenfuller/fuller-lab/refs/heads/master/k8s/dev/serverrc.sh

    # Make sure url and token are properly set
    echo "export K3S_URL=$1" >> .bashrc
    echo "export K3S_TOKEN=$2" >> .bashrc

else
    ip=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
    curl -sfL https://get.k3s.io | K3S_TOKEN=$1 sh -s - server --cluster-init --disable=traefik --tls-san $ip load_balancer_ip_or_hostname

    # Download and set new .bashrc
    wget -O .bashrc https://raw.githubusercontent.com/jansenfuller/fuller-lab/refs/heads/master/k8s/dev/serverrc.sh

    # Install Helm
    sudo apt install curl gpg apt-transport-https --yes
    curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt update
    sudo apt install helm
fi

source ~/.bashrc
k get nodes
