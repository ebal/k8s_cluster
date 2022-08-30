resource "libvirt_domain" "domain-ubuntu" {
  for_each = local.VMs

  name = each.value.hostname

  memory = each.value.vmem
  vcpu   = each.value.vcpu

  cloudinit = libvirt_cloudinit_disk.cloud-init[each.key].id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  console {
    target_type = "serial"
    type        = "pty"
    target_port = "0"
  }
  console {
    target_type = "virtio"
    type        = "pty"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.ubuntu-base[each.key].id
  }

  depends_on = [libvirt_cloudinit_disk.cloud-init]
}

