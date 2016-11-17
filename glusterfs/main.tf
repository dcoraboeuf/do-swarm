##################################################################################################
# GlusterFS server(s)
##################################################################################################

resource "digitalocean_droplet" "glusterfs_server" {
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

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y python-software-properties",
      "add-apt-repository ppa:semiosis/ubuntu-glusterfs-3.8",
      "apt-get update",
      "apt-get install -y glusterfs-server",
    ]
  }

}

##################################################################################################
# GlusterFS peer
##################################################################################################

//resource "null_resource" "glusterfs_peer" {
//  count = "${var.glusterfs_count}"
//
//  connection {
//    user = "${var.do_user}"
//    private_key = "${file(var.do_ssh_key_private)}"
//    agent = false
//  }
//}
