## Digital Ocean credentials

variable "do_token" {
  description = "Your DigitalOcean API key"
}

## Digital Ocean settings

variable "do_region" {
  description = "DigitalOcean Region"
  default = "fra1"
}

variable "do_image" {
  description = "Slug for the image to install"
  default = "ubuntu"
}

variable "do_server_size" {
  description = "Server Size"
  default = "2GB"
}

variable "do_ssh_key_id" {
  description = "ID of the SSH record in DO"
}

variable "do_ssh_key_private" {
  description = "Path to the SSH private key"
  default = "./do-key"
}

variable "do_user" {
  description = "User to use to connect the machine using SSH. Depends on the image being installed."
  default = "root"
}

## GlusterFS variables

variable "glusterfs_cluster" {
  description = "Name of the GlusterFS cluster"
  default = "glusterfs"
}

variable "glusterfs_count" {
  description = "Number of GlusterFS servers"
  # TODO Increase the number of hosts
  default = "1"
}
