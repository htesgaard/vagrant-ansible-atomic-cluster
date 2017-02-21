#!/usr/bin/env bash
echo "Run once provisioning start"
ansible-playbook /vagrant/ansible/playbooks/enable_host_only_network_after_reboot.yml
if [ $? -eq 0 ] ; then
     rm ~/run_once_init.sh
    echo "Run once provisioning sucessfull"
else
    echo "Run once provisioning failed"
fi
