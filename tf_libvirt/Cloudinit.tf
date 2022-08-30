resource "random_id" "id" {
  for_each = local.VMs

  byte_length = 4
}

data "template_file" "user_data" {
  for_each = local.VMs

  template = file("templates/user-data.yml")
  vars = {
    hostname = each.value.hostname
    sshdport = each.value.ssh_port
    timezone = each.value.timezone
    gh_user  = each.value.gh_user
  }
}

data "template_file" "network_config" {
  template = file("templates/netplan.yml")
}

resource "libvirt_cloudinit_disk" "cloud-init" {
  for_each = local.VMs

  name      = "${random_id.id[each.key].id}_cloud-init.iso"
  user_data = data.template_file.user_data[each.key].rendered

  depends_on = [data.template_file.user_data]
}

resource "time_sleep" "wait_for_cloud_init" {
  create_duration = "20s"

  depends_on = [libvirt_cloudinit_disk.cloud-init]
}
