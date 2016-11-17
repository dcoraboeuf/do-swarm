##################################################################################################
# GlusterFS server(s)
##################################################################################################

resource "digitalocean_droplet" "glusterfs_primary" {
  name = "${format("${var.glusterfs_cluster}-%02d", 0)}"

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

  provisioner "local-exec" {
    command = "echo \"${self.ipv4_address_private}\" ${self.name} >> hosts.txt"
  }

  provisioner "local-exec" {
    command = "echo \"${self.ipv4_address_private}:/storage \" >> hosts_string.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y python-software-properties",
      "add-apt-repository ppa:semiosis/ubuntu-glusterfs-3.8",
      "apt-get update",
      "apt-get install -y glusterfs-server",
      "mkdir -p ${var.glusterfs_storage_path}",
    ]
  }

}

##################################################################################################
# GlusterFS peer(s)
##################################################################################################
