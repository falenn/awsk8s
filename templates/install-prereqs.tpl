#!/bin/bash

ID_RSA_PUB=${id_rsa_pub}


# Setup ec2-user ########################
# Setup ec2-user
useradd ec2-user
usermod -a -G wheel ec2-user

mkdir -p /home/ec2-user/.ssh
touch /home/ec2-user/.ssh/authorized_keys
# ID RSA from Terraform
echo $ID_RSA_PUB | /bin/base64 --decode  >> /home/ec2-user/.ssh/authorized_keys
chown -R ec2-user: /home/ec2-user/.ssh
chmod 700 /home/ec2-user/.ssh
chmod 600 /home/ec2-user/.ssh/authorized_keys

# Allow members of the wheel group sudo w/o password - modifying /etc/soduers
#
sed -i 's/%wheel[\s\t]+ALL\=\(ALL\)[\s\t]+ALL/# %wheel ALL=\(ALL\) ALL/' /etc/sudoers
sed -i 's/#\s%wheel[\s\t]+ALL\=\(ALL\)[\s\t]+NOPASSWD\:\sALL/%wheel ALL=\(ALL\) NOPASSWD: ALL/' /etc/sudoers


#### - everything proceding could be done via Ansible -- ####

# Update the OS
yum update -y

# Install System Prereqs
yum install -y yum-utils

# Install Python
yum install -y python3 
yum install -y pip3

# Install Ansible
yum install -y ansible 
pip install boto3 --user


# Install Docker
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y containerd.io-1.2.13 docker-ce-19.03.11 docker-ce-cli-19.03.11
usermod -a -G docker ec2-user

mkdir /etc/docker
cat <<EOF | tee /etc/docker/daemon.json 
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
EOF

mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker
systemctl enable docker

# Install kubernetes
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

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

# Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl enable --now kubelet

kubeadm init --pod-network-cidr=192.168.0.0/16

# copy config to ec2-user
mkdir -p /home/ec2-user/.kube
cp -i /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
chown -R ec2-user: /home/ec2-user/.kube

# Make master schedulable
kubectl taint nodes --all node-role.kubernetes.io/master-

# install CNI
#kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
#kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml

# install weave CNI
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

