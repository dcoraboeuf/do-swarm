##################################################################
# Definition of services to run on the Docker Swarm initially
##################################################################

resource "null_resource" "docker_swarm_services" {

  depends_on = [
    "digitalocean_droplet.docker_swarm_agent",
  ]

  connection {
    host = "${digitalocean_droplet.docker_swarm_master_initial.ipv4_address}"
    user = "${var.do_user}"
    private_key = "${file(var.do_ssh_key_private)}"
    agent = false
  }

  provisioner "file" {
    source = "infra.sh"
    destination = "/tmp/infra.sh"
  }

  # Configuration directories

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /tmp/conf/logstash",
      "mkdir -p /tmp/conf/prometheus/conf",
      "mkdir -p /tmp/conf/grafana/conf",
    ]
  }

  # Configuration of logstash

  provisioner "file" {
    source = "conf/logstash/",
    destination = "/tmp/conf/logstash"
  }

  # Configuration of prometheus

  provisioner "file" {
    source = "conf/prometheus/",
    destination = "/tmp/conf/prometheus/conf"
  }

  # Configuration of Grafana

  provisioner "file" {
    source = "conf/grafana/conf/",
    destination = "/tmp/conf/grafana/conf"
  }

  # Running all services

  provisioner "remote-exec" {
    inline = [
      "chmod u+x /tmp/infra.sh",
      "/tmp/infra.sh",
    ]
  }

}

##################################################################
# Grafana provisioning
##################################################################

resource "null_resource" "grafana_provisioning" {

  depends_on = [
    "null_resource.docker_swarm_services",
  ]

  provisioner "local-exec" {
    command = <<EOF
curl --fail --silent -v \
  "http://${digitalocean_droplet.docker_swarm_master_initial.ipv4_address}:3000/api/datasources" \
  --user admin:admin \
  --header "Content-Type: application/json" \
  -X POST \
  --data @conf/grafana/datasources/prometheus.json
EOF
  }

  provisioner "local-exec" {
    command = <<EOF
curl --fail --silent -v \
  "http://${digitalocean_droplet.docker_swarm_master_initial.ipv4_address}:3000/api/datasources" \
  --user admin:admin \
  --header "Content-Type: application/json" \
  -X POST \
  --data @conf/grafana/datasources/elasticsearch.json
EOF
  }

}
