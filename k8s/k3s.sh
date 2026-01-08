#!/usr/bin/bash
set -e

# Remove swap fstab line
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Turn off swap manually to continue
sudo swapoff -a

# Change working directory for new bashrc
cd ~

mv .bashrc .bashrc_original

# Run install for master nodes
if [ $1 == "server" ]; then
    # Install K3S
    curl -sfL https://get.k3s.io | sh -s - --tls-san load_balancer_ip_or_hostname

    # Download and set new .bashrc
    wget -O .bashrc https://raw.githubusercontent.com/jansenfuller/fuller-lab/refs/heads/master/k8s/dev/serverrc.sh

    # Install Helm
    sudo apt-get install curl gpg apt-transport-https --yes
    curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update
    sudo apt-get install helm

# Run install for worker nodes
else
    # Install K3S Agent
    curl -sfL https://get.k3s.io | K3S_URL=$1 K3S_TOKEN=$2 sh -s - agent
    wget -O .bashrc https://raw.githubusercontent.com/jansenfuller/fuller-lab/refs/heads/master/k8s/dev/serverrc.sh

    # Make sure url and token are properly set
    echo "export K3S_URL=$1" >> .bashrc
    echo "export K3S_TOKEN=$2" >> .bashrc
fi

source .bashrc
k get nodes
