###################################################################################################
# SSH key registration
###################################################################################################

resource "digitalocean_ssh_key" "docker_swarm_ssh_key" {
    name = "${var.do_swarm_name}-ssh-key"
    public_key = "${file(var.do_ssh_key_public)}"
}

###################################################################################################
# Flocker authentication file preparation
###################################################################################################

resource "null_resource" "flocker_authentication" {
   # Installation of the Flocker client
   provisioner "local-exec" {
      command = "flocker/local/authentication.sh ${var.flocker_client_path} ${var.flocker_client_name} ${var.do_swarm_name} ${var.docker_swarm_domain_name} ${var.docker_swarm_domain}"
   }
}

###################################################################################################
# Master node
###################################################################################################

resource "digitalocean_droplet" "docker_swarm_master_initial" {
   depends_on = [ "null_resource.flocker_authentication" ]
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
      private_key = "${file(var.do_ssh_key_private)}"
      agent = false
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

   # Flocker driver

   provisioner "remote-exec" {
      inline = [
         "mkdir -p /var/lib/flocker"
      ]
   }

   provisioner "file" {
      source = "flocker/remote/node.sh"
      destination = "/var/lib/flocker/node.sh"
   }

   provisioner "remote-exec" {
      inline = [
         "chmod u+x /var/lib/flocker/node.sh",
         "/var/lib/flocker/node.sh"
      ]
   }

   # Flocker control service installation

   provisioner "remote-exec" {
      inline = [
         "mkdir /etc/flocker"
      ]
   }

   provisioner "file" {
      source = "control-${var.docker_swarm_domain_name}.${var.docker_swarm_domain}.crt"
      destination = "/etc/flocker/control-service.crt"
   }

   provisioner "file" {
      source = "control-${var.docker_swarm_domain_name}.${var.docker_swarm_domain}.key"
      destination = "/etc/flocker/control-service.key"
   }

   provisioner "file" {
      source = "cluster.crt"
      destination = "/etc/flocker/"
   }

   provisioner "remote-exec" {
      inline = [
         "chmod 0700 /etc/flocker",
         "chmod 0600 /etc/flocker/control-service.key"
      ]
   }

   # Enabling the Flocker control service

   provisioner "file" {
      source = "flocker/remote/flocker-control.override"
      destination = "/etc/flocker/"
   }

   provisioner "remote-exec" {
      inline = [
         "echo 'flocker-control-api	    4523/tcp        # Flocker Control API port'   >> /etc/services",
         "echo 'flocker-control-agent   4524/tcp        # Flocker Control Agent port' >> /etc/services",
         "service flocker-control start",
         "ufw allow flocker-control-api",
         "ufw allow flocker-control-agent"
      ]
   }

}

###################################################################################################
# Master DNS registration
###################################################################################################

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

###################################################################################################
# TODO Other master nodes
###################################################################################################

###################################################################################################
# Swarm agents
###################################################################################################

resource "digitalocean_droplet" "docker_swarm_agent" {
   depends_on = [ "null_resource.flocker_authentication" ]

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
      private_key = "${file(var.do_ssh_key_private)}"
      agent = false
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

   # Flocker driver

   provisioner "remote-exec" {
      inline = [
         "mkdir -p /var/lib/flocker"
      ]
   }

   provisioner "file" {
      source = "flocker/remote/node.sh"
      destination = "/var/lib/flocker/node.sh"
   }

   provisioner "remote-exec" {
      inline = [
         "chmod u+x /var/lib/flocker/node.sh",
         "/var/lib/flocker/node.sh"
      ]
   }

   # Flocker node

   provisioner "remote-exec" {
      inline = [
         "mkdir /etc/flocker"
      ]
   }

   provisioner "file" {
      source = "flocker-ca-node/"
      destination = "/etc/flocker"
   }

   provisioner "file" {
      source = "flocker-ca-client-plugin/"
      destination = "/etc/flocker"
   }

   provisioner "file" {
      source = "cluster.crt"
      destination = "/etc/flocker/"
   }

   provisioner "remote-exec" {
      inline = [
         "chmod 0700 /etc/flocker",
         "chmod 0600 /etc/flocker/node.key"
      ]
   }

}
