## Initialisation of local resources

resource "null_resource" "ssh_key" {
  provisioner "local-exec" {
    command = "ssh-keygen -t rsa -f ./aws-key -N ''"
  }
}
