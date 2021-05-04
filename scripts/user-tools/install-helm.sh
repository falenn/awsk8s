#!/bin/bash

mkdir ~/tmp
curl -fsSL -o ~/tmp/helm.tar.gz https://get.helm.sh/helm-v3.4.1-linux-amd64.tar.gz

tar -xzf ~/tmp/helm.tar.gz

mv ./linux-amd64/helm ~/bin
chmod u+x ~/bin/helm

~/bin/helm version

~/bin/helm repo add stable https://charts.helm.sh/stable

~/bin/helm repo update


