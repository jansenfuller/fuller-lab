#!/bin/sh
#!/bin/sh
set -e

# Remove swap fstab line
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Turn off swap manually to continue
sudo swapoff -a

# Detect Alpine version
ALPINE_VERSION=$(grep -oE '^[0-9]\+\.[0-9]\+' /etc/alpine-release)

# Add community repo
echo "https://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/community" \
  | sudo tee -a /etc/apk/repositories

# Add edge main, community, and testing repos
echo "https://dl-cdn.alpinelinux.org/alpine/edge/main" \
  | sudo tee -a /etc/apk/repositories
echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" \
  | sudo tee -a /etc/apk/repositories
echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" \
  | sudo tee -a /etc/apk/repositories

# Update and install NFS utils to allow NFS mounts
sudo apk update
sudo apk add nfs-common

# Change working directory for new bashrc
cd "$HOME"

mv .bashrc .bashrc_original 2>/dev/null || true

# Add C Groups
sudo sed -i 's/$/ cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1 swapaccount=1/' /boot/cmdline.txt

# Run install for master nodes
if [ "$1" = "server" ]; then

    # Install K3S
    curl -sfL https://get.k3s.io | K3S_URL="$2" K3S_TOKEN="$3" sh -s - server --disable=traefik --tls-san load_balancer_ip_or_hostname

    # Download and set new .bashrc
    wget -O .bashrc https://raw.githubusercontent.com/jansenfuller/fuller-lab/refs/heads/master/k8s/dev/serverrc.sh

    # Install Helm
    sudo apk update
    sudo apk add helm

    # Make sure url and token are properly set
    echo "export K3S_URL=$1" >> .bashrc
    echo "export K3S_TOKEN=$2" >> .bashrc

elif [ "$1" = "agent" ]; then
    # Install K3S Agent
    curl -sfL https://get.k3s.io | K3S_URL="$2" K3S_TOKEN="$3" sh -s - agent

    wget -O .bashrc https://raw.githubusercontent.com/jansenfuller/fuller-lab/refs/heads/master/k8s/dev/serverrc.sh

    echo "export K3S_URL=$1" >> .bashrc
    echo "export K3S_TOKEN=$2" >> .bashrc

else
    ip=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)

    curl -sfL https://get.k3s.io | K3S_TOKEN="$1" sh -s - server --cluster-init --disable=traefik --tls-san "$ip" load_balancer_ip_or_hostname

    wget -O .bashrc https://raw.githubusercontent.com/jansenfuller/fuller-lab/refs/heads/master/k8s/dev/serverrc.sh

    sudo apk update
    sudo apk add helm
fi

# POSIX-compatible alternative to "source"
. "$HOME/.bashrc"

k get nodes

