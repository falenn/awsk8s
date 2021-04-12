variable "docker_registry" {
  default="https://hub.docker.com/"
}

variable "docker_username" {}
variable "docker_password" {}
variable "docker_data_directory" {
  default = "/data/docker"
}

variable "docker_daemon_json_tpl" {
  default = "./templates/docker/daemon.json.tpl"
}

#render the daemon.json
data "template_file" "docker_daemon_json" {
  template = file(var.docker_daemon_json_tpl)
  vars = {
    docker_registry = var.docker_registry
    docker_data_directory = var.docker_data_directory
  }
}

resource "null_resource" "k8s-master" {
  
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
  provisioner "file" {
    content = data.template_file.docker_daemon_json.rendered
    destination = "/tmp/daemon.json"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-docker.sh",
      "sudo cp /tmp/daemon.json /etc/docker/daemon.json",
      "/tmp/install-docker.sh",
      "sudo docker login ${var.docker_registry} --username ${var.docker_username} --password ${var.docker_password}"
    ]
  }
}

resource "null_resource" "k8s-worker" {

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
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-docker.sh",
      "/tmp/install-docker.sh",
      "sudo docker login ${var.docker_registry} --username ${var.docker_username} --password ${var.docker_password}"
    ]
  }
}

