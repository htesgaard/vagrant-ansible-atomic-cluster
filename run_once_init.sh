#!/usr/bin/env bash
echo "one-shot provisioning start"
ansible-playbook /vagrant/ansible/playbooks/enable_host_only_network_after_reboot.yml
if [ $? -eq 0 ] ; then
  rm /vagrant/run_once_init.sh
  echo "one-shot provisioning completed"
else
  echo "one-shot provisioning failed"
fi

