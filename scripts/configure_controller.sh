#!/bin/bash
set -e
cd ~
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
sudo mkdir -p /etc/kubernetes/certs/
sudo scp -r vagrant@atomic1:/etc/kubernetes/certs /etc/kubernetes/
mkdir ~/.kube
scp -r vagrant@atomic1:~/.kube ~/

echo "source <(kubectl completion bash)" >> ~/.bashrc
. ~/.bashrc

# show node pod capacity
sudo yum install jq -y
kubectl get node
echo 'Nodes must be STATUS "Ready" for the following command to complete successfully'
kubectl get node -o json | jq '.items[] | {name: .metadata.name, capacity: .status.capacity}'
kubectl get node
