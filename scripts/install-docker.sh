#!/bin/bash


sudo yum update -y

# Install Docker
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y containerd.io-1.2.13 docker-ce-19.03.11 docker-ce-cli-19.03.11
sudo usermod -a -G docker ec2-user

sudo mkdir /etc/docker


# replace the following with ansible playbook
#Docker 
sudo yum install docker -y
sudo usermod -a -G docker ec2-user
sudo mkdir /etc/docker
sudo bash -c 'cat << EOF > /etc/docker/daemon.json 
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF'

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker

