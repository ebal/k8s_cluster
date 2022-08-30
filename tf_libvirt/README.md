# Deploy ubuntu 22.04 LTS to libvirt/qemu via terraform

Terraform repo to deploy a kubernetes cluster for educational purposes.

It spawns three (3) Qemu/KVM Virtual Machines, based on ubuntu 22.04 LTS to libvirt.

## Variables

You need to edit **Variables.tf**

- timezone
- ssh port
- hostname
- vcpu
- vmem
- vol_size

and especially the Variable

- github user

so you can have ssh access to these VMs.

## init

```bash
terraform init

```

## start

```bash
./start.sh

...

Apply complete! Resources: 16 added, 0 changed, 0 destroyed.

Outputs:

VMs = [
  "192.168.122.169  k8scpnode",
  "192.168.122.40   k8wrknode1",
  "192.168.122.8    k8wrknode2",
]


$ ssh -l ubuntu 192.168.122.169 hostname
k8scpnode

$ ssh 192.168.122.169 -l ubuntu 'grep ^VERSION= /etc/os-release'
VERSION="22.04.1 LTS (Jammy Jellyfish)"

```

## destroy

```bash
./destroy.sh

```

## root password

if needed

```bash
$ sudo virsh console k8scpnode

userame:  root
password: ping

````
