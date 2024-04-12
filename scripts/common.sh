#!/bin/bash

echo "Common setup for all servers (Control Plane and Nodes)"

set -euxo pipefail

echo "DNS Setting"
if [ ! -d /etc/systemd/resolved.conf.d ]; then
	sudo mkdir /etc/systemd/resolved.conf.d/
fi
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dns_servers.conf
[Resolve]
DNS=${DNS_SERVERS}
EOF

if systemctl is-active --quiet systemd-resolved.service; then
  echo "Restart systemd-resolved to apply DNS settings"
  sudo systemctl restart systemd-resolved
else
  echo "systemd-resolved does not active!"
fi
#

echo "disable swap"
sudo swapoff -a

echo "keeps the swaf off during reboot"
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
sudo apt-get update -y


echo "Create the .conf file to load the modules at bootup"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

echo "Start modules overlay e br_netfilter"
sudo modprobe overlay
sudo modprobe br_netfilter

echo "Sysctl params required by setup, params persist across reboots"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

echo "Apply sysctl params without reboot"
sudo sysctl --system

echo "Install CRIO Runtime"
sudo apt-get update -y
apt-get install -y software-properties-common curl apt-transport-https ca-certificates

curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list

echo "Apply sysctl params without reboot"
sudo sysctl --system

echo "Install CRIO Runtime"

sudo apt-get update -y
apt-get install -y software-properties-common curl apt-transport-https ca-certificates

curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list

>>>>>>> 902a144b1ce6433fa5804e984244dcdc060deffe
sudo apt-get update -y
sudo apt-get install -y cri-o

sudo systemctl daemon-reload
sudo systemctl enable crio --now
sudo systemctl start crio.service

echo "CRI runtime installed successfully"

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION_SHORT/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION_SHORT/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
<<<<<<< HEAD

echo "Install Kubernetes tools..."
=======


>>>>>>> 902a144b1ce6433fa5804e984244dcdc060deffe
sudo apt-get update -y
sudo apt-get install -y kubelet="$KUBERNETES_VERSION" kubectl="$KUBERNETES_VERSION" kubeadm="$KUBERNETES_VERSION"
sudo apt-get update -y
sudo apt-get install -y jq yq

echo "Disable auto-update kubernetes tools"
sudo apt-mark hold kubelet kubectl kubeadm cri-o

echo "Configure KUBELET_EXTRA_ARGS parameter"

echo "Disable auto-update services"
sudo apt-mark hold kubelet kubectl kubeadm cri-o

echo "Configure KUBELET_EXTRA_ARGS"
local_ip="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
${ENVIRONMENT}
EOF

echo "Restart kubelet"
systemctl restart kubelet

# Configure kubectl autocompletion
apt-get install -y bash-completion
kubectl completion bash > /etc/bash_completion.d/kubectl
echo 'alias k=kubectl' >> /etc/bash.bashrc
echo 'complete -F __start_kubectl k' >> /etc/bash.bashrc

echo "Setup vimrc for user root and vagrant"
cat << EOF > /root/.vimrc
set nomodeline
set bg=dark
set tabstop=2
set expandtab
set ruler
set nu
syntax on
EOF
cp /root/.vimrc /home/vagrant/.vimrc && chown vagrant:vagrant /home/vagrant/.vimrc
