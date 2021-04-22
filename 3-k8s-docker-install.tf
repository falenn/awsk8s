variable "docker_proxy" {
  default="https://hub.docker.com"
}

variable "docker_registry" {
  default="https://hub.docker.com"
}

variable "docker_username" {}
variable "docker_password" {}
variable "docker_data_directory" {
  default = "/var/lib/docker"
}

variable "docker_daemon_json_tpl" {
  default = "./templates/docker/daemon.json.tpl"
}

#render the daemon.json
data "template_file" "docker_daemon_json" {
  template = file(var.docker_daemon_json_tpl)
  vars = {
    docker_registry = var.docker_proxy
    docker_data_directory = var.docker_data_directory
  }
}

resource "null_resource" "docker-prep-master" {
  count = var.aws_ec2_k8s_master_count
  triggers = {
    cluster_instance_ids = join(",", aws_instance.k8s-master.*.id)
  }
  connection {
    type    = "ssh"
    user    = "ec2-user"
    host    = aws_instance.k8s-master.*.private_ip[count.index]
    private_key = file("/root/.ssh/id_rsa")
  }
  provisioner "file" {
    source = "scripts/install-docker.sh"
    destination = "/tmp/install-docker.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p ${var.docker_data_directory}"
    ]
  }
  provisioner "file" {
    content = data.template_file.docker_daemon_json.rendered
    destination = "/tmp/daemon.json"
  }
  depends_on = [
    aws_instance.k8s-master,
    aws_volume_attachment.ebs_att_k8s-master
  ]
}

resource "null_resource" "docker-install-master" {
  count = var.aws_ec2_k8s_master_count
  triggers = {
    cluster_instance_ids = join(",", aws_instance.k8s-master.*.id)
  }
  connection {
    type    = "ssh"
    user    = "ec2-user"
    host    = aws_instance.k8s-master.*.private_ip[count.index]
    private_key = file("/root/.ssh/id_rsa")
  }
  provisioner "remote-exec" {
    inline = [
      "chmod u+x /tmp/install-docker.sh",
      "sudo mkdir -p /etc/docker",
      "sudo cp /tmp/daemon.json /etc/docker/daemon.json",
      "sudo chown root:root /etc/docker/daemon.json",
      "/tmp/install-docker.sh",
      "sudo docker login ${var.docker_registry} --username ${var.docker_username} --password ${var.docker_password}"
    ]
  }
  depends_on = [
    null_resource.docker-prep-master
  ]
}

resource "null_resource" "docker-prep-worker" {
  count = var.aws_ec2_k8s_worker_count
  triggers = {
    cluster_instance_ids = join(",", aws_instance.k8s-worker.*.id)
  }
  connection {
    type    = "ssh"
    user    = "ec2-user"
    host    = aws_instance.k8s-worker.*.private_ip[count.index]
    private_key = file("/root/.ssh/id_rsa")
  }
  provisioner "file" {
    source = "scripts/install-docker.sh"
    destination = "/tmp/install-docker.sh"
  }
  provisioner "file" {
    content = data.template_file.docker_daemon_json.rendered
    destination = "/tmp/daemon.json"
  }
  depends_on = [
    aws_instance.k8s-worker,
    aws_volume_attachment.ebs_att_k8s-worker
  ]
}

resource "null_resource" "docker-install-worker" {
  count = var.aws_ec2_k8s_worker_count
  triggers = {
    cluster_instance_ids = join(",", aws_instance.k8s-worker.*.id)
  }
  connection {
    type    = "ssh"
    user    = "ec2-user"
    host    = aws_instance.k8s-worker.*.private_ip[count.index]
    private_key = file("/root/.ssh/id_rsa")
  }
  provisioner "remote-exec" {
    inline = [
      "chmod u+x /tmp/install-docker.sh",
      "sudo mkdir -p /etc/docker",
      "sudo cp /tmp/daemon.json /etc/docker/daemon.json",
      "sudo chown root:root /etc/docker/daemon.json",
      "/tmp/install-docker.sh",
      "sudo docker login ${var.docker_registry} --username ${var.docker_username} --password ${var.docker_password}"
    ]
  }
  depends_on = [
    null_resource.docker-prep-worker
  ]
}

