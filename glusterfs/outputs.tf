output "glusterfs_ip" {
  value = "${digitalocean_droplet.glusterfs_primary.ipv4_address}"
}

output "glusterfs_volume" {
  value = "${var.glusterfs_volume_name}"
}
