#!/bin/bash


# exit when any command fails
#set -e

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
#trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

# Vars
TMP_PATH=/tmp/docker


while getopts "b:o:" arg; do
  case $arg in
    b)
      S3_BUCKET_URI=$OPTARG
      echo "S3 image cache bucket: $S3_BUCKET_URI"
      ;;
    o)
      S3_OBJECT_PREFIX=$OPTARG
      echo "S3_OBJECT_PREFIX: $S3_OBJECT_PREFIX"
      ;;
    ?)
      echo "Usage: [-o s3://bucket/uri | -p s3_obect_prefix ] Supply these options for loading docker images cached in S3 for faster cluster start. These are in the format of docker load - images.tar and images.list set of tags."
      exit 1
      ;;
  esac
done


# prep host with docker image import for S3
echo "Checking for cache available at S3: ${S3_BUCKET_URI} for images: ${S3_OBJECT_PREFIX}"
if [ -v S3_BUCKET_URI ]; then
if [ ! -z ${S3_BUCKET_URI} ]; then
  file=$TMP_PATH/${S3_OBJECT_PREFIX}.tar
  if [ ! -f "$file" ]; then
    echo "Downloading from S3..."
    # copy files from S3 cache
    mkdir -p $TMP_PATH
    /usr/bin/aws s3 cp $S3_BUCKET_URI $TMP_PATH --recursive > /dev/null
    echo "Downloading done."
    ls -la $TMP_PATH
  fi
  # load into docker
  sudo docker load -i $TMP_PATH/$S3_OBJECT_PREFIX.tar > /dev/null
  echo "$S3_OBJECT_PREFIX.tar downloaded to $TMP_PATH"
  # retag imported images

  while read REPOSITORY TAG IMAGE_ID
  do
    echo "== Tagging $REPOSITORY $TAG $IMAGE_ID =="
    sudo docker tag "$IMAGE_ID" "$REPOSITORY:$TAG"
  done < $TMP_PATH/${S3_OBJECT_PREFIX}.list
fi
fi

