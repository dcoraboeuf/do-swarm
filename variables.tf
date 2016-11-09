## AWS credentials

variable "aws_access_key" {
  description = "AWS Access key"
}

variable "aws_secret_key" {
  description = "AWS Secret key"
}

variable "aws_region" {
  description = "AWS Region"
}

## AWS node definition

variable "aws_ami_id" {
  description = "AMI ID of the image to use for all the nodes"
  default = "ami-8504fdea"
}

variable "aws_instance_type" {
  description = "EC2 instance type"
  default = "t2.nano"
}

## SSH key pair

variable "ssh_key_public" {
  description = "Path to the SSH public key"
  default = "./aws-key.pub"
}

variable "ssh_key_private" {
  description = "Path to the SSH private key"
  default = "./aws-key"
}

## Swarm configuration

variable "swarm_name" {
  description = "Name of the cluster, used also for networking"
  default = "swarm"
}

variable "swarm_master_count" {
  description = "Number of master nodes."
  default = "1"
}

variable "swarm_agent_count" {
  description = "Number of agents to deploy"
  default = "1"
}

## DNS setup

variable "dns_domain" {
  description = "Name of the DNS domain for the swarm"
  default = "nemerosa.net"
}

variable "dns_entry" {
  description = "Name of the swarm in the DNS domain"
  default = "swarm"
}
