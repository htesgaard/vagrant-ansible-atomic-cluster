#!/bin/bash
#
# Copyright 2012 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

cd /vagrant/ansible/playbooks/
ansible-playbook 0_enable_host_only_network_after_reboot.yml -i VAGRANT_INVENTORY
ansible-playbook 0_force_upgrade_downgrade_atomic_version.yml -i VAGRANT_INVENTORY

cd /vagrant/ansible/playbooks/k8s-install/
for i in *.yml; do ansible-playbook "$i" -i ../VAGRANT_INVENTORY; done

# Linux
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
kubectl get nodes -o json | jq '.items[] | {name: .metadata.name, capacity: .status.capacity}'
kubectl get nodes
