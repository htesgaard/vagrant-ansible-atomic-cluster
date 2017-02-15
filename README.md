# vagrant-ansible-atomic-cluster

#Prerequisites
* Virtualbox
* Vagrant


The system topology is:
```bash
$ vagrant status
Current machine states:

control                   running (virtualbox) – containing Ansible
master1                   running (virtualbox) – basic atomic node
minion1                   running (virtualbox) – basic atomic node
minion2                   running (virtualbox) – basic atomic node
minion3                   running (virtualbox) – basic atomic node
```

Hostfiles are automatically configured, so any host can ping the other hosts.

To get started `git clone` this project and start up the nodes using the command `vagrant up`.

The idea is to configure Kubernetes on all the nodes running “atomic” using ansible on ‘contol’ as provisioning tool . All the “atomic” nodes contains kubectl and docker.

ssh pki authentication is configured so you can do:
```bash
user@N63531 ~/projects/vagrant/vagrant-ansible-atomic-cluster
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

## Configure Ansible
Ansible is alredy installed on the 'control' node. Configure Ansible the current topology 
by following step 1-3 [here](https://github.com/leucos/ansible-tuto)

## Configure Kubernetes
Configure Kubernetes manually by following the guide [here] ()http://www.projectatomic.io/blog/2016/09/running-kubernetes-in-containers-on-atomic/)

When that is done, reset the atomic nodes using the command ´vagrant destroy -f master1 minion1 minion2 minion3 && vagrant up master1 minion1 minion2 minion3 ´, no it's time implement an Ansible playbook for automating configuring Kubernetes as an Ansible playbook.  