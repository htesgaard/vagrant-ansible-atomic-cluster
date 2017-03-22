#!/bin/bash
cd /vagrant/ansible/playbooks/
ansible-playbook 0_enable_host_only_network_after_reboot.yml -i VAGRANT_INVENTORY
ansible-playbook 0_force_upgrade_downgrade_atomic_version.yml -i VAGRANT_INVENTORY

