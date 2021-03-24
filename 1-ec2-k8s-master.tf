  variable "k8s-master-instance-type" {
    default="t3.medium"
  }

  variable "k8s-master-hostname" {
    default="k8s-master"
  }

  variable "aws_ami_name" {
    default="eVo_AMI_CentOS7*"
  }
  
  # set via docker -e 
  variable "aws_ami_id" {}

  #data "aws_ssm_parameter" "linuxAmi" {
  #  provider = aws.east
  #  name = "/aws/service/eVo_AMI_CentOS7*"
  #}


  # User-data
  data "template_file" "user_data" {
    template = file("./scripts/install-prereqs.txt")
  }


  # Create and bootstrap EC2 in default region
  resource "aws_instance" "k8s-master" {
    provider 			= aws.east
    ami 			= var.aws_ami_id
    instance_type 		= var.k8s-master-instance-type
    key_name			= var.aws_ssh_key_name
    associate_public_ip_address   = true
    vpc_security_group_ids	= [var.aws_security_group_id]
    subnet_id			= var.aws_subnet_id
    user_data			= data.template_file.user_data.rendered

    tags = {
      USER = var.aws_username,
      Name = var.k8s-master-hostname,
      project = var.aws_project,
      type = "k8s"
    }
  }
