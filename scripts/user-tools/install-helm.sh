#!/bin/bash

mkdir ~/tmp
curl -fsSL -o ~/tmp/helm.tar.gz https://get.helm.sh/helm-v3.4.1-linux-amd64.tar.gz

tar -xzf ~/tmp/helm.tar.gz

mv ./linux-amd64/helm ~/bin

helm version

helm repo add stable https://charts.helm.sh/stable

helm repo update


