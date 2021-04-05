#!/usr/bin/bash
#
# This is a wrapper for terraform, injecting vars we'd rather keep private and not checked into GIT, and
# by running terraform in a docker container, we ease the install.
#

TERRAFORM_VER=0.14.9
VARS_FILE=env
AMI_NAME="/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"

if [ -e $VARS_FILE ]; then
  echo "Sourcing envrionment vars file: $VARS_FILE"
  . ./$VARS_FILE
else
  echo "No file $VARS_FILE found"
fi

# helper
function docker() {
  sudo docker $@
}


# Because of the fixed nature of the env, the params are set for the amis we see.
# @TODO Externalize in the future
function listLatestAMI() {
  AMI=$1

  if [ -z "${AMI}" ]; then
    # set from ~/.aws/vars if exists
    AMI=${AMI_NAME}
  fi

  CMD="aws ssm get-parameters \
       --names $AMI  
       --region us-east-1"
  
  # echo "AMI Set: ${AMI}"

  #CMD="aws ec2 describe-images \
  #  --filters Name=architecture,Values='x86_64' \
  #  --filters Name='name',Values='${AMI}'"

  ImageJSON="`$CMD`"
  #echo "$Latest AMI: $ImageJSON"

  imageId=`echo $ImageJSON | jq '.Parameters[].Value'`
  #echo "imageId: $imageId"

  # Remove quotes
  temp="${imageId%\"}"
  temp="${temp#\"}"
  echo "$temp"
}

function terraform() {
  echo "PWD: $(pwd)"
  docker run --rm -it \
    -v $(pwd):/terraform \
    -v ~/.aws:/root/.aws \
    -v ~/.ssh:/root/.ssh \
    --env-file $VARS_FILE \
    -e TF_VAR_aws_ami_id=$AMI_ID \
    -w /terraform \
    -v /.terraform.d/plugins/lunix_amd64/:/plugins/ \
    --log-driver=journald \
    hashicorp/terraform:${TERRAFORM_VER} $@

# --entrypoint="/bin/sh"
# --network=host
# -v /etc/pki/tls/certs/cacert.crt:/etc/pki/tls/certs/cacert.crt \ 
}

# Get the current AMI
AMI_ID=`listLatestAMI $TF_VAR_aws_ami_name`
echo "AMI ID [$TF_VAR_aws_ami_name]: $AMI_ID"

# printenv
# echo call terraform
terraform $@

