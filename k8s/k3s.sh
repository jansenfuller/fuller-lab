#!/usr/bin/bash
set -e

# Remove swap fstab line
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Turn off swap manually to continue
sudo swapoff -a

cd ~

mv .bashrc .bashrc_original

# Run install for master nodes
if [ $1 == "server" ]; then
        curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--flannel-backend --disable=traefik" sh -s - server --tls-san load_balancer_ip_or_hostname

        wget -O .bashrc https://raw.githubusercontent.com/jansenfuller/fuller-lab/refs/heads/master/k8s/dev/serverrc.sh

# Run install for worker nodes
else
        curl -sfL https://get.k3s.io | K3S_URL=$1 K3S_TOKEN=$2 sh -s - agent
        wget -O .bashrc https://raw.githubusercontent.com/jansenfuller/fuller-lab/refs/heads/master/k8s/dev/serverrc.sh

        echo "export K3S_URL=$1" >> .bashrc
        echo "export K3S_TOKEN=$2" >> .bashrc
fi
