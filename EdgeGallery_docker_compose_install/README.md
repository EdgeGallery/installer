# 基于Docker进行EdgeGallery部署

此部署方式基于docker与docker-compose，不依赖k8s，helm等。部署之前需要提前安装如下依赖：

| 依赖项         | 版本    | 备注        |
|----------------|---------|-------------|
| Docker         | 18.09.0 |             |
| Docker Compose | 1.26.0  |             |
| Curl           | 7.58.0  | 发送API请求 |


## 部署EdgeGallery

可以先下载镜像的压缩包，加载到机器上，即可在离线环境进行EdgeGallery的安装。

镜像压缩包分为[edge边缘侧部署的全部镜像](https://edgegallery.obs.cn-east-3.myhuaweicloud.com/docker-compose-images/edge-images.tar.gz)和[controller中心侧部署的全部镜像](https://edgegallery.obs.cn-east-3.myhuaweicloud.com/docker-compose-images/controller-images.tar.gz)。

执行以下命令加载镜像，并安装部署edge和controller。

 **注：需要先部署controller，再部署edge。因为部署controller时需要配置docker/daemon.json，会重启docker service。** 


```
docker load -i controller-images.tar.gz
bash controller_install.sh <IP-of-this-machine>

docker load -i edge-images.tar.gz
bash edge_install.sh <IP-of-this-machine>
```

上面公式里的`<IP-of-this-machine>`可以为此机器的私有IP，则EdgeGallery部署后只能在机器上用此私有IP进行访问。
若需要在其他机器访问，可将`<IP-of-this-machine>`设置为此机器的公网IP。


## 卸载EdgeGallery

```
bash edge_uninstall.sh
bash controller_uninstall.sh
```
