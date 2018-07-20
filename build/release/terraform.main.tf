variable "instance_name" {
  default = "builder"
}
variable "ami_name" {
  default = "amzn-ami-*-amazon-ecs-optimized"
}
variable "region" {}
variable "zone" {}

terraform {
    required_version = "~> 0.11.3"
}

provider "tls" {}

provider "aws" {
  version = "~> 1.10.0"
  region = "${var.region}"
}

data "aws_vpc" "default" {
  default = true
}

resource "tls_private_key" "builder" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "builder" {
  key_name   = "temp-builder"
  public_key = "${tls_private_key.builder.public_key_openssh}"
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_all"
  description = "Allow inbound SSH traffic from my IP"
  vpc_id = "${data.aws_vpc.default.id}"

ingress {
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "builder" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name = "name"
    values = ["${var.ami_name}"]
  }
}

resource "aws_instance" "builder" {
  ami = "${data.aws_ami.builder.id}"
  instance_type = "t2.medium"
  tags {
    Name = "${var.instance_name}"
  }
  availability_zone = "${var.region}${var.zone}"
  key_name      = "${aws_key_pair.builder.key_name}"
  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]
  provisioner "file" {
    source      = "dockerfile"
    destination = "/tmp/dockerfile"
    connection {
      user = "ec2-user"
      private_key = "${tls_private_key.builder.private_key_pem}"
      agent = false
    }
  }
  provisioner "remote-exec" {
    inline = [
      "mkdir /tmp/docker_build",
      "mv /tmp/dockerfile /tmp/docker_build/",
      "cd /tmp/docker_build",
      "docker build ."
    ]
    connection {
      user = "ec2-user"
      private_key = "${tls_private_key.builder.private_key_pem}"
      agent = false
    }
  }
}
