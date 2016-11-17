##################################################################################################
# GlusterFS server(s)
##################################################################################################

resource "digitalocean_droplet" "docker_swarm_master_initial" {
  count = "${var.glusterfs_count}"
  name = "${format("${var.glusterfs_cluster}-%02d", count.index)}"

  image = "${var.do_image}"
  size = "${var.do_server_size}"
  region = "${var.do_region}"
  private_networking = true


  ssh_keys = [
    "${var.do_ssh_key_id}"
  ]

  connection {
    user = "${var.do_user}"
    private_key = "${file(var.do_ssh_key_private)}"
    agent = false
  }

}
