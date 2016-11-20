output "glusterfs_ip" {
  value = "${digitalocean_floating_ip.glusterfs_floating_ip.ip_address}"
}

output "glusterfs_volume" {
  value = "${var.glusterfs_volume_name}"
}
