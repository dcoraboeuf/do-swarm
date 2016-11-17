output "glusterfs_ip" {
  value = "${digitalocean_droplet.glusterfs_server.0.ipv4_address}"
}
