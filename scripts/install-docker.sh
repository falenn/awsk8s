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
sudo mkdir -p /data/docker

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker

