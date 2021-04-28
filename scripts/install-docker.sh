#!/bin/bash

# exit when any command fails
set -e

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

# update first
sudo yum update -y

# Ensure data directory can be created
status=1
while [[ $status -ne 0 ]]; do
  sudo mkdir -p /data/docker
  status=$?
  if [[ $status -ne 0 ]]; then
    sleep 5;
  else

# Handle Amazon 2 Linux
cat /etc/os-release | grep -e "amazon_linux:2"
if [ $? -eq 0 ]; then
  sudo amazon-linux-extras install docker -y
else

  # add repo
  sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

  # install
  sudo yum install -y containerd.io-1.2.13 docker-ce-19.03.11 docker-ce-cli-19.03.11

  # enable docker service
  sudo mkdir -p /etc/systemd/system/docker.service.d
  sudo systemctl daemon-reload
fi

sudo systemctl restart docker
sudo systemctl enable docker

# update user group
sudo usermod -a -G docker ec2-user

  fi
done

