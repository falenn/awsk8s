variable "aws_username" {}
variable "aws_resource_prefix" {}

variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "aws_availability_zone" {
  type = string
  default = "us-east-1a"
}

variable "profile" {
  type = string
  default = "awsk8s"
}

# global AWS variables
variable "aws_project" {}
# variable "aws_iam_role" {}
variable "aws_iam_instance_profile" {}
variable "aws_ssh_key_name" {}
variable "aws_vpc_id" {}
variable "aws_vpc_main_cidr_block" {}
variable "aws_subnet_id" {}
variable "aws_subnet_cidr_block" {}
variable "aws_k8s_api_access_cidr_block" {}
variable "aws_k8s_nodeport_access_cidr_block" {}

