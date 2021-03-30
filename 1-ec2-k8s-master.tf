  variable "k8s-master-instance-type" {
    default="t3.medium"
  }

  variable "k8s-worker-instance-type" { 
    default="t3.small"
  }

  variable "aws_ec2_k8s_master_count" {
    default=1
  }

  variable "aws_ec2_k8s_worker_count" {
    default=0
  }

 
  variable "aws_ec2_cloud_init_tpl" {
    default="./templates/install-prereqs.tpl"
  }

  # locally defined or composite variables
  locals {
    k8s-master-hostname = "${var.aws_resource_prefix}_k8s-master"
    k8s-worker-hostname = "${var.aws_resource_prefix}_k8s-worker"
    deploy_key = "${var.aws_resource_prefix}_deploy_key"
  }

  # set via docker -e 
  variable "aws_ami_id" {}
  
  # id_rsa.pub to additionally set for Ansible follow-on automation
  # @todo - could possibly just use AWS key provisioning...
  variable "ssh_deploy_key" {}

  # User-data
  data "template_file" "user_data" {
    template = file(var.aws_ec2_cloud_init_tpl)
    vars = {
      id_rsa_pub = var.ssh_deploy_key
    }
  }

  # Remote Provision Key
  # Public Key must be base64 encoded
  resource "aws_key_pair" "remote-provision-key" {
    provider = aws.east
    key_name = local.deploy_key
    public_key = base64decode(var.ssh_deploy_key)
  }

  # Create and bootstrap EC2 in default region
  # sets SSH key from AWS (key_name)  
  # Check the ami-instance type for what user to use to log in.  The default centos7 uses the "centos" user
  resource "aws_instance" "k8s-master" {
    provider 			= aws.east
    ami 			= var.aws_ami_id
    instance_type 		= var.k8s-master-instance-type
    key_name			= var.aws_ssh_key_name
    associate_public_ip_address = false
    vpc_security_group_ids	= [var.aws_security_group_id]
    iam_instance_profile	= var.aws_iam_instance_profile
    subnet_id			= var.aws_subnet_id
    user_data			= data.template_file.user_data.rendered
    count			= var.aws_ec2_k8s_master_count

    tags = {
      USER = var.aws_username,
      Name = join("_", [local.k8s-master-hostname, count.index + 1]),
      project = var.aws_project,
      type = "k8s",
      subtype = "master",
      Managed_By  =   "Terraform"
    }
  }

  # Storage for k8s-masters
  resource "aws_volume_attachment" "ebs_att_k8s-master" {
    device_name = "/dev/sdf"
    volume_id   = aws_ebs_volume.ebs_k8s-master_data.id
    instance_id = aws_instance.k8s-master.id

    tags = {
      Name = join("_", [local.k8s-master-hostname, count.index + 1]),
      project = var.aws_project,
      type = "k8s",
      subtype = "master",
      Managed_By  =   "Terraform"
    }
  }

  resource "aws_ebs_volume" "ebs_k8s-master_data" {
    availability_zone = var.aws_availability_zone
    size              = 100
  }


  # Create and bootstrap k8s workers
  resource "aws_instance" "k8s-worker" {
    provider 			= aws.east
    ami				= var.aws_ami_id
    instance_type		= var.k8s-worker-instance-type
    key_name			= var.aws_ssh_key_name
    associate_public_ip_address = false
    vpc_security_group_ids	= [var.aws_security_group_id]
    iam_instance_profile 	= var.aws_iam_instance_profile
    subnet_id			= var.aws_subnet_id
    user_data			= data.template_file.user_data.rendered
    count			= var.aws_ec2_k8s_worker_count

    tags = {
      USER = var.aws_username
      Name = join("_", [local.k8s-worker-hostname, count.index + 1]),
      project = var.aws_project,
      type = "k8s",
      subtype = "worker",
      Managed_By  =   "Terraform"
    }
    
    depends_on = [aws_instance.k8s-master]
  }

  # Storage for k8s-workers
  resource "aws_volume_attachment" "ebs_att_k8s-worker" {
    device_name = "/dev/sdf"
    volume_id   = aws_ebs_volume.ebs_k8s-worker_data.id
    instance_id = aws_instance.k8s-worker.id

    tags = {
      Name = join("_", [local.k8s-worker-hostname, count.index + 1]),
      project = var.aws_project,
      type = "k8s",
      subtype = "worker",
      Managed_By  =   "Terraform"
    }
  }

  resource "aws_ebs_volume" "ebs_k8s-worker_data" {
    availability_zone = var.aws_availability_zone
    size              = 100
  }



  # Outputs
  output "k8s-master-private-ips" {
    value = {
      for instance in aws_instance.k8s-master : 
        instance.id => instance.private_ip
    }
  }  

  output "k8s-worker-private-ips" {
    value = {
      for instance in aws_instance.k8s-worker: 
        instance.id => instance.private_ip
    }
  }

  

