# -*- mode: ruby -*-
# vi: set ft=ruby :

unless Vagrant.has_plugin?("vagrant-hostmanager")
  raise 'Missing plugin! Install using the command: vagrant plugin install vagrant-hostmanager'
end
unless Vagrant.has_plugin?("vagrant-vbguest")
  raise 'Missing plugin! Install using the command: vagrant plugin install vagrant-vbguest'
end

#http://www.thisprogrammingthing.com/2015/multiple-vagrant-vms-in-one-vagrantfile/


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
  # config.vm.box = "base"

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


  config.hostmanager.enabled = true

  #config.vbguest.iso_path = "http://download.virtualbox.org/virtualbox/%{version}/VBoxGuestAdditions_%{version}.iso"
  config.vbguest.auto_update = true

  controlBoxImage = "centos/7"
  atomicBoxImage = "centos/atomic-host"

  config.vm.provision "shell", inline: "echo 'Hello from Guest'"

  config.vm.define "control", primary: true do |h|
    h.vm.box = controlBoxImage
    h.vm.hostname = "control"
    # force virtualbox as mechanism for shared folders
    h.vm.synced_folder ".", "/vagrant", type: "virtualbox"
    h.vm.network "private_network", ip: "192.168.56.2"
    h.vm.provider :virtualbox do |v|
      #v.customize ["modifyvm", :id, "--memory", 2048]
      v.customize ["modifyvm", :id, "--name", "control"]
      # On CentOS support guest additions and functional vboxsf
      v.check_guest_additions = true
      v.functional_vboxsf     = true
    end

    # centos hack to get the private_network going
    h.vm.provision "shell", run: "always", inline: "systemctl restart network"
    h.vm.provision "shell", inline: "echo 'LC_CTYPE=\"en_US.UTF-8\"' | sudo tee -a /etc/environment"
    h.vm.provision "shell", inline: "yum install epel-release -y"
    h.vm.provision "shell", inline: "yum install ansible -y"
    h.vm.provision :shell, :inline => <<'EOF'
if [ ! -f "/home/vagrant/.ssh/id_rsa" ]; then
  ssh-keygen -t rsa -N "" -f /home/vagrant/.ssh/id_rsa
fi
cp /home/vagrant/.ssh/id_rsa.pub /vagrant/ansible.pub


cat << 'SSHEOF' > /home/vagrant/.ssh/config
Host *
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
SSHEOF

chown -R vagrant:vagrant /home/vagrant/.ssh/

sudo cat << 'ANSIBLEHOSTS' > /etc/ansible/hosts
# This is the default ansible 'hosts' file.
#
# It should live in /etc/ansible/hosts
#
#   - Comments begin with the '#' character
#   - Blank lines are ignored
#   - Groups of hosts are delimited by [header] elements
#   - You can enter hostnames or ip addresses
#   - A hostname/ip can be a member of multiple groups
[masters]
master1

[minions]
minion[1:3]
ANSIBLEHOSTS

EOF

    # Configure run-once provisioning thats activated when user logins to 'control'
    h.vm.provision :shell, privileged: false, inline: "cp /vagrant/ansible/config/run_once_init.sh ~ && chmod +x ~/run_once_init.sh"
    h.vm.provision :shell, privileged: false, inline: "echo \"[ ! -f ~/run_once_init.sh ] || ~/run_once_init.sh\" >> ~/.bashrc"
  end

  (1..1).each do |n|
    config.vm.define "master#{n}" do |master|
      # plugin not supported by centos/atomic-host
      if Vagrant.has_plugin?("vagrant-vbguest") then
        config.vbguest.auto_update = false
      end
      master.vm.box = atomicBoxImage
      master.vm.hostname = "master#{n}"
      master.vm.synced_folder ".", "/vagrant", disabled: true
      master.vm.network "private_network", ip: "192.168.56.#{n+10}"
      master.vm.provider :virtualbox do |v|
        v.customize ["modifyvm", :id, "--memory", 2048]
        v.customize ["modifyvm", :id, "--name", "master#{n}"]
        # On VirtualBox, we don't have guest additions or a functional vboxsf
        # in CoreOS, so tell Vagrant that so it can be smarter.
        v.check_guest_additions = false
        v.functional_vboxsf     = false
      end

      # centos hack to get the private_network going
      master.vm.provision "shell", run: "always", inline: "ifup enp0s8"
      master.vm.provision "shell", inline: "echo 'LC_CTYPE=\"en_US.UTF-8\"' | sudo tee -a /etc/environment"
      master.vm.provision "file", source: "./ansible.pub", destination: "/home/vagrant/ansible.pub"
      master.vm.provision "shell", inline: "cat /home/vagrant/ansible.pub >> /home/vagrant/.ssh/authorized_keys"
    end
  end


  (1..3).each do |n|
    config.vm.define "minion#{n}" do |minion|
      # plugin not supported by centos/atomic-host
      #if Vagrant.has_plugin?("vagrant-vbguest") then
      #  config.vbguest.auto_update = false
      #end
      minion.vm.box = atomicBoxImage
      minion.vm.hostname = "minion#{n}"
      minion.vm.synced_folder ".", "/vagrant", disabled: true

      minion.vm.network "private_network", ip: "192.168.56.#{n+20}"
      minion.vm.provider :virtualbox do |v|
        v.customize ["modifyvm", :id, "--memory", 2048]
        v.customize ["modifyvm", :id, "--name", "minion#{n}"]
        # On VirtualBox, we don't have guest additions or a functional vboxsf
        # in CoreOS, so tell Vagrant that so it can be smarter.
        v.check_guest_additions = false
        v.functional_vboxsf     = false
      end

      # centos hack to get the private_network going
      minion.vm.provision "shell", run: "always", inline: "ifup enp0s8"
      minion.vm.provision "shell", inline: "echo 'LC_CTYPE=\"en_US.UTF-8\"' | sudo tee -a /etc/environment"
      minion.vm.provision "file", source: "./ansible.pub", destination: "/home/vagrant/ansible.pub"
      minion.vm.provision "shell", inline: "cat /home/vagrant/ansible.pub >> /home/vagrant/.ssh/authorized_keys"
    end
  end


end
