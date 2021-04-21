
  variable "aws_ec2_boot_vol_size" {
    default=20
  }

  variable "aws_ebs_k8s_vol_size" {
    default=100
  }

  variable "aws_ebs_k8s_vol_type" {
    default="gp2"
  }

  variable "aws_ebs_device" {
    default="nvme1n1"
  }
  variable "aws_ebs_device_partition" {
    default="nvme1n1p1"
  }

  variable "aws_ec2_cloud_init_tpl" {
    default="./templates/install-prereqs.tpl"
  }

  # locally defined or composite variables
  locals {
    k8s-worker-hostname = "${var.aws_resource_prefix}_k8s-worker"
    k8s-master-hostname = "${var.aws_resource_prefix}_k8s-master"
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

