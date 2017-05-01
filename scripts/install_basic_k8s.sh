#!/bin/bash
set -e
cd /vagrant/ansible/playbooks/k8s-install/
for i in 0[1-9]*.yml; do echo "$1" && ansible-playbook "$i" -i ../VAGRANT_INVENTORY; done
