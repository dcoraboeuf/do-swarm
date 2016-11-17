output "glusterfs_ip" {
  value = "${digitalocean_droplet.glusterfs_primary.ipv4_address}"
}
