# setup Rook Ceph -

kubectl create namespace rook-ceph
helm install --namespace rook-ceph rook-ceph rook-release/rook-ceph
helm ls --namespace rook-ceph

## after operator in ready state....
kubectl create -f cluster.yaml

# Troubleshooting
If OSDs are not starting,

Check network CNI
Check that each node has a raw device - one OSD per resonably-sized device (ESB) - 200GB, for instance.

kubectl get configmap -n rook-ceph 

Delete any of the OSD token configmaps.

Delete the ceph operator pod (another will restart).
Operator will go through device discovery again.
