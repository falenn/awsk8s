
resource "null_resource" "k8s-worker-join" {

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
      "/usr/bin/aws s3 cp ${var.s3_k8s_jointoken_bucket}${var.s3_k8s_join_filename} /tmp/joincmd",
      "sudo /usr/bin/bash /tmp/joincmd"
    ]
  }
  depends_on = [
    null_resource.k8s-setup
  ]
}

