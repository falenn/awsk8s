resource "null_resource" "k8s-master-docker" {
  count = var.aws_ec2_k8s_master_count
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
      "chmod +x /tmp/install-docker.sh",
      "/tmp/install-docker.sh"
    ]
  }
}
