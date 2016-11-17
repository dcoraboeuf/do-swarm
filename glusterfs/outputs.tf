output "glusterfs_ip" {
  value = "${digitalocean_droplet.docker_swarm_master_initial.0.ipv4_address}"
}
