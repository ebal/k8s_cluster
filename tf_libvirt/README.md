# Deploy the Ubuntu 24.04 LTS virtual machines to libvirt/QEMU using Terraform

Creating a Terraform repository to deploy a Kubernetes cluster for educational purposes.

It creates three (3) QEMU/KVM virtual machines running Ubuntu 24.04 LTS, provisioned through Libvirt.

## Step 0: Configure Variables

You need to edit **Variables.tf**

- timezone
- ssh port
- hostname
- vcpu
- vmem
- vol_size

and especially the Variable

- github user

... allowing you to access these VMs via SSH.

## Step 1: Initialize Terraform

```bash
terraform init

```

## Step 2: Preview the Infrastructure Changes 

```bash
terraform plan

```

## Step 3: Apply the Terraform Configuration

using a bash shell script to automate creation

```bash
./start.sh
```

## Console Output


```
Apply complete! Resources: 16 added, 0 changed, 0 destroyed.

Outputs:

VMs = [
  "192.168.122.223 k8scpnode1",
  "192.168.122.50  k8swrknode1",
  "192.168.122.10  k8swrknode2",
]
```

### Verify 

```bash
$ ssh -l ubuntu 192.168.122.223 hostname
k8scpnode1

$ ssh 192.168.122.223 -l ubuntu 'grep ^VERSION= /etc/os-release'
VERSION="24.10 (Oracular Oriole)"

```

## Destroy Everything

run destroy bash shell script

```bash
./destroy.sh

```

##  Root Password

If you need to set a root password for the Ubuntu 24.04 LTS virtual machine during its creation via Terraform

```bash
$ sudo virsh console k8scpnode1

userame:  root
password: ping

````
