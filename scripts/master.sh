#!/bin/bash

echo "Setup for Control Plane (Master) servers"

set -euxo pipefail

NODENAME=$(hostname -s)
echo "hostname is $NODENAME"

echo "kubeadm pull images..."
sudo kubeadm config images pull

echo "Preflight Check Passed: Downloaded All Required Images"

echo "Initialize cluster"
sudo kubeadm init --apiserver-advertise-address=$CONTROL_IP \
    --apiserver-cert-extra-sans=$CONTROL_IP \
    --pod-network-cidr=$POD_CIDR \
    --service-cidr=$SERVICE_CIDR \
    --node-name "$NODENAME" \
    --ignore-preflight-errors Swap

echo "Setting kubeconfig"
mkdir -p "$HOME"/.kube
sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

# Save Configs to shared /Vagrant location

echo "For Vagrant re-runs, check if there is existing configs in the location and delete it for saving new configuration."
config_path="/vagrant/configs"
if [ -d $config_path ]; then
  rm -rf $config_path
fi
mkdir -p $config_path

echo "Generate $config_path/join.sh"
cp -i /etc/kubernetes/admin.conf $config_path/config
touch $config_path/join.sh
chmod +x $config_path/join.sh
kubeadm token create --print-join-command > $config_path/join.sh

echo "Install Calico Network Plugin"
curl https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/calico.yaml -O
kubectl apply -f calico.yaml

echo "Configure /home/vagrant"
sudo -i -u vagrant bash << EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i $config_path/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
EOF


echo "Install Metrics Server"
kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml

