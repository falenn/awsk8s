# install Kubernetes

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
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-k8s.sh",
      "/tmp/install-k8s.sh"
    ]
  }
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
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-k8s.sh",
      "/tmp/install-k8s.sh"
    ]
  }
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
      "sudo /bin/kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=all",
      "mkdir -p /home/ec2-user/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf /home/ec2-user/.kube/config",
      "sudo chown ec2-user:ec2-user /home/ec2-user/.kube/config",
      "/bin/kubectl taint nodes --all node-role.kubernetes.io/master-",
      "/bin/kubectl apply -f /tmp/tigera-operator.yaml",
      "/bin/kubectl apply -f /tmp/custom-resources.yaml"
    ]
  }
}
