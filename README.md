# vagrant-ansible-atomic-cluster
A basic Vagrant setup to configure Kubernetes on Atomic boxes using Ansible.

#Prerequisites
* [Virtualbox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](https://www.vagrantup.com/docs/installation/)

##A note on vagrant/virtualbox networking
All nodes are configured with two NIC's one [NAT](https://www.virtualbox.org/manual/ch06.html#network_nat) and one [Host-Only](https://www.virtualbox.org/manual/ch06.html#network_hostonly).
This is common usage in [mulit-machine](https://www.vagrantup.com/docs/multi-machine/) vagrant setups.

Vagrant controls the virtual boxs using ssh port-forwarding on the 'default' NAT atapter. It's port forwarding on
the default NAT adapter thats used when you ssh into the box using `vagrant ssh <node>`.
        
The purpose of the Host-Only adapter is to allow the boxs to see each other. It's a virtual network segment.
In that way we build a multi-machine setup that acts like real machines.

Hostfiles are automatically configured, so any host can ping the other hosts by their names. The vagrant plugin
'vagrant-hostmanager' takes care of that. 

The multi-machine topology:

```bash
                                   TOPOLOGY

+-------------------------------------------------------------------------------+
|                                                                               |
|                                                                               |
|   +-----------------------------------------------------------+               |
|   |                                                           |               |
|   |                                         +-------+         |               |
|   |                                   +-----+master1+-----+   |               |
|   |                                   |     +-------+     |   |               |
|   |                                   |                   |   |               |
|   |                                   |     +-------+     |   |               |
|   |                                   +-----+minion1+-----+   |               |
|   |                 +---------+       |     +-------+     |   |   +-------+   |
|   |                 | control +-------+                   +-------+Vagrant|   |
|   |                 +---------+       |     +-------+     |   |   +-------+   |
|   |  After '^agrant up',              +-----+minion2+-----+ <- port forwarding|
|   |  use '^agrant ssh control'        |     +-------+     |   |               |
|   |  to enter the Ansible control     |                   |   |               |
|   |  box                              |     +-------+     |   |               |
|   |                                   +-----+minion3+-----+   |               |
|   |                              Host-only  +-------+ NAT     |               |
|   |                              network              network |               |
|   |Virtualbox                                                 |               |
|   +-----------------------------------------------------------+               |
|Host operating system                                                          |
+-------------------------------------------------------------------------------+
Created using: http://asciiflow.com/
```

##ssh pki authentication 
An example showing how the nodes can be accessed directly without authentication because 'contol' box public key is
included in `.ssh/authorized_keys` on all the other nodes.

From the 'control' box 'minion1' can be accessed directly without entering any passwords using the command: `ssh minion1`.

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
###Control node
*[centos7](https://www.centos.org/download/)
The control vm gets populated with virtualbox guest-additions. That allows it to use
[virtualbox synched folders](https://www.vagrantup.com/docs/synced-folders/virtualbox.html). In this setup
the current folder `.` (the folder containing the file 'Vagrantfile') is mapped to the path `/vagrant` inside the guest
os. I recommend to add a subfolder called ansible where ansible playbooks can be shared between the host and guest os.
E.g. if you prefer to edit the files in a tool like Intellij on the host os.


###Master and minion nodes
*[atomic](http://www.projectatomic.io/)

Atomic is "immutable infrastructure to deploy and scale your containerized applications. Project Atomic provides the
best platform for your Linux Docker Kubernetes (LDK) application stack."
The intention is not to allow tainting the kernel.

## Getting started
To get started `git clone` this [project](https://github.com/htesgaard/vagrant-ansible-atomic-cluster.git) and start up the nodes using the command `vagrant up`.


## Configure Ansible
Ansible is alredy installed on the 'control' node. Configure Ansible the current topology 
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
minion[1:3]
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

#Exercise
The idea is to configure Kubernetes on all the nodes running “atomic” using Ansible (on the 'control' node) as provisioning tool. All the “atomic” nodes contains Kubernetes and Docker software including kubectl and docker.

## Configure Kubernetes
Configure Kubernetes manually by following the guide [here](http://www.projectatomic.io/blog/2016/09/running-kubernetes-in-containers-on-atomic/)

When that is done, reset the atomic nodes using the command ´vagrant destroy -f master1 minion1 minion2 minion3 && vagrant up master1 minion1 minion2 minion3 ´, no it's time implement an Ansible playbook for automating configuring Kubernetes as an Ansible playbook.
  
## Vagrant tips

###Pausing and resuming
 ```bash
vagrant suspend && vagrant resume
 ``` 
 ###Stopping and starting
 ```bash
vagrant halt && vagrant up 
  ```
