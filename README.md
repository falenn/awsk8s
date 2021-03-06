# K8s on AWS

## About
This project uses Terraform to spin up infrastructure on AWS.  This terraform instance is a wrapper around Docker execution of hashicorp/terraform:<ver>!  There is no Terraform or Python installation dependency.  

## Quickstart
To use this k8s installer, do the following:
0.  AWSCLI Setup
1.  Setup your env file
2.  Install Docker on your local machine
3.  Run Terraform Commands!
4.  Kubectl

### 0. Setup AWSCLI on your host
#### Install AWSCLI if you don't have it
On Ubuntu
```
sudo apt-get install -y awscli
```

On CentOS7
```
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
```

Make sure you define ~/.aws/config with the same default region as your project.  AWS CLI may be used to interrogate AMI instances, etc. using pass-through credentials.  No need to put AWS credentials in this config:
```
[default]
region = us-east-1
output = json
```

We can also just run AWS CLI from Docker like we are doing for Terraform, but we will save that for another time.


### 1. Setting up Your env file
In the directory where you have cloned this project, create a key=value file of required environment vars named env.  
This file is ignored in the .gitignore.

Example env file:
```
TF_VAR_aws_username=$USER
TF_VAR_aws_resource_prefix=$USER
TF_VAR_aws_project=my-project

# AWS Infrastructure required information

# the PVC deploying to and the ipv4 CIDR block for the PVC
TF_VAR_aws_vpc_id=vpc-1234567890abcdef
TF_VAR_aws_vpc_main_cidr_block=10.x.x.x/25

# The private subnet to deploy the ec2 instances to - this should be the same subnet
# that the ec2 instance you are deploying the cluster with is in
TF_VAR_aws_subnet_id=subnet-1234567890abcdef
# The IPV4 CIDR block for the private subnet
TF_VAR_aws_subnet_cidr_block=10.x.x.x/26
# CIDR blocks from which to restrict access to the K8s API and nodeport services
TF_VAR_aws_k8s_api_access_cidr_block=10.x.x.x/22     <maybe restrict to within the VPC>
TF_VAR_aws_k8s_nodeport_access_cidr_block=0.0.0.0/0  <this would allow all traffic or traffic from an AWS loadbalancer>

# The conveyence of any rights to the ec2 instance (e.g., access to the AWS CLI and various elements)
TF_VAR_aws_iam_instance_profile=<from AWS, e.g., myk8s-user-profile>
# The SSH key to use from AWS-managed keys
# This is currently not used for login since we normalize the access to the ec2-user.  Not all AMIs present the same standard login user.
TF_VAR_aws_ssh_key_name=<SSH key managed in AWS>

# AMI to use for instance creation
TF_VAR_aws_ami_name=<from AWS, e.g., "MY_AMI_CentOS7*">

# Instance Settings
# Master count - default is 1
TF_VAR_aws_ec2_k8s_master_count=1
# Worker count - default is 0
TF_VAR_aws_ec2_k8s_worker_count=1
# master ec2 instance type
TF_VAR_aws_ec2_k8s_master_instance_type=t2.medium
# master EBS block attachment name
TF_VAR_aws_ec2_k8s_master_ebs_name=xvdf
# worker ec2 instance type
TF_VAR_aws_ec2_k8s_worker_instance_type=t2.medium
# worker EBS block attachment name
TF_VAR_aws_ec2_k8s_worker_ebs_name=xvdf
# Extra EBS block size for all nodes - attached storage for Ceph - in GB
TF_VAR_aws_ebs_k8s_vol_size=200

# The local SSH key to use - first must base64 encode the public key
# cat ~/.ssh/id_rsa.pub | base64
# paste that value here
TF_VAR_ssh_deploy_key=<base64 encoded public key>
```
#### SSH Keys
Just as a note - do you have an ssh public key on your ec2-host to base64 encode?  You can create a new one.
```
ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C "john@example.com"
```

Now you can use this "Twisted Edwards" key (Stronger than RSA2048 and still compatible with Gitlab, etc.) and base64 the public for inclusion above.


#### Variable Description
| Variable  | Example | Type  | AWS Reference or Description |
| :---      | :---    | :---  | :---      |
| TF_VAR_aws_username | $USER | String, no quotes | AWS Label |
| TF_VAR_aws_resource_prefix | $USER | String, no quotes | AWS Label |
| TF_VAR_aws_project | my-project | String, no quotes | AWS Label |
| TF_VAR_aws_subnet_id | subnet-1234567890abcdef | AWS subnet ID | EC2 > Network & Security > Subnets |
| TF_VAR_aws_security_group_id | sg-1234567890abcdef | AWS Security Group ID | EC2 > Network & Security > Security Groups |
| TF_VAR_aws_iam_instance_profile | myks-user-profile | AWS IAM Role | IAM > Roles |
| TF_VAR_aws_ssh_key_name | my_ssh_key | String, no quotes | EC2 > Network & Security > Kye Pairs | 
| TF_VAR_aws_ami_name | "My_AMI_CentOS7*" | String | EC2 > Images > AMIs |
| TF_VAR_aws_ec2_k8s_master_count | 1 | number | Number of nodes to create | 
| TF_VAR_aws_ec2_k8s_master_instance_type | t2.medium | String | AWS ec2 server size to launch |
| TF_VAR_aws_ec2_k8s_master_ebs_name | xvdf | String | name to give EBS storage device when present in /dev/ |
| TF_VAR_aws_ec2_k8s_worker_count | 1 | number | Number of nodes to create |
| TF_VAR_aws_ec2_k8s_worker_instance_type | t2.medium | String | AWS ec2 server size to launch |
| TF_VAR_aws_ec2_k8s_worker_ebs_name | xvdf | String | name to give EBS storage device when present in /dev/ |
| TF_VAR_aws_ebs_k8s_vol_size | 200 | Number in GB | Size of attached block storage on all nodes |
| TF_VAR_ssh_deploy_key | c3NoLXJzYSBBQUFBQjNOemFDMXlj... | String, no quotes | base64 encoded id_rsa.pub | 
| TF_VAR_docker_username | myname | String, no quotes | Dockerhub.com \ docker.io account name|
| TF_VAR_docker_passwrod | password | String, no quotes | docker.io passwd - don't like this. Can omit and provide when prompted by Terraform|
| TF_VAR_docker_proxy | https://locationtomirror.com | URL String, no quotes | See Docker daemon.json, registry-mirrors |
| TF_VAR_docker_registry | https://locationofprivatepregistry.com | URL String, no quotes | Alternate registry, private registry |
| TF_VAR_docker_encoded_auth | "1234567890abcdef=" | String with Quotes | encoded username, pwd for Docker login - take from ~/.docker/config.json after logging in.  Used to access Docker registry | 

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
Add yourself to the Docker group
```
sudo usermod -a -G docker $USER
```
3. Run Terraform Commands!
Init your terraform project
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

4. Install Kubectl
get the binary!
```
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl
```

or run the script:
```
scripts/user-tools/install-kubectl.sh
```
Now, get access to the cluster:
If you need to, copy the ~/.kube/config from the master node to your ~/.kube/config as a quick way to get into your cluster.

5. Install Helm
Run the script:
```
scripts/user-tools/install-helm.sh
```

# S3 Options
As an alternative to Baking (staging an OS / AMI with all binary dependencies before boot - see Hashicorp Packer), we can pull binaries from an S3 bucket and apply them - definitely faster than docker pulling from internet repositories with rate-limiting.

## Steps
1. Create an S3 bucket

## S3 cmds
list buckets
```
aws s3 ls
```

list bucket object
```
aws s3 ls <bucket>
```

copy object to S3 Bucket
```
aws s3 cp <source> <target>
aws s3 cp k8s-dockerimages.tar s3://project-k8s/images/k8s-dockerimages.tar
aws s3 cp k8s-dockerimages.list S3://project-k8s/images/k8s-dockerimages.list
```
Copying From S3 to Host is just opposite



Docker export images
```
docker save $(docker images -q) -o /path/to/save/mydockersimages.tar
```
Docker export tags
```
docker images | sed '1d' | awk '{print $1 " " $2 " " $3}' > mydockersimages.list
```

Docker import images
```
docker load -i ./k8s-dockerimages.tar
```

Docker import tags
```
while read REPOSITORY TAG IMAGE_ID
do
        echo "== Tagging $REPOSITORY $TAG $IMAGE_ID =="
        docker tag "$IMAGE_ID" "$REPOSITORY:$TAG"
done < mydockersimages.list
```


now, the ec2 host can pull those objects from the bucket, given that the iam_instance_profile has been granted such permissions.


# Appendix
## Terraform Approach
Following: https://blog.smartlogic.io/how-i-organize-terraform-modules-off-the-beaten-path/
Terraform is structured a little differently for better readability.  

1. Isolate files as much as possible
Principle: Scope of the file contains the things that make sense to delete at once - an atomic unit.

Each file is treated as its own module.  Each file contains:
* Goal Resources
* Dependencies
* Any required variables
* Any locals
* Required providers
* Any output



2. Order these files lexographically such that they execute in a predictable order
Principle: Easy mechanism to replace order of causality.
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

3. Consequences of the Approach - if done correctly
**Where do I start reading?**
At the beginning!  List the dir- treat it as a table of contents.
**Where do I add something?**
Where it makes logical sense.  Follow the (n+1)-bar.tf strategy
**If I remove something, what might I break?**
Anything greater than n - the file you remove - will most-likely break.
**Where should I check to see if a variable is used?**
Each file declares and uses variables, so in the given file.
**Where does a dependent resource come from?**
(n-1)-bar.tf


## Variables
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

## Symlinks
__ - double-underscore is a convenient prefix to denote a symlinked file - Terraform has no prob following this
