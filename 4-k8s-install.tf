# install Kubernetes

# already defined in docker install tf
# variable "docker_registry" {}

# This is the encoded form of username / pwd created when written to docker key.json or .docker/config.json
variable "docker_encoded_auth" {}

variable "docker_config_json_tpl" {
  default="./templates/docker/config.json.tpl"
}

# bucket containing k8s docker images for faster boot
variable "s3_k8s_image_bucket" {
  default="NONE"
}

# file name prefix for images.tar, images.list
variable "s3_k8s_image_filename" {
  default="dockerimages"
}

variable "s3_k8s_jointoken_bucket" {
  default="NONE"
}
variable "s3_k8s_join_filename" {
  default="joincmd"
}

#render the daemon.json
data "template_file" "docker_config_json" {
  template = file(var.docker_config_json_tpl)
  vars = {
    REGISTRY = var.docker_registry
    AUTH = var.docker_encoded_auth
  }
}


resource "null_resource" "k8s-install-master" {
  
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
    source = "scripts/install-k8s.sh"
    destination = "/tmp/install-k8s.sh"
  }
  provisioner "file" {
    source = "scripts/s3LoadDockerCache.sh"
    destination = "/tmp/s3LoadDockerCache.sh"
  } 
  provisioner "file" {
    content = data.template_file.docker_config_json.rendered
    destination = "/tmp/config.json"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod u+x /tmp/s3LoadDockerCache.sh",
      "/tmp/s3LoadDockerCache.sh -b ${var.s3_k8s_image_bucket} -o ${var.s3_k8s_image_filename}",
      "chmod u+x /tmp/install-k8s.sh",
      "/tmp/install-k8s.sh",
      "sudo mkdir -p /var/lib/kubelet",
      "sudo cp /tmp/config.json /var/lib/kubelet/config.json"
    ]
  }
  depends_on = [
    null_resource.docker-install-master
  ]
}

resource "null_resource" "k8s-install-worker" {

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
    source = "scripts/install-k8s.sh"
    destination = "/tmp/install-k8s.sh"
  }
  provisioner "file" {
    source = "scripts/s3LoadDockerCache.sh"
    destination = "/tmp/s3LoadDockerCache.sh"
  }
  provisioner "file" {
    content = data.template_file.docker_config_json.rendered
    destination = "/tmp/config.json"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod u+x /tmp/s3LoadDockerCache.sh",
      "/tmp/s3LoadDockerCache.sh -b ${var.s3_k8s_image_bucket} -o ${var.s3_k8s_image_filename}",
      "chmod u+x /tmp/install-k8s.sh",
      "/tmp/install-k8s.sh",
      "sudo mkdir -p /var/lib/kubelet",
      "sudo cp /tmp/config.json /var/lib/kubelet/config.json"
    ]
  }
  depends_on = [
    null_resource.docker-install-worker
  ]
}

resource "null_resource" "k8s-setup" {
  connection {
    type    = "ssh"
    user    = "ec2-user"
    host    = aws_instance.k8s-master.*.private_ip[0]
    private_key = file("/root/.ssh/id_rsa")
  }
  provisioner "file" {
    source = "templates/calico/v3.17.1/custom-resources.yaml"
    destination = "/tmp/custom-resources.yaml"   
  }
  provisioner "file" {
    source = "templates/calico/v3.17.1/tigera-operator.yaml"
    destination = "/tmp/tigera-operator.yaml"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo /usr/bin/kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=all",
      "mkdir -p /home/ec2-user/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf /home/ec2-user/.kube/config",
      "sudo chown ec2-user:ec2-user /home/ec2-user/.kube/config",
      "/usr/bin/kubectl taint nodes --all node-role.kubernetes.io/master-",
      "/usr/bin/kubectl apply -f /tmp/tigera-operator.yaml",
      "/usr/bin/kubectl apply -f /tmp/custom-resources.yaml",
      "/usr/bin/kubeadm token create --print-join-command >> /tmp/${var.s3_k8s_join_filename}",
      "/usr/bin/aws s3 cp /tmp/${var.s3_k8s_join_filename} ${var.s3_k8s_jointoken_bucket}"
    ]
  }
  depends_on = [
    null_resource.k8s-install-master
  ]
}
