#!/bin/bash

#cloud-config
#cloud_final_modules:
#- [users-groups,always]
#users:
#  - name: username
#    groups: [ wheel ]
#    sudo: [ "ALL=(ALL) NOPASSWD:ALL" ]
#    shell: /bin/bash
#    ssh-authorized-keys: 
#    - ssh-rsa AB3nzExample
#
#packages:
# - httpd
# 
#runcmd:
# - [bash, -c, "cmd"]
# - systemclt start svc
 
ID_RSA_PUB=${id_rsa_pub}


# Setup ec2-user ########################
# Setup ec2-user
useradd ec2-user

# instead of adding to wheel, which has PASSWD restriction, just add directly
echo 'ec2-user ALL=(ALL:ALL) NOPASSWD:ALL' | sudo EDITOR='tee -a' visudo

usermod -a -G wheel ec2-user
mkdir -p /home/ec2-user/.ssh
touch /home/ec2-user/.ssh/authorized_keys
# ID RSA from Terraform
echo $ID_RSA_PUB | /bin/base64 --decode  >> /home/ec2-user/.ssh/authorized_keys
chown -R ec2-user: /home/ec2-user/.ssh
chmod 700 /home/ec2-user/.ssh
chmod 600 /home/ec2-user/.ssh/authorized_keys

