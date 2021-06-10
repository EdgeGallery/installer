# based onDockerget onEdgeGallerydeploy

This deployment method is based ondockerversusdocker-compose，not depend onk8s，helmWait。The following dependencies need to be installed in advance before deployment：

| Dependency         | version    | Remarks        |
|----------------|---------|-------------|
| Docker         | 18.09.0 |             |
| Docker Compose | 1.26.0  |             |
| Curl           | 7.58.0  | sendAPIrequest |


## deployEdgeGallery

You can download the compressed package of the image first，Load onto the machine，Can be performed in an offline environmentEdgeGalleryinstallation。

The image compression package is divided into[edgeAll images deployed on the edge](https://edgegallery.obs.cn-east-3.myhuaweicloud.com/docker-compose-images/edge-images.tar.gz)with[controllerAll images deployed on the center side](https://edgegallery.obs.cn-east-3.myhuaweicloud.com/docker-compose-images/controller-images.tar.gz)。

Execute the following command to load the image，And install and deployedgewithcontroller。

 **Note：Need to deploy firstcontroller，Redeployedge。Because of deploymentcontrollerNeed to configuredocker/daemon.json，Will restartdocker service。** 


```
docker load -i controller-images.tar.gz
bash controller_install.sh <IP-of-this-machine>

docker load -i edge-images.tar.gz
bash edge_install.sh <IP-of-this-machine>
```

In the above formula`<IP-of-this-machine>`Can be private for this machineIP，thenEdgeGalleryThis private can only be used on the machine after deploymentIPMake a visit。
If you need to access it on other machines，Can be`<IP-of-this-machine>`Set the public network of this machineIP。


## UninstallEdgeGallery

```
bash edge_uninstall.sh
bash controller_uninstall.sh
```
