locals {
  allow_k8s_calico = "${var.aws_resource_prefix}_allow_k8s_calico"
}

# for Calico CNI
resource "aws_security_group" "allow_k8s_calico" {
  name        = local.allow_k8s_calico
  description = "Allow access between nodes for Calico CNI"
  vpc_id      = var.aws_vpc_id

  ingress {
    description      = "Calico Typha TCP"
    from_port        = 5473
    to_port          = 5473
    protocol         = "tcp"
    cidr_blocks      = [var.aws_subnet_cidr_block]
  }

  ingress {
    description      = "Calico VXLAN"
    from_port        = 4789
    to_port          = 4789
    protocol         = "udp"
    cidr_blocks      = [var.aws_subnet_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [var.aws_subnet_cidr_block]
  }

  tags = {
    Name = local.allow_k8s_calico,
    Project = var.aws_project,
    User = var.aws_username,
    Managed_By  =   "Terraform"
  }
}

