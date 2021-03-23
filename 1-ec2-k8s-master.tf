
  # SSH key
  data "local_file" "rsa_pub" {
    filename = file("./id_rsa.pub")
  }

  # User-data
  data "template_file" "user_data" {
    filename = file("./scripts/install-prereqs.txt")
  }

  #create key-pair for SSH access into EC2 instance 
  resource "aws_key_pair" "k8s_ssh" {
    provider = aws.east
    key_name = "ehpc-clbates"
    pulic_key = local_file.rsa_pub
  }

  # Create and bootstrap EC2 in default region
  resource "aws_instance" "k8s-master" {
    provider 			= aws.east
    ami 			= var.TF_VAR_AMI
    instance_type 		= var.k8s-master-instance-type
    key_name			= aws_key_pair.k8s_ssh.key_name
    associate_public_ip_address   = true
    vpc_security_group_ids	= [var.SECURITY_GROUP]
    subnet_id			= var.SUBNET_ID
    user_data			= data.template_file.user_data.rendered

    tags = {
      Name = "k8s-master",
      project = TF_VAR_PROJECT,
      type = "k8s"
    }
  }
