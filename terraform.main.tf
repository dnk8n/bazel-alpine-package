variable "vpc_id" {
  default = ""
}
variable "ami_owner_alias" {
  default = "amazon"
}
variable "ami_name" {
  default = "amzn-ami-*-amazon-ecs-optimized"
}
variable "ami_most_recent" {
  default = true
}
variable "ssh_user" {
  default = "ec2-user"
}
variable "instance_type" {
  default = "t2.nano"
}
variable "region" {
  default = "us-east-1"
}
variable "zone" {
  default = "a"
}
variable "timeout_minutes" {
  default = 60
}
variable "build_dir" {
  default = "build"
}
variable "build_command" {
  type = "list"
}

provider "tls" {}

provider "aws" {
  region = "${var.region}"
}

data "aws_vpc" "provisioner" {
  default = "${var.vpc_id == "" ? true : false}"
  filter {
    name = "vpc-id"
    values = ["${var.vpc_id == "" ? "*" : var.vpc_id}"]
  }
}

data "aws_ami" "provisioner" {
  most_recent = "${var.ami_most_recent}"
  filter {
    name   = "owner-alias"
    values = ["${var.ami_owner_alias}"]
  }
  filter {
    name = "name"
    values = ["${var.ami_name}"]
  }
}

resource "tls_private_key" "provisioner" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "provisioner" {
  key_name   = "temp-provisioner-${uuid()}"
  public_key = "${tls_private_key.provisioner.public_key_openssh}"
}

resource "aws_security_group" "provisioner" {
  name = "temp-provisioner-${uuid()}"
  vpc_id = "${data.aws_vpc.provisioner.id}"
ingress {
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }
egress {
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "provisioner" {
  ami = "${data.aws_ami.provisioner.id}"
  instance_type = "${var.instance_type}"
  tags {
    Name = "temp-provisioner-${uuid()}"
  }
  availability_zone = "${var.region}${var.zone}"
  key_name      = "${aws_key_pair.provisioner.key_name}"
  vpc_security_group_ids = ["${aws_security_group.provisioner.id}"]
  user_data = <<EOF
#!/usr/bin/env bash
shutdown -P +${var.timeout_minutes}
EOF
  provisioner "file" {
    source      = "${var.build_dir}/"
    destination = "/tmp/"
    connection {
      user = "${var.ssh_user}"
      private_key = "${tls_private_key.provisioner.private_key_pem}"
      agent = false
    }
  }
  provisioner "remote-exec" {
    inline = "${var.build_command}"
    connection {
      user = "${var.ssh_user}"
      private_key = "${tls_private_key.provisioner.private_key_pem}"
      agent = false
    }
  }
}
