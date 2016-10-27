resource "digitalocean_ssh_key" "docker_swarm_ssh_key" {
    name = "${var.do_swarm_name}-ssh-key"
    public_key = "${file(var.do_ssh_key_public)}"
}

resource "digitalocean_droplet" "docker_swarm_master_initial" {
   count = 1
   name = "${format("${var.do_swarm_name}-master-%02d", count.index)}"

   image = "docker"
   size = "${var.do_agent_size}"
   region = "${var.do_region}"
   private_networking = true

   user_data = "#cloud-config\n\nssh_authorized_keys:\n  - \"${file("${var.do_ssh_key_public}")}\"\n"
   ssh_keys = [ "${digitalocean_ssh_key.docker_swarm_ssh_key.id}" ]

   connection {
      user = "root"
      key_file = "${file(var.do_ssh_key_private)}"
   }

   provisioner "remote-exec" {
      inline = [
         "docker swarm init --advertise-addr ${self.ipv4_address}",
         "docker swarm join-token --quiet worker > /var/lib/docker/worker.token",
         "docker swarm join-token --quiet manager > /var/lib/docker/manager.token"
      ]
   }

   provisioner "local-exec" {
      command = "scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i ${var.do_ssh_key_private} root@${self.ipv4_address}:/var/lib/docker/worker.token ."
   }

   provisioner "local-exec" {
      command = "scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i ${var.do_ssh_key_private} root@${self.ipv4_address}:/var/lib/docker/manager.token ."
   }

   provisioner "remote-exec" {
      inline = [
         "curl -sSL -o /usr/bin/docker-volume-plugin-dostorage https://github.com/omallo/docker-volume-plugin-dostorage/releases/download/v0.3.0/docker-volume-plugin-dostorage_linux_amd64",
         "chmod +x /usr/bin/docker-volume-plugin-dostorage",
         "docker-volume-plugin-dostorage --access-token=${var.do_token} &",
         "service docker restart"
      ]
   }

}

resource "digitalocean_floating_ip" "docker_swarm_floating_ip" {
    droplet_id = "${digitalocean_droplet.docker_swarm_master_initial.id}"
    region = "${digitalocean_droplet.docker_swarm_master_initial.region}"
}

resource "digitalocean_record" "docker_swarm_dns_record" {
    domain = "${var.docker_swarm_domain}"
    type = "A"
    name = "${var.docker_swarm_domain_name}"
    value = "${digitalocean_floating_ip.docker_swarm_floating_ip.ip_address}"
}

# TODO Other masters

resource "digitalocean_droplet" "docker_swarm_agent" {
   count = "${var.do_swarm_agent_count}"
   name = "${format("${var.do_swarm_name}-agent-%02d", count.index)}"

   image = "docker"
   size = "${var.do_agent_size}"
   region = "${var.do_region}"
   private_networking = true

   user_data = "#cloud-config\n\nssh_authorized_keys:\n  - \"${file("${var.do_ssh_key_public}")}\"\n"
   ssh_keys = [ "${digitalocean_ssh_key.docker_swarm_ssh_key.id}" ]

   connection {
      user = "root"
      key_file = "${file(var.do_ssh_key_private)}"
   }

   provisioner "file" {
      source = "worker.token"
      destination = "/var/lib/docker/worker.token"
   }

   provisioner "remote-exec" {
      inline = [
         "docker swarm join --token $(cat /var/lib/docker/worker.token) ${digitalocean_droplet.docker_swarm_master_initial.ipv4_address}:2377"
      ]
   }

   provisioner "remote-exec" {
      inline = [
         "curl -sSL -o /usr/bin/docker-volume-plugin-dostorage https://github.com/omallo/docker-volume-plugin-dostorage/releases/download/v0.3.0/docker-volume-plugin-dostorage_linux_amd64",
         "chmod +x /usr/bin/docker-volume-plugin-dostorage",
         "docker-volume-plugin-dostorage --access-token=${var.do_token} &",
         "service docker restart"
      ]
   }
}
