#!/bin/bash
set -e

echo "🚀 Installing Kubernetes 1.34 with containerd on Ubuntu 22.04"

# ------------------------------
# 1. Load Kernel Modules
# ------------------------------
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# ------------------------------
# 2. Kernel Networking Settings
# ------------------------------
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                = 1
EOF

sudo sysctl --system

# ------------------------------
# 3. Disable Swap
# ------------------------------
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# ------------------------------
# 4. Install containerd
# ------------------------------
sudo apt update
sudo apt install -y containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Enable systemd cgroup for Kubernetes
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

# ------------------------------
# 5. Install Kubernetes 1.34 repo
# ------------------------------
sudo apt install -y curl ca-certificates gnupg

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update

# ------------------------------
# 6. Install Kubernetes Components
# ------------------------------
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# ------------------------------
# 7. Final Verification
# ------------------------------
echo "✅ Versions Installed:"
kubeadm version
kubectl version --client
containerd --version

echo "🎉 Kubernetes 1.34 + containerd setup completed. Ready for kubeadm init or join."
