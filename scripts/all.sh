#!/bin/bash
set -e

prepare_nodes.sh
install_k8s.sh
configure_controller.sh