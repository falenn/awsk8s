#!/bin/bash

# exit when any command fails
set -e

S3_IMAGE_URI=$1
S3_IMAGE_FILENAME=$2


# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

# kubernetes network config
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

# Setup k8s repo
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# prep host with docker image import for S3
echo "Checking for cache available at s3"
if [ -z $S3_IMAGE_URI ]; then
  echo "S3 image cache bucket: $S3_IMAGE_URI"
  if [ "$S3_IMAGE_URI" -ne "NONE" ]; then
    # copy files from S3 cache
    mkdir -p /tmp/docker
    /usr/bin/aws s3 cp $S3_IMAGE_URI/ /tmp/docker --recursive
    
    # load into docker
    sudo docker load -i /tmp/docker/${S3_IMAGE_FILENAME}.tar
    
    # retag imported images
    while read REPOSITORY TAG IMAGE_ID
    do
        echo "== Tagging $REPOSITORY $TAG $IMAGE_ID =="
        sudo docker tag "$IMAGE_ID" "$REPOSITORY:$TAG"
    done < ${S3_IMAGE_FILENAME}.list

  fi
fi
# dir prep
sudo mkdir -p /etc/cni/net.d

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

sudo systemctl enable --now kubelet
#sudo kubeadm config images pull

# deal with some bugs
#sudo mkdir -p /usr/libexec/kubernetes/kubelet-plugins/volume/exec/nodeagent~uds

# Calicoctl
#curl -O -L  https://github.com/projectcalico/calicoctl/releases/download/v3.18.1/calicoctl
#sudo mv calicoctl /usr/local/sbin/calicoctl

# set the env for calicoctl
#DATASTORE_TYPE=kubernetes KUBECONFIG=~/.kube/config 

# get nodes
#calicoctl get nodes


