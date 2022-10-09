# Creating a kubernetes cluster with kubeadm on Ubuntu 22.04 LTS - weave

> [Kubernetes](https://kubernetes.io/), also known as **K8s**, is an open-source system for automating deployment, scaling, and management of containerized applications.

***Notice*** The initial blog post is here: [blog post](https://balaskas.gr/blog/2022/08/31/creating-a-kubernetes-cluster-with-kubeadm-on-ubuntu-2204-lts/)

<!-- toc -->

- [Prerequisites](#Prerequisites)
- [Git Terraform Code for the kubernetes cluster](#Git-Terraform-Code-for-the-kubernetes-cluster)
  * [Initilaze the working directory](#Initilaze-the-working-directory)
  * [Ubuntu 22.04 Image](#Ubuntu-2204-Image)
  * [Spawn the VMs](#Spawn-the-VMs)
- [Control-Plane Node](#Control-Plane-Node)
  * [Ports on the control-plane node](#Ports-on-the-control-plane-node)
  * [Firewall on the control-plane node](#Firewall-on-the-control-plane-node)
  * [Hosts file in the control-plane node](#Hosts-file-in-the-control-plane-node)
    + [Updating your hosts file](#Updating-your-hosts-file)
  * [No Swap on the control-plane node](#No-Swap-on-the-control-plane-node)
  * [Kernel modules on the control-plane node](#Kernel-modules-on-the-control-plane-node)
  * [NeedRestart on the control-plane node](#NeedRestart-on-the-control-plane-node)
    + [temporarily](#temporarily)
    + [permanently](#permanently)
  * [Installing a Container Runtime on the control-plane node](#Installing-a-Container-Runtime-on-the-control-plane-node)
  * [Installing kubeadm, kubelet and kubectl on the control-plane node](#Installing-kubeadm-kubelet-and-kubectl-on-the-control-plane-node)
  * [Initializing the control-plane node](#Initializing-the-control-plane-node)
  * [Create user access config to the k8s control-plane node](#Create-user-access-config-to-the-k8s-control-plane-node)
  * [Verify the control-plane node](#Verify-the-control-plane-node)
  * [Install an overlay network provider on the control-plane node](#Install-an-overlay-network-provider-on-the-control-plane-node)
    + [Weave Firewall in the control-plane node](#Weave-Firewall-in-the-control-plane-node)
  * [Verify CoreDNS is running on the control-plane node](#Verify-CoreDNS-is-running-on-the-control-plane-node)
- [Worker Nodes](#Worker-Nodes)
  * [Ports on the worker nodes](#Ports-on-the-worker-nodes)
  * [Firewall on the worker nodes](#Firewall-on-the-worker-nodes)
    + [Weave Firewall in the workder nodes](#Weave-Firewall-in-the-workder-nodes)
  * [Hosts file in the worker node](#Hosts-file-in-the-worker-node)
  * [No Swap on the worker node](#No-Swap-on-the-worker-node)
  * [Kernel modules on the worker node](#Kernel-modules-on-the-worker-node)
  * [NeedRestart on the worker node](#NeedRestart-on-the-worker-node)
  * [Installing a Container Runtime on the worker node](#Installing-a-Container-Runtime-on-the-worker-node)
  * [Installing kubeadm, kubelet and kubectl on the worker node](#Installing-kubeadm-kubelet-and-kubectl-on-the-worker-node)
  * [Get Token from the control-plane node](#Get-Token-from-the-control-plane-node)
  * [Get Certificate Hash from the control-plane node](#Get-Certificate-Hash-from-the-control-plane-node)
  * [Join Workers to the kubernetes cluster](#Join-Workers-to-the-kubernetes-cluster)
- [Is the kubernetes cluster running ?](#Is-the-kubernetes-cluster-running-)
- [Kubernetes Dashboard](#Kubernetes-Dashboard)
  * [Install Weave Scope](#Install-Weave-Scope)
  * [Port-forward to access weave-scope-app](#Port-forward-to-access-weave-scope-app)
  * [Port-forward to k8s cluster](#Port-forward-to-k8s-cluster)
  * [Accessing Weave Scope](#Accessing-Weave-Scope)
- [That's it](#Thats-it)

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
  "192.168.122.149  k8scpnode",
  "192.168.122.174  k8wrknode1",
  "192.168.122.243  k8wrknode2",
]

```

Verify that you have ssh access to the VMs

eg.

```bash
ssh  -l ubuntu 192.168.122.149

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
192.168.122.149  k8scpnode
192.168.122.174   k8wrknode1
192.168.122.243    k8wrknode2

```

replace the IPs to yours.

#### Updating your hosts file

if you already the IPs of your VMs, run the below script to ALL 3 VMs

```bash
sudo tee -a /etc/hosts <<EOF

192.168.122.149  k8scpnode
192.168.122.174  k8wrknode1
192.168.122.243  k8wrknode2

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

We will use **[Weave Net](https://www.weave.works/oss/net/)** as Weave creates a mesh overlay network between each of the nodes in the cluster, allowing for flexible routing between participants.

```bash
WEAVE="v2.8.1"
kubectl apply -f https://github.com/weaveworks/weave/releases/download/${WEAVE}/weave-daemonset-k8s.yaml

```

output

```bash
serviceaccount/weave-net created
clusterrole.rbac.authorization.k8s.io/weave-net created
clusterrolebinding.rbac.authorization.k8s.io/weave-net created
role.rbac.authorization.k8s.io/weave-net created
rolebinding.rbac.authorization.k8s.io/weave-net created
daemonset.apps/weave-net created

```

#### Weave Firewall in the control-plane node

permit traffic & metrics

```bash
sudo ufw allow 6781:6782/tcp
sudo ufw allow 6783
sudo ufw allow 6784/udp

sudo ufw status

```

### Verify CoreDNS is running on the control-plane node

Verify that the control-plane node is Up & Running and the control-plane pods (as coredns pods) are also running.

```bash
k get nodes -o wide

```

```bash
NAME        STATUS   ROLES           AGE   VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
k8scpnode   Ready    control-plane   54s   v1.25.0   192.168.122.149   <none>        Ubuntu 22.04.1 LTS   5.15.0-46-generic   containerd://1.6.8

```

```bash
k get pods -A -o wide

```

```bash
NAMESPACE    NAME                              READY STATUS  RESTARTS AGE IP              NODE      NOMINATED NODE READINESS GATES
kube-system  weave-net-rj29l                   2/2   Running 1      3h39m 192.168.122.149 k8scpnode <none>         <none>
kube-system  coredns-565d847f94-lg54q          1/1   Running 0        38s 10.32.0.2       k8scpnode <none>         <none>
kube-system  coredns-565d847f94-ms8zk          1/1   Running 0        38s 10.32.0.3       k8scpnode <none>         <none>
kube-system  etcd-k8scpnode                    1/1   Running 0        50s 192.168.122.149 k8scpnode <none>         <none>
kube-system  kube-apiserver-k8scpnode          1/1   Running 0        50s 192.168.122.149 k8scpnode <none>         <none>
kube-system  kube-controller-manager-k8scpnode 1/1   Running 0        50s 192.168.122.149 k8scpnode <none>         <none>
kube-system  kube-proxy-pv7tj                  1/1   Running 0        39s 192.168.122.149 k8scpnode <none>         <none>
kube-system  kube-scheduler-k8scpnode          1/1   Running 0        50s 192.168.122.149 k8scpnode <none>         <none>

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

#### Weave Firewall in the workder nodes

permit traffic & metrics

```bash
sudo ufw allow 6781:6782/tcp
sudo ufw allow 6783
sudo ufw allow 6784/udp

sudo ufw status

```

### Hosts file in the worker node

Update the `/etc/hosts` file to include the IPs and hostname of all VMs.

```bash
192.168.122.149  k8scpnode
192.168.122.174  k8wrknode1
192.168.122.243  k8wrknode2

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
or2jqe.r7uh6finztec4vgm   23h         2022-08-31T18:38:16Z   authentication,signing   The default bootstrap token generated by 'kubeadm init'.   system:bootstrappers:kubeadm:default-node-token

```

In this case is the

    or2jqe.r7uh6finztec4vgm

### Get Certificate Hash from the control-plane node

To get the CA certificate hash from the control-plane-node, we need to run a complicated command:

```bash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'

```

and in my k8s cluster is:

```bash
d306452ab5f05d68c0525468242a3ddd5df1627ebf1ca6915777cc462449ddeb
```

### Join Workers to the kubernetes cluster

So now, we can Join our worker nodes to the kubernetes cluster.
Run the below command on both worker nodes:

```bash
sudo kubeadm join 192.168.122.149:6443 \
       --token or2jqe.r7uh6finztec4vgm \
       --discovery-token-ca-cert-hash sha256:d306452ab5f05d68c0525468242a3ddd5df1627ebf1ca6915777cc462449ddeb

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
k8scpnode    Ready    control-plane   64m     v1.25.0   192.168.122.149   <none>        Ubuntu 22.04.1 LTS   5.15.0-46-generic   containerd://1.6.8
k8wrknode1   Ready    <none>          2m32s   v1.25.0   192.168.122.174   <none>        Ubuntu 22.04.1 LTS   5.15.0-46-generic   containerd://1.6.8
k8wrknode2   Ready    <none>          2m28s   v1.25.0   192.168.122.243   <none>        Ubuntu 22.04.1 LTS   5.15.0-46-generic   containerd://1.6.8
```

```bash
NAMESPACE      NAME                                READY   STATUS    RESTARTS  AGE     IP                NODE         NOMINATED NODE   READINESS GATES

kube-system   weave-net-7nnv4                     2/2     Running   0          3h28m   192.168.122.243   k8wrknode2   <none>           <none>
kube-system   weave-net-jnhx4                     2/2     Running   0          3h28m   192.168.122.174   k8wrknode1   <none>           <none>
kube-system   weave-net-rj29l                     2/2     Running   1          3h30m   192.168.122.149   k8scpnode    <none>           <none>

kube-system    coredns-565d847f94-lg54q           1/1     Running   0          64m     10.32.0.2         k8scpnode    <none>           <none>
kube-system    coredns-565d847f94-ms8zk           1/1     Running   0          64m     10.32.0.3         k8scpnode    <none>           <none>
kube-system    etcd-k8scpnode                     1/1     Running   0          64m     192.168.122.149   k8scpnode    <none>           <none>
kube-system    kube-apiserver-k8scpnode           1/1     Running   0          64m     192.168.122.149   k8scpnode    <none>           <none>
kube-system    kube-controller-manager-k8scpnode  1/1     Running   1          64m     192.168.122.149   k8scpnode    <none>           <none>
kube-system    kube-proxy-4khw6                   1/1     Running   0          2m32s   192.168.122.174   k8wrknode1   <none>           <none>
kube-system    kube-proxy-gm27l                   1/1     Running   0          2m28s   192.168.122.243   k8wrknode2   <none>           <none>
kube-system    kube-proxy-pv7tj                   1/1     Running   0          64m     192.168.122.149   k8scpnode    <none>           <none>
kube-system    kube-scheduler-k8scpnode           1/1     Running   1          64m     192.168.122.149   k8scpnode    <none>           <none>

```

That's it !

Our **k8s cluster** is running.

## Kubernetes Dashboard

> is a general purpose, web-based UI for Kubernetes clusters. It allows users to manage applications running in the cluster and troubleshoot them, as well as manage the cluster itself.

We can proceed by installing a k8s dashboard to our k8s cluster.

### Install Weave Scope

One simple way to install the Weave Scope, is by applying the latest (as of this writing) yaml configuration file.

```bash
SCOPE=v1.13.2
kubectl apply -f https://github.com/weaveworks/scope/releases/download/${SCOPE}/k8s-scope.yaml

```

the output of the above command should be something like

```bash
namespace/weave created
clusterrole.rbac.authorization.k8s.io/weave-scope created
clusterrolebinding.rbac.authorization.k8s.io/weave-scope created
deployment.apps/weave-scope-app created
daemonset.apps/weave-scope-agent created
deployment.apps/weave-scope-cluster-agent created
serviceaccount/weave-scope created
service/weave-scope-app created

```

Verify the installation

```bash
kubectl get all -o wide -n weave

```

```bash
NAME                                             READY   STATUS    RESTARTS   AGE     IP                NODE         NOMINATED NODE   READINESS GATES
pod/weave-scope-agent-gktkj                      1/1     Running   0          3m26s   192.168.122.174   k8wrknode1   <none>           <none>
pod/weave-scope-agent-prp68                      1/1     Running   0          3m27s   192.168.122.149   k8scpnode    <none>           <none>
pod/weave-scope-agent-tmbrg                      1/1     Running   0          3m26s   192.168.122.243   k8wrknode2   <none>           <none>
pod/weave-scope-app-8ccc4d754-6xcdh              1/1     Running   0          3m27s   10.44.0.1         k8wrknode2   <none>           <none>
pod/weave-scope-cluster-agent-59cc85cbcc-x4dvc   1/1     Running   0          3m26s   10.36.0.1         k8wrknode1   <none>           <none>

NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE     SELECTOR
service/weave-scope-app   ClusterIP   10.101.147.223   <none>        80/TCP    3m26s   app=weave-scope,name=weave-scope-app,weave-cloud-component=scope,weave-scope-component=app

NAME                               DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE     CONTAINERS    IMAGES                    SELECTOR
daemonset.apps/weave-scope-agent   3         3         3       3            3           <none>          3m27s   scope-agent   weaveworks/scope:1.13.2   app=weave-scope

NAME                                        READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS            IMAGES                              SELECTOR
deployment.apps/weave-scope-app             1/1     1            1           3m27s   app                   weaveworks/scope:1.13.2             app=weave-scope
deployment.apps/weave-scope-cluster-agent   1/1     1            1           3m27s   scope-cluster-agent   docker.io/weaveworks/scope:1.13.2   app=weave-scope,name=weave-scope-cluster-agent,weave-cloud-component=scope,weave-scope-component=cluster-agent

NAME                                                   DESIRED   CURRENT   READY   AGE     CONTAINERS            IMAGES                              SELECTOR
replicaset.apps/weave-scope-app-8ccc4d754              1         1         1       3m27s   app                   weaveworks/scope:1.13.2             app=weave-scope,pod-template-hash=8ccc4d754
replicaset.apps/weave-scope-cluster-agent-59cc85cbcc   1         1         1       3m27s   scope-cluster-agent   docker.io/weaveworks/scope:1.13.2   app=weave-scope,name=weave-scope-cluster-agent,pod-template-hash=59cc85cbcc,weave-cloud-component=scope,weave-scope-component=cluster-agent

```

### Port-forward to access weave-scope-app

Not a permament solution but a quick one to forward the internal Port: 80 to our control-plane node port 4040:

```bash
 kubectl port-forward svc/weave-scope-app -n weave 4040:80
Forwarding from 127.0.0.1:4040 -> 4040
Forwarding from [::1]:4040 -> 4040

Handling connection for 4040
Handling connection for 4040

```

### Port-forward to k8s cluster

We need to port-forward the control-plane node's port: 4040 to our localhost via ssh:

```bash
$ ssh -L:4040:127.0.0.1:4040 192.168.122.149 -l ubuntu
Welcome to Ubuntu 22.04.1 LTS (GNU/Linux 5.15.0-48-generic x86_64)

```

### Accessing Weave Scope

Open a new tab on our browser and type:

```bash
http://127.0.0.1:4040

```

![k8s_weave_scope1.jpg](attachments/k8s_weave_scope1.jpg)


![k8s_weave_scope2.jpg](attachments/k8s_weave_scope2.jpg)


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
