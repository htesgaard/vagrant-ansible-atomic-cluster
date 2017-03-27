#!/bin/bash
set -e
cd /vagrant/scripts/
./prepare_nodes.sh
./install_k8s.sh
./configure_controller.sh