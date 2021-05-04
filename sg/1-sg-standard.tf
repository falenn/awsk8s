locals {
  allow_tls = "${var.aws_resource_prefix}_allow_tls"
  allow_ssh = "${var.aws_resource_prefix}_allow_ssh"
  allow_all_egress = "${var.aws_resource_prefix}_allow_all_egress"
}

resource "aws_security_group" "allow_tls" {
  name        = local.allow_tls
  description = "Allow TLS inbound traffic"
  vpc_id      = var.aws_vpc_id

  ingress {
    description      = "TLS from Anywhere"
    from_port	     = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.allow_tls,
    Project = var.aws_project,
    User = var.aws_username,
    Managed_By  =   "Terraform"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = local.allow_ssh
  description = "Allow SSH inbound traffic"
  vpc_id      = var.aws_vpc_id

  ingress {
    description      = "SSH from VPC"
    from_port	     = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.allow_ssh,
    Project = var.aws_project,
    User = var.aws_username,
    Managed_By  =   "Terraform"
  }
}

resource "aws_security_group" "allow_all_egress" {
  name = local.allow_all_egress
  description = "Allow all traffic outbound"
  vpc_id = var.aws_vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = local.allow_all_egress,
    Project = var.aws_project,
    User = var.aws_username,
    Managed_By  =   "Terraform"
  }

}

