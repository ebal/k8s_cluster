output "VMs" {
  value = [ for vms in libvirt_domain.domain-ubuntu : format("%s  %s", vms.network_interface.0.addresses[0], vms.name) ]

  depends_on = [libvirt_domain.domain-ubuntu]
}

