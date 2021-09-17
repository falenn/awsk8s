locals {
  allow_all_subnet = "${var.aws_resource_prefix}_allow_all_in_subnet"
}

resource "aws_security_group" "allow_all_subnet" {
  name 		= local.allow_all_subnet
  description 	= "Allow all in the subnet"
  vpc_id 	= var.aws_vpc_id
  
  ingress {
    description     = "Allow from all nodes in private subnet"
    from_port	    = 0
    to_port	    = 0
    protocol	    = "-1"
    cidr_blocks	    = [var.aws_subnet_cidr_block]
  }

  ingress {
    description	    = "Allow from all nodes in private subnet for CNI CIDR traffic in case of calico"
    from_port	    = 0
    to_port	    = 0
    protocol	    = "-1"
    cidr_blocks	    = [var.aws_k8s_pod_network_cidr]
  }

  tags = {
    Name = local.allow_all_subnet,
    Project = var.aws_project,
    User = var.aws_username,
    Managed_By  =   "Terraform"
  }
}
