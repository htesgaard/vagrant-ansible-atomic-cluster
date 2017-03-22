# -*- mode: ruby -*-
# vi: set ft=ruby :

# Get more inspiration here: https://github.com/errordeveloper/kubernetes-ansible-vagrant

Vagrant.require_version ">= 1.9.2"

unless Vagrant.has_plugin?("vagrant-hostmanager")
  raise 'Missing plugin! Install using the command: vagrant plugin install vagrant-hostmanager'
end
unless Vagrant.has_plugin?("vagrant-vbguest")
  raise 'Missing plugin! Install using the command: vagrant plugin install vagrant-vbguest'
end

Vagrant.configure("2") do |config|

  # always use Vagrants insecure key
  config.ssh.insert_key = false
  config.ssh.private_key_path = File.expand_path('./insecure_private_key')

  # forward ssh agent to easily ssh into the different machines
  config.ssh.forward_agent = true

  # Enable hostmanager by default - to update /etc/hosts (https://github.com/devopsgroup-io/vagrant-hostmanager)
  config.hostmanager.enabled = true


  # force virtualbox as mechanism for shared folders
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  config.hostmanager.enabled = true

  config.vm.provision "shell", inline: "echo 'Hello from Guest'"

  config.vm.box = "centos/7"


  config.vm.define "control", primary: true do |h|

    # plugin conflict
    if Vagrant.has_plugin?("vagrant-vbguest") then
      config.vbguest.auto_update = true
    end

    h.vm.provision "shell", inline: "echo 'LC_CTYPE=\"en_US.UTF-8\"' | sudo tee -a /etc/environment"
    h.vm.provision "file", source: "./insecure_private_key", destination: "/home/vagrant/insecure_private_key"
    h.vm.provision "shell", inline: "mv ./insecure_private_key ./.ssh/id_rsa", privileged: false
    h.vm.provision "shell", inline: "chmod 400 /home/vagrant/.ssh/id_rsa"
    h.vm.provision "shell", inline: "chown -R vagrant:vagrant /home/vagrant/.ssh/"
    h.vm.provision "shell", inline: "yum install epel-release -y"
    h.vm.provision "shell", inline: "yum install ansible -y"
    h.vm.provision "shell", :inline => <<'RUBY_HERE_DOCUMENT1'
    
sudo cat << ANSIBLEHOSTSEOF > /etc/ansible/hosts
# This is the default ansible 'hosts' file.
#
# It should live in /etc/ansible/hosts
#
#   - Comments begin with the '#' character
#   - Blank lines are ignored
#   - Groups of hosts are delimited by [header] elements
#   - You can enter hostnames or ip addresses
#   - A hostname/ip can be a member of multiple groups

[kubernetes-masters]
atomic[1:1]

[kubernetes-kubelets]
atomic[2:3]

ANSIBLEHOSTSEOF

RUBY_HERE_DOCUMENT1

    h.vm.provision "shell", inline: 'sudo ansible all -i "localhost," -c local -m lineinfile -a "dest=/etc/ansible/ansible.cfg regexp=\'^#host_key_checking\' line=\'host_key_checking = False\'"'

    h.vm.hostname = "control"
    # force virtualbox as mechanism for shared folders
    h.vm.synced_folder ".", "/vagrant", type: "virtualbox"
    h.vm.network "private_network", ip: "192.168.99.250", netmask: "255.255.255.0",
                 auto_config: true,
                 virtualbox__intnet: "k8s-net"
    h.vm.provider :virtualbox do |vb|
      vb.memory = 2048
      vb.gui = false
      #vb.customize ['modifyvm', :id, '--cpuexecutioncap', "#{$vb_cpuexecutioncap}"]
      #vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
      #vb.customize ['modifyvm', :id, '--ioapic', 'on']

      # On CentOS support guest additions and functional vboxsf
      vb.check_guest_additions = true
      vb.functional_vboxsf     = true
    end




  end

  config.vm.provision "shell", inline: "echo 'Hello from All'"

  (1..3).each do |index|
    config.vm.define "atomic#{index}" do |atomic|
      atomic.vm.provision "shell", inline: "echo 'Hello from Atomic'"
      # plugin conflict
      if Vagrant.has_plugin?("vagrant-vbguest") then
        config.vbguest.auto_update = false
      end

      atomic.vm.box = "centos/atomic-host"
      atomic.vm.hostname = "atomic#{index}"
      atomic.vm.provision :shell, inline: "sed 's/127\.0\.0\.1.*atomic.*/192\.168\.99\.#{index} k8s#{index}/' -i /etc/hosts"

      # centos hack to get the private_network going
      #atomic.vm.provision "shell", run: "always", inline: "ifup enp0s8"
      atomic.vm.provision "file", source: "./vagrant.pub", destination: "/home/vagrant/vagrant.pub"
      atomic.vm.provision "shell", inline: "cat /home/vagrant/vagrant.pub >> /home/vagrant/.ssh/authorized_keys"
      atomic.vm.provision "shell", inline: "rm /home/vagrant/vagrant.pub"
      atomic.vm.provision "shell", inline: "echo 'LC_CTYPE=\"en_US.UTF-8\"' | sudo tee -a /etc/environment"

      atomic.vm.network "private_network", ip: "192.168.99.#{index}", netmask: "255.255.255.0",
         auto_config: true,
         virtualbox__intnet: "k8s-net"
      atomic.vm.provider "virtualbox" do |v|
        #v.name = "k8s#{index}"
        v.memory = 2048
        v.gui = false
      end


    end
  end
end
