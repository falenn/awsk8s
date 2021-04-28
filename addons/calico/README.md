#

curl https://docs.projectcalico.org/manifests/calico-typha.yaml -o calico.yaml


# policy demo
kubectl create ns policy-demo

# create a pod
kubectl create deployment --namespace=policy-demo nginx --image=nginx

# expose the service
kubectl expose --namespace=policy-demo deployment nginx --port=80

# test exposure
kubectl run --namespace=policy-demo access --rm -ti --image busybox /bin/sh
# try wget from here
wget -q nginx -O -
