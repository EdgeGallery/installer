# KubeEdge
 This one_click_deploy.sh is for deploying the KubeEdge server and node. The required prerequisite like installing docker as well as k8s server, for that we have to refer [here](../../README.md) for prerequisite. One thing should be noted before running the command that we need to add only the controller part inside the nodelist.ini there. Now run the following command:
```
cd ../..
bash one_click_deploy.sh -i infra
```

**OneClickDeployment CLI host:**

The following OS is required:
 - Ubuntu

The hostname of the edge side as well as the controller side should be different. Otherwise, the edge node may not join the controller node

### Install sshpass on CLI host
**ubuntu:**
`apt-get install sshpass`

### Update nodelist.ini
Update `platform-mgmt/kubeEdge/pfm-kedge/nodelist.ini` with Edge & Controller Node details. It should be added in the following order i.e controller node should become first followed by the edge node.
KubeEdgeAdversiteIP is the ip address exposed by the cloud side and KubeEdgeJoinIP is the ip address to join with from edge.

**Syntax:**
```
<controller>|<username>|<IP>|<KubeEdgeAdversiteIP>
<edge>|<username>|<IP>|<KubeEdgeJoinIP>
```


## Deploy KubeEdge using CLI
Use the following command:
```
$ cd kubeEdge/pfm-kedge
$ bash one_click_deploy.sh -i all
```

## Remove KubeEdge using CLI
Use the following command:
```
$ kubeEdge/pfm-kedge/
$ bash one_click_deploy.sh -r all
```

### Limitations
Make sure Controller exosed IP and Edge Join IP are of same network.