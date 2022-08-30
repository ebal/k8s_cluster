resource "libvirt_volume" "ubuntu-vol" {
  for_each = local.VMs

  name = "${random_id.id[each.key].id}_ubuntu-vol"
  pool = "default"
  source = each.value.cloud_image
  format = "qcow2"
}

resource "libvirt_volume" "ubuntu-base" {
  for_each = local.VMs

  name           = "${random_id.id[each.key].id}_ubuntu-base"
  pool           = "default"
  base_volume_id = libvirt_volume.ubuntu-vol[each.key].id
  size           = each.value.vol_size
  format         = "qcow2"
}
