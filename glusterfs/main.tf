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

resource "digitalocean_droplet" "glusterfs_peer" {
  count = "${var.glusterfs_peer_count}"
  name = "${format("${var.glusterfs_cluster}-%02d", count.index + 1)}"

  depends_on = [
    "digitalocean_droplet.glusterfs_primary"
  ]

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
# GlusterFS prober
##################################################################################################

resource "digitalocean_droplet" "glusterfs_prober" {
  name = "${format("${var.glusterfs_cluster}-%02d", 99)}"

  depends_on = [
    "digitalocean_droplet.glusterfs_peer"
  ]

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

  provisioner "file" {
    source = "./hosts.txt"
    destination = "/tmp/hosts.txt"
  }

  provisioner "file" {
    source = "./hosts_string.txt"
    destination = "/tmp/hosts_string.txt"
  }

  provisioner "local-exec" {
    command = "rm hosts.txt && rm hosts_string.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y python-software-properties",
      "add-apt-repository ppa:semiosis/ubuntu-glusterfs-3.8",
      "apt-get update",
      "apt-get install -y glusterfs-server",
      "mkdir -p ${var.glusterfs_storage_path}",
      "for host in `cat /tmp/hosts.txt | awk '{print $1}'`; do gluster peer probe $host && echo \"Peer Probe: $host\"; done",
      "sleep 15; gluster peer status",
      "echo `cat /tmp/hosts.txt` >> /etc/hosts",
      "gluster volume create ${var.glusterfs_volume_name} replica ${var.glusterfs_peer_count + 2} transport tcp `cat /tmp/hosts_string.txt` force",
      "gluster volume start ${var.glusterfs_volume_name}",
    ]
  }

}
