# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 1.9.2"

unless Vagrant.has_plugin?("vagrant-hostmanager")
  raise 'Missing plugin! Install using the command: vagrant plugin install vagrant-hostmanager'
end
unless Vagrant.has_plugin?("vagrant-vbguest")
  raise 'Missing plugin! Install using the command: vagrant plugin install vagrant-vbguest'
end

$vm_gui = false
$vm_memory = 2048
$vm_cpus = 1
$vb_cpuexecutioncap = 100

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  #config.vm.box = "centos/atomic-host"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL

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

    h.vm.hostname = "control"
    # force virtualbox as mechanism for shared folders
    h.vm.synced_folder ".", "/vagrant", type: "virtualbox"
    h.vm.network "private_network", ip: "192.168.56.2"
    h.vm.provider :virtualbox do |vb|
      vb.gui = $vm_gui
      vb.memory = $vm_memory
      vb.cpus = $vm_cpus
      #vb.customize ['modifyvm', :id, '--cpuexecutioncap', "#{$vb_cpuexecutioncap}"]
      #vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
      #vb.customize ['modifyvm', :id, '--ioapic', 'on']

      # On CentOS support guest additions and functional vboxsf
      vb.check_guest_additions = true
      vb.functional_vboxsf     = true
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
atomic[0:0]

[kubernetes-kubelets]
atomic[1:1]

ANSIBLEHOSTSEOF

RUBY_HERE_DOCUMENT1

    h.vm.provision "shell", inline: 'sudo ansible all -i "localhost," -c local -m lineinfile -a "dest=/etc/ansible/ansible.cfg regexp=\'^#host_key_checking\' line=\'host_key_checking = False\'"'
  end


  config.vm.provision "shell", inline: "echo 'Hello from All'"


  (0..1).each do |n|
    config.vm.define "atomic#{n}" do |atomic|
      atomic.vm.provision "shell", inline: "echo 'Hello from Atomic'"
      # plugin conflict
      if Vagrant.has_plugin?("vagrant-vbguest") then
        config.vbguest.auto_update = false
      end

      atomic.vm.box = "centos/atomic-host"
      atomic.vm.hostname = "atomic#{n}"
      atomic.vm.network "private_network", ip: "192.168.56.#{n+10}"

      atomic.vm.provider :virtualbox do |vb|
        vb.gui = $vm_gui
        vb.memory = $vm_memory
        vb.cpus = $vm_cpus
        #vb.customize ['modifyvm', :id, '--cpuexecutioncap', "#{$vb_cpuexecutioncap}"]
        #vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
        #vb.customize ['modifyvm', :id, '--ioapic', 'on']
      end
      # centos hack to get the private_network going
      atomic.vm.provision "shell", run: "always", inline: "ifup enp0s8"
      atomic.vm.provision "file", source: "./vagrant.pub", destination: "/home/vagrant/vagrant.pub"
      atomic.vm.provision "shell", inline: "cat /home/vagrant/vagrant.pub >> /home/vagrant/.ssh/authorized_keys"
      atomic.vm.provision "shell", inline: "rm /home/vagrant/vagrant.pub"
      atomic.vm.provision "shell", inline: "echo 'LC_CTYPE=\"en_US.UTF-8\"' | sudo tee -a /etc/environment"
    end
  end
end
