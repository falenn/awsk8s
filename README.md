# K8s on AWS

## About
This project uses Terraform to spin up infrastructure on AWS.  This terraform instance is a wrapper around Docker execution of hashicorp/terraform:<ver>!  There is no Terraform or Python installation dependency.  

## Quickstart

To use this k8s installer, do the following:
1.  First, ensure 
1.  Setup your env file
In the directory where you have cloned this project, create a key=value file of required environment vars:
```
vi env
 - follow the steps below about env setup
```
2. Install Docker if you don't have it installed already
```
# add repo
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# install
sudo yum install -y containerd.io-1.2.13 docker-ce-19.03.11 docker-ce-cli-19.03.11

# enable docker service
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker
```
2. Add yourself to the Docker group
```
sudo usermod -a -G docker $USER
```
2. Init your terraform project
```
./terraform init
```
Plan the terraform deployment
```
./terraform plan --out plan.out
```
Deploy!
```
./terraform apply plan.out
```

Do some work...

Destroy!
```
./terraform destroy
```

## Terraform Approach
Following: https://blog.smartlogic.io/how-i-organize-terraform-modules-off-the-beaten-path/
Terraform is structured a little differently for better readability.  

In summary:
1. Each file is treated as its own module.  Each file contains:
1.1 Goal Resources
1.2 Dependencies
1.2.1 Any required variables
1.2.2 Any locals
1.3 Required providers
1.4 Any output

Principle: Scope of the file contains the things that make sense to delete at once - an atomic unit.

2. Order these files lexographically such that 
```
ls | xargs cat
```
returns the files in the desired order of execution.  This is much like how CNI modules are loaded in K8s.
Although not desirable, here is a pragmatic practice:
* _init.tf - contains provider declarations, locals, widely used data source, and any top-level resources.
0-vpc.tf - stage 0 - setting up the VPC
1-rds_subnets.tf - stage 1 - subnet for the database
2-rds_security-groups.tf - stage 2 - sec group for the database
1-k8s_subnets.tf - stage 1 - subnet for k8s ec2 nodes
2-k8s_security-groups.tf - stage 2  - sec groups for k8s
...

Notice, duplicative numberis is possible for mutually-exclusive componetry!  

Principle: Easy mechanism to replace order of causality.

# Variables
## Constants
__constants.tf - variable locals block that is replayed as though we never expect it to be overriden
## Global references
_inputs_subnets.tf
_inputs_dnsname.tf
## Global Outputs
_output_foo.tf
## Local Variables

## Environment Vars
Variables can be asserted on the command line:
```
terraform apply -var-file="key=value"
```
which is how terraform workspace passes variables in.

Env vars can also be passed in with this prefix: "TF_VAR_"
which is useful when wrapping terraform apply, etc. with bash automation.
```
$ export TF_VAR_image_id=ami-abc123'
```

Variables that are currently expected:
```
$ vi env 
TF_VAR_aws_username=$USER
TF_VAR_aws_resource_prefix=
TF_VAR_aws_project=
# TF_VAR_aws_region="us-east-1" is default
# TF_VAR_aws_vpc_id="" is presupposed when VPC is already existing
TF_VAR_aws_security_group_id=
TF_VAR_aws_subnet_id=
TF_VAR_aws_iam_instance_profile=
TF_VAR_aws_ssh_key_name= SSH key managed in AWS
# name of AMI image to use for ec2 instance
TF_VAR_aws_ami_name=
# Default is 1
TF_VAR_aws_ec2_k8s_master_count=1
# Default is 0
TF_VAR_aws_ec2_k8s_worker_count=1
# dockerhub username
TF_VAR_docker_username=
TF_VAR_docker_password=
# docker mirrored-proxies
TF_VAR_docker_proxy=
# private registry
TF_VAR_docker_registry=
# username/pwd as encoded when viewed in ~/.docker/config.json after login
TF_VAR_docker_encoded_auth="ddd" 
TF_VAR_ssh_deploy_key=  ->>>>   cat ~/.ssh/id_rsa.pub | base64

```



# Symlinks
__ - double-underscore is a convenient prefix to denote a symlinked file - Terraform has no prob following this

# Consequences
## Where do I start reading?
At the beginning!  List the dir- treat it as a table of contents.
## Where do I add something?
Where it makes logical sense.  Follow the (n+1)-bar.tf strategy
## If I remove something, what might I break?
Anything greater than n - the file you remove - will most-likely break.
## Where should I check to see if a variable is used?
Each file declares and uses variables, so in the given file.
## Where does a dependent resource come from?
(n-1)-bar.tf

# Options for AWS vars
store in ~/.aws/config

# example profile
[profile dev-full-access]
role_arn = arn:aws:iam::12345678:role/dev-full-access
needs policies such as:
action: Allow, IAM:PassRole


# terraform.tfvars
will load this file if present.  Can .gitignore for safety

