variable "aws_ec2_k8s_worker_instance_type" {
    default="t3.small"
  }

  variable "aws_ec2_k8s_worker_count" {
    default=0
  }


# Create and bootstrap k8s workers
  resource "aws_instance" "k8s-worker" {
    provider                    = aws
    ami                         = var.aws_ami_id
    instance_type               = var.aws_ec2_k8s_master_instance_type
    key_name                    = var.aws_ssh_key_name
    associate_public_ip_address = false
    vpc_security_group_ids      = [aws_security_group.allow_ssh.id,
                                   aws_security_group.allow_all_egress.id,
    				   aws_security_group.allow_local_subnet.id]
    iam_instance_profile        = var.aws_iam_instance_profile
    subnet_id                   = var.aws_subnet_id
    user_data                   = data.template_file.user_data.rendered
    source_dest_check		= false
    count                       = var.aws_ec2_k8s_worker_count
    root_block_device {
      volume_type = var.aws_ebs_k8s_vol_type
      volume_size = var.aws_ec2_boot_vol_size
      delete_on_termination = "true"
    }
    tags = {
      User = var.aws_username
      Name = join("_", [local.k8s-worker-hostname, count.index + 1]),
      Project = var.aws_project,
      Type = "k8s",
      Subtype = "worker",
      Managed_By  =   "Terraform"
    }
  }

  resource "aws_ebs_volume" "ebs_k8s-worker_data" {
    count             = var.aws_ec2_k8s_worker_count
    availability_zone = element(aws_instance.k8s-worker.*.availability_zone, count.index)
    type              = var.aws_ebs_k8s_vol_type
    size              = var.aws_ebs_k8s_vol_size
    tags = {
      User = var.aws_username,
      Name = join("_", [local.k8s-worker-hostname, count.index + 1]),
      Project = var.aws_project,
      Type = "k8s",
      Subtype = "worker",
      Managed_By  =   "Terraform"
    }
  }

  # Storage for k8s-workers
  resource "aws_volume_attachment" "ebs_att_k8s-worker" {
    count       = var.aws_ec2_k8s_worker_count
    device_name = "/dev/sdf"
    volume_id   = aws_ebs_volume.ebs_k8s-worker_data.*.id[count.index]
    instance_id = aws_instance.k8s-worker.*.id[count.index]
    connection {
      type    = "ssh"
      user    = "ec2-user"
      host    = aws_instance.k8s-worker.*.private_ip[count.index]
      private_key = file("/root/.ssh/id_rsa")
    }
    #provisioner "file" {
    #  source      = "scripts/setupStorageLVM.sh"
    #  destination = "/tmp/setupStorageLVM.sh"
    #}
    #provisioner "remote-exec" {
    #  inline = [
    #    "chmod +x /tmp/setupStorageLVM.sh",
    #    "/tmp/setupStorageLVM.sh ${var.aws_ebs_device} ${var.aws_ebs_device_partition}"
    #  ]
    #}
    provisioner "remote-exec" {
      inline = [
        "sudo yum install -y lvm2"
      ]
    }
  }


  # outputs
  output "k8s-worker-private-ips" {
    value = {
      for instance in aws_instance.k8s-worker:
        instance.id => instance.private_ip
    }
  }
