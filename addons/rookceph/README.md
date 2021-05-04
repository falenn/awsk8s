# Install Helm
https://helm.sh/docs/intro/install/
'''
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
$ chmod 700 get_helm.sh
$ ./get_helm.sh
'''

# install helm rook repo
```
helm repo add rook-release https://charts.rook.io/release
kubectl create namespace rook-ceph
helm install --namespace rook-ceph rook-ceph rook-release/rook-ceph
```

# setup Rook Ceph -
```
kubectl create namespace rook-ceph
helm install --namespace rook-ceph rook-ceph rook-release/rook-ceph
helm ls --namespace rook-ceph
```
## after operator in ready state....
```
kubectl create -f cluster.yaml
```

# Troubleshooting
If OSDs are not starting,

Check network CNI
Check that each node has a raw device - one OSD per resonably-sized device (ESB) - 200GB, for instance.
```
kubectl get configmap -n rook-ceph 
```
Delete any of the OSD token configmaps.

Delete the ceph operator pod (another will restart as it is governed by a deployment).
Operator will go through device discovery again.
