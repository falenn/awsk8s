locals {
  allow_k8s_api = "${var.aws_resource_prefix}_allow_k8s_api"
  allow_k8s_management = "${var.aws_resource_prefix}_allow_k8s_management"
}

resource "aws_security_group" "allow_k8s_api" {
  name        = local.allow_k8s_api
  description = "Allow TLS to K8s API Serve from specified CIDR address range"
  vpc_id      = var.aws_vpc_id

  ingress {
    description      = "TLS from Anywhere"
    from_port        = 6443
    to_port          = 6443
    protocol         = "tcp"
    cidr_blocks      = [var.aws_k8s_api_access_cidr_block]
  }

  tags = {
    Name = local.allow_k8s_api,
    Project = var.aws_project,
    User = var.aws_username,
    Managed_By  =   "Terraform"
  }
}


# for kube-sched, kube api control plane, etc.
resource "aws_security_group" "allow_k8s_management" {
  name        = local.allow_k8s_management
  description = "Allow access between nodes to k8s scheduler and api control plane, etc."
  vpc_id      = var.aws_vpc_id

  ingress {
    description      = "API control plane"
    from_port        = 10250
    to_port          = 10250
    protocol         = "tcp"
    cidr_blocks      = [var.aws_subnet_cidr_block]
  }

  ingress {
    description      = "k8s scheduler"
    from_port        = 10251
    to_port          = 10251
    protocol         = "tcp"
    cidr_blocks      = [var.aws_subnet_cidr_block]
  }

  ingress {
    description      = "k8s controller manager"
    from_port        = 10252
    to_port          = 10252
    protocol         = "tcp"
    cidr_blocks      = [var.aws_subnet_cidr_block]
  }

  ingress {
    description      = "Etcd"
    from_port        = 2379
    to_port          = 2380
    protocol         = "tcp"
    cidr_blocks      = [var.aws_subnet_cidr_block]
  }

  ingress {
    description      = "nodeport"
    from_port        = 30000
    to_port          = 32767
    protocol         = "tcp"
    cidr_blocks      = [var.aws_vpc_main_cidr_block, var.aws_k8s_nodeport_access_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [var.aws_vpc_main_cidr_block]
  }

  tags = {
    Name = local.allow_k8s_management,
    Project = var.aws_project,
    User = var.aws_username,
    Managed_By  =   "Terraform"
  }
}

