# vagrant-ansible-atomic-cluster
A basic Vagrant setup to configure Kubernetes on Atomic boxes using Ansible.

#Prerequisites
* [Virtualbox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](https://www.vagrantup.com/docs/installation/)

###Vagrant modules
```bash
$ vagrant plugin install vagrant-vbguest && vagrant plugin install vagrant-hostmanager
```


##A note on vagrant/virtualbox networking
All _boxes_ are configured with two NIC's one [NAT](https://www.virtualbox.org/manual/ch06.html#network_nat) and one [Host-Only](https://www.virtualbox.org/manual/ch06.html#network_hostonly).
This is common usage in [mulit-machine](https://www.vagrantup.com/docs/multi-machine/) vagrant setups.

Vagrant controls the virtual boxes using ssh port-forwarding on the _default_ NAT atapter. It's port forwarding on
the default NAT adapter thats used when you ssh into the box using `vagrant ssh <box>`.
        
The purpose of the Host-Only adapter is to allow the boxes to see each other. It's a virtual network segment.
In that way we build a multi-machine setup that acts like real machines.

Hostfiles are automatically configured, so any host can ping the other hosts by their names. The vagrant plugin
'vagrant-hostmanager' takes care of that. 

##Topology

```bash
+-------------------------------------------------------------------------------+
|                                                                               |
|                                                                               |
|   +-----------------------------------------------------------+               |
|   |                                                           |               |
|   |                                         +-------+         |               |
|   |                                   +-----+atomic0+-----+   |               |
|   |                                   |     +-------+     |   |               |
|   |                                   |                   |   |               |
|   |                                   |     +-------+     |   |               |
|   |                                   +-----+atomic1+-----+   |               |
|   |                 +---------+       |     +-------+     |   |   +-------+   |
|   |                 | control +-------+                   +-------+Vagrant|   |
|   |                 +---------+       |     +-------+     |   |   +-------+   |
|   |  After 'vagrant up',              +-----+atomic2+-----+ <- port forwarding|
|   |  use 'vagrant ssh control'        |     +-------+     |   |               |
|   |  to enter the Ansible control     |                   |   |               |
|   |  box                              |     +-------+     |   |               |
|   |                                   +-----+atomic3+-----+   |               |
|   |                              Host-only  +-------+ NAT     |               |
|   |                              network              network |               |
|   |Virtualbox                                                 |               |
|   +-----------------------------------------------------------+               |
|Host operating system                                                          |
+-------------------------------------------------------------------------------+
Created using: http://asciiflow.com/
```

##Usage

##Getting started
The atomic distribution fails initializing the network on vagrant 1.9.2. This seams to be related to the issue [8148](https://github.com/mitchellh/vagrant/pull/8148).

Calling vagrant up will cause this error on all the atomic boxes.

```bash
==> atomic1: Configuring and enabling network interfaces...
The following SSH command responded with a non-zero exit status.
Vagrant assumes that this means the command failed!

# Down the interface before munging the config file. This might
# fail if the interface is not actually set up yet so ignore
# errors.
/sbin/ifdown 'enp0s8'
# Move new config into place
mv -f '/tmp/vagrant-network-entry-enp0s8-1488809797-0' '/etc/sysconfig/network-scripts/ifcfg-enp0s8'
# attempt to force network manager to reload configurations
nmcli c reload || true

# Restart network
service network restart


Stdout from the command:

Restarting network (via systemctl):  [FAILED]


Stderr from the command:

usage: ifdown <configuration>
Job for network.service failed because the control process exited with error code. See "systemctl status network.service" and "journalctl -xe" for details.
```

But if you rerun 'vagrant up' a second time on all the atomic boxes, it will initialize correctly. So to start this ignoring the errors as a one-liner use this command:    
```bash
vagrant up control && (vagrant up atomic0 || vagrant up atomic0) && (vagrant up atomic1 || vagrant up atomic1) && (vagrant up atomic2 || vagrant up atomic2) && (vagrant up atomic3 || vagrant up atomic3)
```

Be shure to activate the hos-only adapters on the atomic hosts before running any other playbooks above. If the os is restarted the host-only NIC's won't auto start before this playbook has been played once.
That can be fixed as by running this command:
```bash
user@box ~/projects/vagrant/vagrant-ansible-atomic-cluster
$ vagrant ssh control
[vagrant@control ~]$ ansible-playbook /vagrant/ansible/playbooks/enable_host_only_network_after_reboot.yml
```

##ssh pki authentication 
An example showing how the _boxes_ can be accessed directly without authentication because _contol_ box public key is
included in `.ssh/authorized_keys` on all the other _boxes_.

From the _control_ box _minion1_ can be accessed directly without entering any passwords using the command: `ssh minion1`.

Detailed example:
```bash
user@box ~/projects/vagrant/vagrant-ansible-atomic-cluster
$ vagrant ssh control
Last login: Tue Feb 14 15:09:31 2017 from 10.0.2.2
[vagrant@control ~]$ ssh minion1
Warning: Permanently added 'minion1,192.168.56.21' (ECDSA) to the list of known hosts.
[vagrant@minion1 ~]$ exit
logout
Connection to minion1 closed.
[vagrant@control ~]$ ssh master1
Warning: Permanently added 'master1,192.168.56.11' (ECDSA) to the list of known hosts.
[vagrant@master1 ~]$ ping minion3
PING minion3 (192.168.56.23) 56(84) bytes of data.
64 bytes from minion3 (192.168.56.23): icmp_seq=1 ttl=64 time=0.479 ms
64 bytes from minion3 (192.168.56.23): icmp_seq=2 ttl=64 time=0.677 ms
^Z
[1]+  Stopped                 ping minion3
[vagrant@master1 ~]$ exit
logout
There are stopped jobs.
[vagrant@master1 ~]$ exit
logout
Connection to master1 closed.
[vagrant@control ~]$ ssh minion3
Warning: Permanently added 'minion3,192.168.56.23' (ECDSA) to the list of known hosts.
[vagrant@minion3 ~]$ exit
logout
Connection to minion3 closed.
[vagrant@control ~]$ exit
logout
Connection to 127.0.0.1 closed.
```

##  Atomic and Centos
The os-distros used in this setup is
###Control _box
*[centos7](https://www.centos.org/download/)

#### control box shared folder 
The control vm gets populated with virtualbox guest-additions. That allows it to use
[virtualbox synched folders](https://www.vagrantup.com/docs/synced-folders/virtualbox.html). In this setup
the current folder `.` (the folder containing the file _Vagrantfile_) is mapped to the path `/vagrant` inside the guest
os. I recommend to add a subfolder called ansible where ansible playbooks can be shared between the host and guest os.
This is usefull if you prefer to edit the files in a tool like Intellij on the host os and use the file in commands on
the _control_ box.
```bash
host-os@machine ~/projects/vagrant/vagrant-ansible-atomic-cluster
$ mkdir ansible

host-os@machine ~/projects/vagrant/vagrant-ansible-atomic-cluster
$ vagrant ssh control
Last login: Wed Feb 15 13:19:37 2017 from 10.0.2.2
[vagrant@control ~]$ ls /vagrant/
ansible  ansible.pub  README.md  Vagrantfile
[vagrant@control ~]$
```

###atomic boxes
*[atomic](http://www.projectatomic.io/)

Atomic is "immutable infrastructure to deploy and scale your containerized applications. Project Atomic provides the
best platform for your Linux Docker Kubernetes (LDK) application stack."
The intention is not to allow tainting the kernel.

# Getting started
To get started `git clone` this [project](https://github.com/htesgaard/vagrant-ansible-atomic-cluster.git) and start up the _boxes_ using the command `vagrant up`.

## Configure Ansible
Ansible is alredy installed on the _control_ _box. Configure Ansible the current topology 
by following guide [here](http://docs.ansible.com/ansible/intro_inventory.html)

To configure ansible to know the topology the /etc/ansible/hosts should contain this configuration
```bash
[vagrant@control ansible]$ cat hosts
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
minion[1:4]
```

To test the setup you should be able to execute the following command with success:
```bash
[vagrant@control ansible]$ ansible -m ping all
master1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
minion3 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
minion2 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
minion1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

#Errors

If you get this error try running `vagrant up` again
```bash
==> control: Mounting shared folders...
    control: /vagrant => /Users/helge/projects/vagrant/vagrant-ansible-atomic-cluster
Vagrant was unable to mount VirtualBox shared folders. This is usually
because the filesystem "vboxsf" is not available. This filesystem is
made available via the VirtualBox Guest Additions and kernel module.
Please verify that these guest additions are properly installed in the
guest. This is not a bug in Vagrant and is usually caused by a faulty
Vagrant box. For context, the command attempted was:

mount -t vboxsf -o uid=1000,gid=1000 vagrant /vagrant

The error output from the command was:

mount: unknown filesystem type 'vboxsf'
```

##Check if docker is running

The command `sudo systemctl status docker.service` should show that the docker daemon is running.
If not, check the systemd logs using the coimmand `sudo journalctl -u docker`.

*Note!* To interact with docker on atomic by default always do `sudo docker <cmd>`, that's because IPC access to the docker deamon via the file `/var/run/docker.sock` require sudo rights 
 
 

#Exercise
The idea is to configure Kubernetes on all the _boxes_ running “atomic” using Ansible (on the _control_ box) as provisioning tool. All the “atomic” _boxes_ contains Kubernetes and Docker software including kubectl and docker.

## Configure Kubernetes
Configure Kubernetes manually by following theese guides:
* [Containerized master](https://wiki.centos.org/SpecialInterestGroup/Atomic/ContainerizedMaster)
* [Project Atomic Getting Started Guide](http://www.projectatomic.io/docs/gettingstarted/)


When that is done, reset the atomic _boxes_ using the command ´vagrant destroy -f master1 minion1 minion2 minion3 && vagrant up master1 minion1 minion2 minion3 ´, no it's time implement an Ansible playbook for automating configuring Kubernetes as an Ansible playbook.
  
## Playbooks

Ensure atomic version 
```bash
user@box ~/projects/vagrant/vagrant-ansible-atomic-cluster
$ vagrant ssh control
Last login: Wed Feb 22 16:42:29 2017 from 10.0.2.2
[vagrant@control ~]$ ansible-playbook /vagrant/ansible/playbooks/force_upgrade_downgrade_atomic_version.yml
```
  
## Vagrant tips

###Pausing and resuming
```bash
vagrant suspend && vagrant resume
``` 

###Stopping and starting
```bash
vagrant halt && vagrant up 
```
