variable "aws_ec2_k8s_master_instance_type" {
   default="t3.medium"
}

variable "aws_ec2_k8s_master_count" {
  default=1
}

variable "aws_ec2_k8s_master_ebs_name" {
    default="xvdf"
}
locals {
  aws_ec2_k8s_master_ebs_device = "/dev/${var.aws_ec2_k8s_master_ebs_name}"
  aws_ec2_k8s_master_ebs_partition = "${var.aws_ec2_k8s_master_ebs_name}1"
}
 
 
# Remote Provision Key
# Public Key must be base64 encoded
#resource "aws_key_pair" "remote-provision-key" {
#  provider = aws
#  key_name = local.deploy_key
#  public_key = base64decode(var.ssh_deploy_key)
#}

# Create and bootstrap EC2 in default region
# sets SSH key from AWS (key_name)  
# Check the ami-instance type for what user to use to log in.  The default centos7 uses the "centos" user
resource "aws_instance" "k8s-master" {
  provider 			= aws
  ami 			= var.aws_ami_id
  instance_type 		= var.aws_ec2_k8s_master_instance_type
  key_name			= var.aws_ssh_key_name
  associate_public_ip_address = false
  vpc_security_group_ids	= [aws_security_group.allow_ssh.id, 
				   aws_security_group.allow_all_egress.id,
				   aws_security_group.allow_all_subnet.id,
				   aws_security_group.allow_k8s_api.id]
  iam_instance_profile	= var.aws_iam_instance_profile
  subnet_id			= var.aws_subnet_id
  user_data			= data.template_file.user_data.rendered
  source_dest_check		= false
  count			= var.aws_ec2_k8s_master_count
  root_block_device {
    volume_type = var.aws_ebs_k8s_vol_type
    volume_size = var.aws_ec2_boot_vol_size
    delete_on_termination = "true"
  }
  tags = {
    User = var.aws_username,
    Name = join("_", [local.k8s-master-hostname, count.index + 1]),
    Project = var.aws_project,
    Type = "k8s",
    Subtype = "master",
    Managed_By  =   "Terraform"
  }
}
  
resource "aws_ebs_volume" "ebs_k8s-master_data" {
  count             = var.aws_ec2_k8s_master_count
  availability_zone = element(aws_instance.k8s-master.*.availability_zone, count.index)
  type              = var.aws_ebs_k8s_vol_type
  size              = var.aws_ebs_k8s_vol_size
  tags = {
    User = var.aws_username,
    Name = join("_", [local.k8s-master-hostname, count.index + 1]),
    Project = var.aws_project,
    Type = "k8s",
    Subtype = "master",
    Managed_By  =   "Terraform"
  }
}
  
# Storage for k8s-masters
resource "aws_volume_attachment" "ebs_att_k8s-master" {
  count 	= var.aws_ec2_k8s_master_count
  device_name = local.aws_ec2_k8s_master_ebs_device
  volume_id   = aws_ebs_volume.ebs_k8s-master_data.*.id[count.index]
  instance_id = aws_instance.k8s-master.*.id[count.index]
  connection {
    type    = "ssh"
    user    = "ec2-user"
    host    = aws_instance.k8s-master.*.private_ip[count.index]
    private_key = file("/root/.ssh/id_rsa")
  }   
  #provisioner "file" {
  #  source      = "scripts/setupStorageLVM.sh"
  #  destination = "/tmp/setupStorageLVM.sh"
  #}
  #provisioner "remote-exec" {
  #  inline = [
  #    "chmod +x /tmp/setupStorageLVM.sh",
  #    "/tmp/setupStorageLVM.sh ${var.aws_ec2_k8s_master_ebs_name} ${local.aws_ec2_k8s_master_ebs_partition}"
  #  ]
  #}
  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y lvm2"
    ]
  }
}
  

# outputs
output "k8s-master-private-ips" {
  value = {
    for instance in aws_instance.k8s-master : 
      instance.id => instance.private_ip
  }
}  
