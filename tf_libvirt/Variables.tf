locals {
    # Virtual Machines
    VMs = {
        k8scpnode = {
            # The host name of the VM
            hostname = "k8scpnode"

            # The image source of the VM
            # cloud_image = "https://cloud-images.ubuntu.com/jammy/current/focal-server-cloudimg-amd64.img"
            cloud_image = "../jammy-server-cloudimg-amd64.img"

            # TimeZone of the VM: /usr/share/zoneinfo/
            timezone    = "Europe/Athens"

            # The sshd port of the VM"
            ssh_port    = 22

            # The default ssh key for user ubuntu
            # https://github.com/<username>.keys
            gh_user = "ebal"

            # The disk volume size of the VM
            # eg. 20G
            vol_size = 20 * 1024 * 1024 * 1024

            # How many virtual CPUs the VM
            vcpu = 2

            # How RAM will VM have will have
            vmem = 2048

        },

        k8wrknode1 = {
            # The host name of the VM
            hostname = "k8wrknode1"

            # The image source of the VM
            # cloud_image = "https://cloud-images.ubuntu.com/jammy/current/focal-server-cloudimg-amd64.img"
            cloud_image = "../jammy-server-cloudimg-amd64.img"

            # TimeZone of the VM: /usr/share/zoneinfo/
            timezone    = "Europe/Athens"

            # The sshd port of the VM"
            ssh_port    = 22

            # The default ssh key for user ubuntu
            # https://github.com/<username>.keys
            gh_user = "ebal"

            # The disk volume size of the VM
            # eg. 40G
            vol_size = 40 * 1024 * 1024 * 1024

            # How many virtual CPUs the VM
            vcpu = 4

            # How RAM will VM have will have
            vmem = 4096

        },

        k8wrknode2 = {
            # The host name of the VM
            hostname = "k8wrknode2"

            # The image source of the VM
            # cloud_image = "https://cloud-images.ubuntu.com/jammy/current/focal-server-cloudimg-amd64.img"
            cloud_image = "../jammy-server-cloudimg-amd64.img"

            # TimeZone of the VM: /usr/share/zoneinfo/
            timezone    = "Europe/Athens"

            # The sshd port of the VM"
            ssh_port    = 22

            # The default ssh key for user ubuntu
            # https://github.com/<username>.keys
            gh_user = "ebal"

            # The disk volume size of the VM
            # eg. 40G
            vol_size = 40 * 1024 * 1024 * 1024

            # How many virtual CPUs the VM
            vcpu = 4

            # How RAM will VM have will have
            vmem = 4096

        }

    }
}