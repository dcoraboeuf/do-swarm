## Initialisation of local resources

resource "null_resource" "ssh_key" {
  provisioner "local-exec" {
    command = "rm -f aws-key* && ssh-keygen -t rsa -f ./aws-key -N ''"
  }
}

## AWS key pair

resource "aws_key_pair" "aws_ssh_key" {
  key_name = "${var.swarm_name}_ssh_key"
  public_key = "${file(var.ssh_key_public)}"
}
