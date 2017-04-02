#!/bin/bash
set -e
cd /vagrant/ansible/playbooks/k8s-install/
for i in *.yml; do echo "$1" && ansible-playbook "$i" -i ../VAGRANT_INVENTORY; done
