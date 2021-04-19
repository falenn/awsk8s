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
# variable "aws_vpc_id" {}
variable "aws_subnet_id" {}


