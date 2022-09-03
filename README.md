# Creating a kubernetes cluster with kubeadm on Ubuntu 22.04 LTS

> [Kubernetes](https://kubernetes.io/), also known as **K8s**, is an open-source system for automating deployment, scaling, and management of containerized applications.

***Notice*** The initial blog post is here: [blog post](https://balaskas.gr/blog/2022/08/31/creating-a-kubernetes-cluster-with-kubeadm-on-ubuntu-2204-lts/)

<!-- toc -->

- [Prerequisites](#Prerequisites)
- [Git Terraform Code for the kubernetes cluster](#Git-Terraform-Code-for-the-kubernetes-cluster)
  - [Initilaze the working directory](#Initilaze-the-working-directory)
  - [Ubuntu 22.04 Image](#Ubuntu-2204-Image)
  - [Spawn the VMs](#Spawn-the-VMs)
- [Control-Plane Node](#Control-Plane-Node)
  - [Ports on the control-plane node](#Ports-on-the-control-plane-node)
  - [Firewall on the control-plane node](#Firewall-on-the-control-plane-node)
  - [Hosts file in the control-plane node](#Hosts-file-in-the-control-plane-node)
    - [Updating your hosts file](#Updating-your-hosts-file)
  - [No Swap on the control-plane node](#No-Swap-on-the-control-plane-node)
  - [Kernel modules on the control-plane node](#Kernel-modules-on-the-control-plane-node)
  - [NeedRestart on the control-plane node](#NeedRestart-on-the-control-plane-node)
    - [temporarily](#temporarily)
    - [permanently](#permanently)
  - [Installing a Container Runtime on the control-plane node](#Installing-a-Container-Runtime-on-the-control-plane-node)
  - [Installing kubeadm, kubelet and kubectl on the control-plane node](#Installing-kubeadm-kubelet-and-kubectl-on-the-control-plane-node)
  - [Initializing the control-plane node](#Initializing-the-control-plane-node)
  - [Create user access config to the k8s control-plane node](#Create-user-access-config-to-the-k8s-control-plane-node)
  - [Verify the control-plane node](#Verify-the-control-plane-node)
  - [Install an overlay network provider on the control-plane node](#Install-an-overlay-network-provider-on-the-control-plane-node)
  - [Verify CoreDNS is running on the control-plane node](#Verify-CoreDNS-is-running-on-the-control-plane-node)
- [Worker Nodes](#Worker-Nodes)
  - [Ports on the worker nodes](#Ports-on-the-worker-nodes)
  - [Firewall on the worker nodes](#Firewall-on-the-worker-nodes)
  - [Hosts file in the worker node](#Hosts-file-in-the-worker-node)
  - [No Swap on the worker node](#No-Swap-on-the-worker-node)
  - [Kernel modules on the worker node](#Kernel-modules-on-the-worker-node)
  - [NeedRestart on the worker node](#NeedRestart-on-the-worker-node)
  - [Installing a Container Runtime on the worker node](#Installing-a-Container-Runtime-on-the-worker-node)
  - [Installing kubeadm, kubelet and kubectl on the worker node](#Installing-kubeadm-kubelet-and-kubectl-on-the-worker-node)
  - [Get Token from the control-plane node](#Get-Token-from-the-control-plane-node)
  - [Get Certificate Hash from the control-plane node](#Get-Certificate-Hash-from-the-control-plane-node)
  - [Join Workers to the kubernetes cluster](#Join-Workers-to-the-kubernetes-cluster)
- [Is the kubernetes cluster running ?](#Is-the-kubernetes-cluster-running-)
- [Kubernetes Dashboard](#Kubernetes-Dashboard)
  - [Install kubernetes dashboard](#Install-kubernetes-dashboard)
  - [Add a Node Port to kubernetes dashboard](#Add-a-Node-Port-to-kubernetes-dashboard)
    - [Patch kubernetes-dashboard](#Patch-kubernetes-dashboard)
    - [Edit kubernetes-dashboard Service](#Edit-kubernetes-dashboard-Service)
  - [Accessing Kubernetes Dashboard](#Accessing-Kubernetes-Dashboard)
  - [Create An Authentication Token (RBAC)](#Create-An-Authentication-Token-RBAC)
    - [Creating a Service Account](#Creating-a-Service-Account)
    - [Creating a ClusterRoleBinding](#Creating-a-ClusterRoleBinding)
    - [Getting a Bearer Token](#Getting-a-Bearer-Token)
  - [Browsing Kubernetes Dashboard](#Browsing-Kubernetes-Dashboard)
- [Nginx App](#Nginx-App)
  - [Install nginx-app](#Install-nginx-app)
  - [Get Deployment](#Get-Deployment)
  - [Expose Nginx-App](#Expose-Nginx-App)
  - [Verify Service nginx-app](#Verify-Service-nginx-app)
  - [Describe Service nginx-app](#Describe-Service-nginx-app)
  - [Curl Nginx-App](#Curl-Nginx-App)
  - [Nginx-App from Browser](#Nginx-App-from-Browser)
- [That's it !](#Thats-it-)

<!-- tocstop -->

In this blog post, I'll try to share my personal notes on how to setup a kubernetes cluster with **kubeadm** on ubuntu 22.04 LTS Virtual Machines.

I am going to use three (3) Virtual Machines in my local lab. My home lab is based on [libvirt](https://libvirt.org/) Qemu/KVM (Kernel-based Virtual Machine) and I run [Terraform](https://terraform.io) as the infrastructure provision tool.

## Prerequisites

- at least 3 Virtual Machines of Ubuntu 22.04 (one for control-plane, two for worker nodes)
- 2GB (or more) of RAM on each Virtual Machine
- 2 CPUs (or more) on each Virtual Machine
- 20Gb of hard disk on each Virtual Machine
- No SWAP partition/image/file on each Virtual Machine

## Git Terraform Code for the kubernetes cluster

I prefer to have a reproducible infrastructure, so I can very fast create and destroy my test lab. My preferable way of doing things is testing on each step, so I pretty much destroy everything, coping and pasting commands and keep on. I use terraform for the create the infrastructure. You can find the code for the entire kubernetes cluster here: [k8s cluster - Terraform code](https://github.com/ebal/k8s_cluster/tree/main/tf_libvirt).

> If you do not use terraform, skip this step!

You can `git clone` the repo to review and edit it according to your needs.

```bash
git clone https://github.com/ebal/k8s_cluster.git
cd tf_libvirt

```

You will **need** to make appropriate changes. Open **Variables.tf** for that. The most important option to change, is the **User** option. Change it to your github username and it will download and setup the VMs with your public key, instead of mine!

But pretty much, everything else should work out of the box. Change the **vmem** and **vcpu** settings to your needs.

### Initilaze the working directory

**Init** terraform before running the below shell script.
This action will download in your local directory all the required teffarorm providers or modules.

```bash
terraform init

```

### Ubuntu 22.04 Image

Before going forward with spawning the VMs, we need to have the ubuntu 22.04 image on our system, or change the code to get it from the internet.

In **Variables.tf** terraform file, you will notice the below entries

```bash
# The image source of the VM
# cloud_image = "https://cloud-images.ubuntu.com/jammy/current/focal-server-cloudimg-amd64.img"
cloud_image = "../jammy-server-cloudimg-amd64.img"

```

If you do not want to download the Ubuntu 22.04 cloud server image then make the below change

```bash
# The image source of the VM
cloud_image = "https://cloud-images.ubuntu.com/jammy/current/focal-server-cloudimg-amd64.img"
#cloud_image = "../jammy-server-cloudimg-amd64.img"

```

otherwise you need to download it, in the upper directory, to speed things up

```bash
cd ../
curl -sLO https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
cd -

ls -l ../jammy-server-cloudimg-amd64.img

```

### Spawn the VMs

We are ready to spawn our 3 VMs by running `terraform plan` & `terraform apply`

```bash
./start.sh

```

output should be something like:

```bash
...
Apply complete! Resources: 16 added, 0 changed, 0 destroyed.

Outputs:

VMs = [
  "192.168.122.169  k8scpnode",
  "192.168.122.40   k8wrknode1",
  "192.168.122.8    k8wrknode2",
]

```

Verify that you have ssh access to the VMs

eg.

```bash
ssh  -l ubuntu 192.168.122.169

```

replace the IP with what the output gave you.

***DISCLAIMER*** if something failed, destroy everything with `./destroy.sh` to remove any garbages before run `./start.sh` again !!!

## Control-Plane Node

Let's us now start the configure of the k8s control-plane node.

### Ports on the control-plane node

Kubernetes runs a few services that needs to be accessable from the worker nodes.

| Protocol | Direction | Port Range | Purpose                 | Used By              |
|----------|-----------|------------|-------------------------|----------------------|
| TCP      | Inbound   | 6443       | Kubernetes API server   | All                  |
| TCP      | Inbound   | 2379-2380  | etcd server client API  | kube-apiserver, etcd |
| TCP      | Inbound   | 10250      | Kubelet API             | Self, Control plane  |
| TCP      | Inbound   | 10259      | kube-scheduler          | Self                 |
| TCP      | Inbound   | 10257      | kube-controller-manager | Self                 |

Although etcd ports are included in control plane section, you can also host your
own etcd cluster externally or on custom ports.

### Firewall on the control-plane node

We need to open the necessary ports on the CP's (control-plane node) firewall.

```bash
sudo ufw allow 6443/tcp
sudo ufw allow 2379:2380/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 10259/tcp
sudo ufw allow 10257/tcp

#sudo ufw disable
sudo ufw status

```

the output should be

```bash
To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
6443/tcp                   ALLOW       Anywhere
2379:2380/tcp              ALLOW       Anywhere
10250/tcp                  ALLOW       Anywhere
10259/tcp                  ALLOW       Anywhere
10257/tcp                  ALLOW       Anywhere
22/tcp (v6)                ALLOW       Anywhere (v6)
6443/tcp (v6)              ALLOW       Anywhere (v6)
2379:2380/tcp (v6)         ALLOW       Anywhere (v6)
10250/tcp (v6)             ALLOW       Anywhere (v6)
10259/tcp (v6)             ALLOW       Anywhere (v6)
10257/tcp (v6)             ALLOW       Anywhere (v6)

```

### Hosts file in the control-plane node

We need to update the `/etc/hosts` with the internal IP and hostname.
This will help when it is time to join the worker nodes.

```bash
echo $(hostname -I) $(hostname) | sudo tee -a /etc/hosts

```

Just a reminder: we need to update the hosts file to all the VMs.
To include all the VMs' IPs and hostnames.

If you already know them, then your `/etc/hosts` file should look like this:

```bash
192.168.122.169  k8scpnode
192.168.122.40   k8wrknode1
192.168.122.8    k8wrknode2

```

replace the IPs to yours.

#### Updating your hosts file

if you already the IPs of your VMs, run the below script to ALL 3 VMs

```bash
sudo tee -a /etc/hosts <<EOF

192.168.122.169  k8scpnode
192.168.122.40   k8wrknode1
192.168.122.8    k8wrknode2
EOF

```

### No Swap on the control-plane node

Be sure that **SWAP** is disabled in all virtual machines!

```bash
sudo swapoff -a

```

and the fstab file should not have any swap entry.

The below command should return nothing.

```bash
sudo grep -i swap /etc/fstab

```

If not, edit the `/etc/fstab` and remove the swap entry.

If you follow my terraform k8s code example from the above github repo,
you will notice that there isn't any swap entry in the cloud init (user-data) file.

Nevertheless it is always a good thing to douple check.

### Kernel modules on the control-plane node

We need to load the below kernel modules on all k8s nodes, so k8s can create some network magic!

- overlay
- br_netfilter

Run the below bash snippet that will do that, and also will enable the forwarding features of the network.

```bash
sudo tee /etc/modules-load.d/kubernetes.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

sudo lsmod | grep netfilter

sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

```

### NeedRestart on the control-plane node

Before installing any software, we need to make a tiny change to **needrestart** program. This will help with the automation of installing packages and will stop asking -via dialog- if we would like to restart the services!

#### temporarily

```bash
export -p NEEDRESTART_MODE="a"

```

#### permanently

a more permanent way, is to update the configuration file

```bash
echo "\$nrconf{restart} = 'a';" | sudo tee -a /etc/needrestart/needrestart.conf

```

### Installing a Container Runtime on the control-plane node

It is time to choose which container runtime we are going to use on our k8s cluster. There are a few container runtimes for k8s and in the past **docker** were used to. Nowadays the most common runtime is the **containerd** that can also uses the cgroup v2 kernel features. There is also a docker-engine runtime via CRI. Read [here](https://kubernetes.io/docs/setup/production-environment/container-runtimes/) for more details on the subject.

```bash
curl -sL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-keyring.gpg

sudo apt-add-repository -y "deb https://download.docker.com/linux/ubuntu jammy stable"

sleep 5

sudo apt -y install containerd.io

containerd config default                              \
 | sed 's/SystemdCgroup = false/SystemdCgroup = true/' \
 | sudo tee /etc/containerd/config.toml

sudo systemctl restart containerd.service

```

We have also enabled the

    systemd cgroup driver

so the control-plane node can use the cgroup v2 features.

### Installing kubeadm, kubelet and kubectl on the control-plane node

Install the kubernetes packages (kubedam, kubelet and kubectl) by first adding the k8s repository on our virtual machine. To speed up the next step, we will also download the configuration container images.

```bash
sudo curl -sLo /etc/apt/trusted.gpg.d/kubernetes-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

sudo apt-add-repository -y "deb http://apt.kubernetes.io/ kubernetes-xenial main"

sleep 5

sudo apt install -y kubelet kubeadm kubectl

sudo kubeadm config images pull

```

### Initializing the control-plane node

We can now initialize our control-plane node for our kubernetes cluster.

There are a few things we need to be careful about:

- We can specify the control-plane-endpoint if we are planning to have a high available k8s cluster. (we will skip this for now),
- Choose a Pod network add-on (next section) but be aware that CoreDNS (DNS and Service Discovery) will not run till then (later),
- define where is our container runtime socket (we will skip it)
- advertise the API server (we will skip it)

But we will define our Pod Network CIDR to the default value of the Pod network add-on so everything will go smoothly later on.

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

```

Keep the output in a notepad.

### Create user access config to the k8s control-plane node

Our k8s control-plane node is running, so we need to have credentials to access it.

The **kubectl** reads a configuration file (that has the token), so we copying this from k8s admin.

```bash
rm -rf $HOME/.kube

mkdir -p $HOME/.kube

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config

ls -la $HOME/.kube/config

alias k="kubectl"

```

### Verify the control-plane node

Verify that the kubernets is running.

That means we have a k8s cluster - but only the control-plane node is running.

```bash
kubectl cluster-info
#kubectl cluster-info dump

k get nodes -o wide; k get pods  -A -o wide

```

### Install an overlay network provider on the control-plane node

As I mentioned above, in order to use the DNS and Service Discovery services in the kubernetes (CoreDNS) we need to install a Container Network Interface (CNI) based Pod network add-on so that your Pods can communicate with each other.

We will use **[flannel](https://github.com/flannel-io/flannel)** as the simplest of them.

```bash
k apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

```

### Verify CoreDNS is running on the control-plane node

Verify that the control-plane node is Up & Running and the control-plane pods (as coredns pods) are also running

```bash
k get nodes -o wide

```

```bash
NAME        STATUS   ROLES           AGE   VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
k8scpnode   Ready    control-plane   54s   v1.25.0   192.168.122.169   <none>        Ubuntu 22.04.1 LTS   5.15.0-46-generic   containerd://1.6.8

```

```bash
k get pods -A -o wide

```

```bash
NAMESPACE    NAME                              READY STATUS  RESTARTS AGE IP              NODE      NOMINATED NODE READINESS GATES
kube-flannel kube-flannel-ds-zqv2b             1/1   Running 0        36s 192.168.122.169 k8scpnode <none>         <none>
kube-system  coredns-565d847f94-lg54q          1/1   Running 0        38s 10.244.0.2      k8scpnode <none>         <none>
kube-system  coredns-565d847f94-ms8zk          1/1   Running 0        38s 10.244.0.3      k8scpnode <none>         <none>
kube-system  etcd-k8scpnode                    1/1   Running 0        50s 192.168.122.169 k8scpnode <none>         <none>
kube-system  kube-apiserver-k8scpnode          1/1   Running 0        50s 192.168.122.169 k8scpnode <none>         <none>
kube-system  kube-controller-manager-k8scpnode 1/1   Running 0        50s 192.168.122.169 k8scpnode <none>         <none>
kube-system  kube-proxy-pv7tj                  1/1   Running 0        39s 192.168.122.169 k8scpnode <none>         <none>
kube-system  kube-scheduler-k8scpnode          1/1   Running 0        50s 192.168.122.169 k8scpnode <none>         <none>

```

<br>

That's it with the control-plane node !

<br>

## Worker Nodes

The below instructions works pretty much the same on both worker nodes.

I will document the steps for the worker1 node but do the same for the worker2 node.

### Ports on the worker nodes

As we learned above on the control-plane section, kubernetes runs a few services

| Protocol | Direction | Port Range  | Purpose           | Used By             |
|----------|-----------|-------------|-------------------|---------------------|
| TCP      | Inbound   | 10250       | Kubelet API       | Self, Control plane |
| TCP      | Inbound   | 30000-32767 | NodePort Services | All                 |

### Firewall on the worker nodes

so we need to open the necessary ports on the worker nodes too.

```bash
sudo ufw allow 10250/tcp
sudo ufw allow 30000:32767/tcp

sudo ufw status

```

output should look like

```bash
To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
10250/tcp                  ALLOW       Anywhere
30000:32767/tcp            ALLOW       Anywhere
22/tcp (v6)                ALLOW       Anywhere (v6)
10250/tcp (v6)             ALLOW       Anywhere (v6)
30000:32767/tcp (v6)       ALLOW       Anywhere (v6)

```

The next few steps are pretty much exactly the same as in the control-plane node.
In order to keep this documentation short, I'll just copy/paste the commands.

### Hosts file in the worker node

Update the `/etc/hosts` file to include the IPs and hostname of all VMs.

```bash
192.168.122.169  k8scpnode
192.168.122.40   k8wrknode1
192.168.122.8    k8wrknode2

```

### No Swap on the worker node

```bash
sudo swapoff -a

```

### Kernel modules on the worker node

```bash
sudo tee /etc/modules-load.d/kubernetes.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

sudo lsmod | grep netfilter

sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

```

### NeedRestart on the worker node

```bash
export -p NEEDRESTART_MODE="a"

```

### Installing a Container Runtime on the worker node

```bash
curl -sL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-keyring.gpg

sudo apt-add-repository -y "deb https://download.docker.com/linux/ubuntu jammy stable"

sleep 5

sudo apt -y install containerd.io

containerd config default                              \
 | sed 's/SystemdCgroup = false/SystemdCgroup = true/' \
 | sudo tee /etc/containerd/config.toml

sudo systemctl restart containerd.service

```

### Installing kubeadm, kubelet and kubectl on the worker node

```bash
sudo curl -sLo /etc/apt/trusted.gpg.d/kubernetes-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

sudo apt-add-repository -y "deb http://apt.kubernetes.io/ kubernetes-xenial main"

sleep 5

sudo apt install -y kubelet kubeadm kubectl

```

### Get Token from the control-plane node

To join nodes to the kubernetes cluster, we need to have a couple of things.

1. a token from control-plane node
2. the CA certificate hash from the contol-plane node.

If you didnt keep the output the initialization of the control-plane node, that's okay.

Run the below command in the control-plane node.

```bash
sudo kubeadm  token list

```

and we will get the initial token that expires after 24hours.

```bash
TOKEN                     TTL         EXPIRES                USAGES                   DESCRIPTION                                                EXTRA GROUPS
zt36bp.uht4cziweef1jo1h   23h         2022-08-31T18:38:16Z   authentication,signing   The default bootstrap token generated by 'kubeadm init'.   system:bootstrappers:kubeadm:default-node-token

```

In this case is the

    zt36bp.uht4cziweef1jo1h

### Get Certificate Hash from the control-plane node

To get the CA certificate hash from the control-plane-node, we need to run a complicated command:

```bash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'

```

and in my k8s cluster is:

```bash
a4833f8c82953370610efaa5ed93b791337232c3a948b710b2435d747889c085
```

### Join Workers to the kubernetes cluster

So now, we can Join our worker nodes to the kubernetes cluster.
Run the below command on both worker nodes:

```bash
sudo kubeadm join 192.168.122.169:6443 \
       --token zt36bp.uht4cziweef1jo1h \
       --discovery-token-ca-cert-hash sha256:a4833f8c82953370610efaa5ed93b791337232c3a948b710b2435d747889c085

```

we get this message

> Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

## Is the kubernetes cluster running ?

We can verify that

```bash
kubectl get nodes   -o wide
kubectl get pods -A -o wide

```

```bash
NAME         STATUS   ROLES           AGE     VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
k8scpnode    Ready    control-plane   64m     v1.25.0   192.168.122.169   <none>        Ubuntu 22.04.1 LTS   5.15.0-46-generic   containerd://1.6.8
k8wrknode1   Ready    <none>          2m32s   v1.25.0   192.168.122.40    <none>        Ubuntu 22.04.1 LTS   5.15.0-46-generic   containerd://1.6.8
k8wrknode2   Ready    <none>          2m28s   v1.25.0   192.168.122.8     <none>        Ubuntu 22.04.1 LTS   5.15.0-46-generic   containerd://1.6.8
```

```bash
NAMESPACE      NAME                                READY   STATUS    RESTARTS      AGE     IP                NODE         NOMINATED NODE   READINESS GATES
kube-flannel   kube-flannel-ds-52g92               1/1     Running   0             2m32s   192.168.122.40    k8wrknode1   <none>           <none>
kube-flannel   kube-flannel-ds-7qlm7               1/1     Running   0             2m28s   192.168.122.8     k8wrknode2   <none>           <none>
kube-flannel   kube-flannel-ds-zqv2b               1/1     Running   0             64m     192.168.122.169   k8scpnode    <none>           <none>
kube-system    coredns-565d847f94-lg54q            1/1     Running   0             64m     10.244.0.2        k8scpnode    <none>           <none>
kube-system    coredns-565d847f94-ms8zk            1/1     Running   0             64m     10.244.0.3        k8scpnode    <none>           <none>
kube-system    etcd-k8scpnode                      1/1     Running   0             64m     192.168.122.169   k8scpnode    <none>           <none>
kube-system    kube-apiserver-k8scpnode            1/1     Running   0             64m     192.168.122.169   k8scpnode    <none>           <none>
kube-system    kube-controller-manager-k8scpnode   1/1     Running   1 (12m ago)   64m     192.168.122.169   k8scpnode    <none>           <none>
kube-system    kube-proxy-4khw6                    1/1     Running   0             2m32s   192.168.122.40    k8wrknode1   <none>           <none>
kube-system    kube-proxy-gm27l                    1/1     Running   0             2m28s   192.168.122.8     k8wrknode2   <none>           <none>
kube-system    kube-proxy-pv7tj                    1/1     Running   0             64m     192.168.122.169   k8scpnode    <none>           <none>
kube-system    kube-scheduler-k8scpnode            1/1     Running   1 (12m ago)   64m     192.168.122.169   k8scpnode    <none>           <none>

```

That's it !

Our **k8s cluster** is running.

## Kubernetes Dashboard

> is a general purpose, web-based UI for Kubernetes clusters. It allows users to manage applications running in the cluster and troubleshoot them, as well as manage the cluster itself.

We can proceed by installing a k8s dashboard to our k8s cluster.

### Install kubernetes dashboard

One simple way to install the kubernetes-dashboard, is by applying the latest (as of this writing) yaml configuration file.

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.6.1/aio/deploy/recommended.yaml

```

the output of the above command should be something like

```bash

namespace/kubernetes-dashboard created
serviceaccount/kubernetes-dashboard created
service/kubernetes-dashboard created
secret/kubernetes-dashboard-certs created
secret/kubernetes-dashboard-csrf created
secret/kubernetes-dashboard-key-holder created
configmap/kubernetes-dashboard-settings created
role.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrole.rbac.authorization.k8s.io/kubernetes-dashboard created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
deployment.apps/kubernetes-dashboard created
service/dashboard-metrics-scraper created
deployment.apps/dashboard-metrics-scraper created

```

Verify the installation

```bash
kubectl get all -n kubernetes-dashboard

```

```bash
NAME                                             READY   STATUS    RESTARTS   AGE
pod/dashboard-metrics-scraper-64bcc67c9c-kvll7   1/1     Running   0          2m16s
pod/kubernetes-dashboard-66c887f759-rr4gn        1/1     Running   0          2m16s

NAME                                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/dashboard-metrics-scraper   ClusterIP   10.110.25.61    <none>        8000/TCP   2m16s
service/kubernetes-dashboard        ClusterIP   10.100.65.122   <none>        443/TCP    2m16s

NAME                                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/dashboard-metrics-scraper   1/1     1            1           2m16s
deployment.apps/kubernetes-dashboard        1/1     1            1           2m16s

NAME                                                   DESIRED   CURRENT   READY   AGE
replicaset.apps/dashboard-metrics-scraper-64bcc67c9c   1         1         1       2m16s
replicaset.apps/kubernetes-dashboard-66c887f759        1         1         1       2m16s

```

### Add a Node Port to kubernetes dashboard

Kubernetes Dashboard by default runs on a internal 10.x.x.x IP.

To access the dashboard we need to have a NodePort in the kubernetes-dashboard service.

We can either **Patch** the service or **edit** the yaml file.

Choose one of these two ways, do not run both of them (unnecessary - not harmful)

#### Patch kubernetes-dashboard

This is one way to add a NodePort.

```bash
kubectl --namespace kubernetes-dashboard patch svc kubernetes-dashboard -p '{"spec": {"type": "NodePort"}}'

```

output

```bash
service/kubernetes-dashboard patched

```

verify the service

```bash
kubectl get svc -n kubernetes-dashboard

```

```bash
NAME                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)         AGE
dashboard-metrics-scraper   ClusterIP   10.110.25.61    <none>        8000/TCP        11m
kubernetes-dashboard        NodePort    10.100.65.122   <none>        443:32709/TCP   11m

```

we can see the **30480** in the kubernetes-dashboard.

#### Edit kubernetes-dashboard Service

This is an alternative way to add a NodePort.

```bash
kubectl edit svc -n kubernetes-dashboard kubernetes-dashboard

```

and chaning the service type from

```bash
type: ClusterIP
```

to

```bash
type: NodePort
```

### Accessing Kubernetes Dashboard

The kubernetes-dashboard has two (2) pods, one (1) for metrics, one (2) for the dashboard.

To access the dashboard, first we need to identify in which Node is running.

```bash
kubectl get pods -n kubernetes-dashboard -o wide

```

```bash
NAME                                         READY   STATUS    RESTARTS   AGE     IP           NODE         NOMINATED NODE   READINESS GATES
dashboard-metrics-scraper-64bcc67c9c-fs7pt   1/1     Running   0          2m43s   10.244.1.9   k8wrknode1   <none>           <none>
kubernetes-dashboard-66c887f759-pzt4z        1/1     Running   0          2m44s   10.244.2.9   k8wrknode2   <none>           <none>

```

In my setup the dashboard pod is running on the **worker node 2** and from the `/etc/hosts` is on the **192.168.122.8** IP.

The NodePort is **32709**

```bash
k get svc -n kubernetes-dashboard -o wide

```

So, we can open a new tab on our browser and type:

```bash
https://192.168.122.8:32709

```

and accept the self-signed certificate!

![k8s_dashboard.jpg](attachments/317345a8.jpg)

### Create An Authentication Token (RBAC)

Last step for the kubernetes-dashboard is to create an authentication token.

#### Creating a Service Account

Create a new yaml file, with kind: **ServiceAccount** that has access to kubernetes-dashboard namespace and has name: admin-user.

```bash
cat > kubernetes-dashboard.ServiceAccount.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard

EOF

```

add this service account to the k8s cluster

```bash
kubectl apply -f kubernetes-dashboard.ServiceAccount.yaml

```

output

```bash
serviceaccount/admin-user created
```

#### Creating a ClusterRoleBinding

We need to bind the Service Account with the kubernetes-dashboard via Role-based access control.

```bash
cat > kubernetes-dashboard.ClusterRoleBinding.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard

EOF

```

apply this yaml file

```bash
kubectl apply -f kubernetes-dashboard.ClusterRoleBinding.yaml

```

```bash
clusterrolebinding.rbac.authorization.k8s.io/admin-user created

```

That means, our Service Account User has all the necessary roles to access the kubernetes-dashboard.

#### Getting a Bearer Token

Final step is to create/get a token for our user.

```bash
kubectl -n kubernetes-dashboard create token admin-user

```

```bash
eyJhbGciOiJSUzI1NiIsImtpZCI6Im04M2JOY2k1Yk1hbFBhLVN2cjA4X1pkdktXNldqWkR4bjB6MGpTdFgtVHcifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNjYxOTU2NDQ1LCJpYXQiOjE2NjE5NTI4NDUsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsInNlcnZpY2VhY2NvdW50Ijp7Im5hbWUiOiJhZG1pbi11c2VyIiwidWlkIjoiN2M4OWIyZDktMGIwYS00ZDg4LTk2Y2EtZDU3NjhjOWU2ZGYxIn19LCJuYmYiOjE2NjE5NTI4NDUsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlcm5ldGVzLWRhc2hib2FyZDphZG1pbi11c2VyIn0.RMRQkZZhcoC5vCvck6hKfqXJ4dfN4JoQyAaClHZvOMI6JgQZEfB2-_Qsh5MfFApJUEit-0TX9r3CzW3JqvB7dmpTPxUQvHK68r82WGveBVp1wF37UyXu_IzxiCQzpCWYr3GcVGAGZVBbhhqNYm765FV02ZA_khHrW3WpB80ikhm_TNLkOS6Llq2UiLFZyHHmjl5pwvGzT7YXZe8s-llZSgc0UenEwPG-82eE279oOy6r4_NltoV1HB3uu0YjUJPlkqAPnHuSfAA7-8A3XAAVHhRQvFPea1qZLc4-oD24AcU0FjWqDMILEyE8zaD2ci8zEQBMoxcf2qmj0wn9cfbZwQ

```

Add this token to the previous login page

![k8s_token.jpg](attachments/4e1384ce.jpg)

### Browsing Kubernetes Dashboard

eg. Cluster --> Nodes

![k8s_dashboard.jpg](attachments/3946b715.jpg)

## Nginx App

Before finishing this blog post, I would also like to share how to install a simple nginx-app as it is customary to do such thing in every new k8s cluster.

But plz excuse me, I will not get into much details.
You should be able to understand the below k8s commands.

### Install nginx-app

```bash
kubectl create deployment nginx-app --image=nginx --replicas=2

```

```bash
deployment.apps/nginx-app created
```

### Get Deployment

```bash
kubectl get deployment nginx-app -o wide
```

```bash
NAME        READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES   SELECTOR
nginx-app   2/2     2            2           64s   nginx        nginx    app=nginx-app
```

### Expose Nginx-App

```bash
kubectl expose deployment nginx-app --type=NodePort --port=80

```

```bash
service/nginx-app exposed
```

### Verify Service nginx-app

```bash
kubectl get svc nginx-app -o wide

```

```bash
NAME        TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE   SELECTOR
nginx-app   NodePort   10.98.170.185   <none>        80:31761/TCP   27s   app=nginx-app

```

### Describe Service nginx-app

```bash
kubectl describe svc nginx-app

```

```bash
Name:                     nginx-app
Namespace:                default
Labels:                   app=nginx-app
Annotations:              <none>
Selector:                 app=nginx-app
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.98.170.185
IPs:                      10.98.170.185
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  31761/TCP
Endpoints:                10.244.1.10:80,10.244.2.10:80
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>


```

### Curl Nginx-App

```bash
curl http://192.168.122.8:31761

```

```bash
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>


```

### Nginx-App from Browser

![k8s_nginx-app.jpg](attachments/88d4150c.jpg)

## That's it

I hope you enjoyed this blog post.

-ebal

```bash
./destroy.sh
```

```bash
...

libvirt_domain.domain-ubuntu["k8wrknode1"]: Destroying... [id=446cae2a-ce14-488f-b8e9-f44839091bce]
libvirt_domain.domain-ubuntu["k8scpnode"]: Destroying... [id=51e12abb-b14b-4ab8-b098-c1ce0b4073e3]
time_sleep.wait_for_cloud_init: Destroying... [id=2022-08-30T18:02:06Z]
libvirt_domain.domain-ubuntu["k8wrknode2"]: Destroying... [id=0767fb62-4600-4bc8-a94a-8e10c222b92e]
time_sleep.wait_for_cloud_init: Destruction complete after 0s
libvirt_domain.domain-ubuntu["k8wrknode1"]: Destruction complete after 1s
libvirt_domain.domain-ubuntu["k8scpnode"]: Destruction complete after 1s
libvirt_domain.domain-ubuntu["k8wrknode2"]: Destruction complete after 1s
libvirt_cloudinit_disk.cloud-init["k8wrknode1"]: Destroying... [id=/var/lib/libvirt/images/Jpw2Sg_cloud-init.iso;b8ddfa73-a770-46de-ad16-b0a5a08c8550]
libvirt_cloudinit_disk.cloud-init["k8wrknode2"]: Destroying... [id=/var/lib/libvirt/images/VdUklQ_cloud-init.iso;5511ed7f-a864-4d3f-985a-c4ac07eac233]
libvirt_volume.ubuntu-base["k8scpnode"]: Destroying... [id=/var/lib/libvirt/images/l5Rr1w_ubuntu-base]
libvirt_volume.ubuntu-base["k8wrknode2"]: Destroying... [id=/var/lib/libvirt/images/VdUklQ_ubuntu-base]
libvirt_cloudinit_disk.cloud-init["k8scpnode"]: Destroying... [id=/var/lib/libvirt/images/l5Rr1w_cloud-init.iso;11ef6bb7-a688-4c15-ae33-10690500705f]
libvirt_volume.ubuntu-base["k8wrknode1"]: Destroying... [id=/var/lib/libvirt/images/Jpw2Sg_ubuntu-base]
libvirt_cloudinit_disk.cloud-init["k8wrknode1"]: Destruction complete after 1s
libvirt_volume.ubuntu-base["k8wrknode2"]: Destruction complete after 1s
libvirt_cloudinit_disk.cloud-init["k8scpnode"]: Destruction complete after 1s
libvirt_cloudinit_disk.cloud-init["k8wrknode2"]: Destruction complete after 1s
libvirt_volume.ubuntu-base["k8wrknode1"]: Destruction complete after 1s
libvirt_volume.ubuntu-base["k8scpnode"]: Destruction complete after 2s
libvirt_volume.ubuntu-vol["k8wrknode1"]: Destroying... [id=/var/lib/libvirt/images/Jpw2Sg_ubuntu-vol]
libvirt_volume.ubuntu-vol["k8scpnode"]: Destroying... [id=/var/lib/libvirt/images/l5Rr1w_ubuntu-vol]
libvirt_volume.ubuntu-vol["k8wrknode2"]: Destroying... [id=/var/lib/libvirt/images/VdUklQ_ubuntu-vol]
libvirt_volume.ubuntu-vol["k8scpnode"]: Destruction complete after 0s
libvirt_volume.ubuntu-vol["k8wrknode2"]: Destruction complete after 0s
libvirt_volume.ubuntu-vol["k8wrknode1"]: Destruction complete after 0s
random_id.id["k8scpnode"]: Destroying... [id=l5Rr1w]
random_id.id["k8wrknode2"]: Destroying... [id=VdUklQ]
random_id.id["k8wrknode1"]: Destroying... [id=Jpw2Sg]
random_id.id["k8wrknode2"]: Destruction complete after 0s
random_id.id["k8scpnode"]: Destruction complete after 0s
random_id.id["k8wrknode1"]: Destruction complete after 0s

Destroy complete! Resources: 16 destroyed.

```
