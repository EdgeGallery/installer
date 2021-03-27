# 基于Docker进行EdgeGallery部署

此部署方式基于docker与docker-compose，不依赖k8s，helm等。部署之前需要提前安装如下依赖：

| 依赖项            | 版本      | 备注                    |
|----------------|---------|-----------------------|
| Docker         | 18.09.0 |                       |
| Docker Compose | 1.26.0  |                       |
| Curl           | 7.58.0  | 用于检测UserMgmt服务是否ready |


## 部署EdgeGallery


```
bash install.sh <IP-of-this-machine>
```

上面公式里的`<IP-of-this-machine>`可以为此机器的私有IP，则EdgeGallery部署后只能在机器上用此私有IP进行访问。
若需要在其他机器访问，可将`<IP-of-this-machine>`设置为此机器的公网IP。


## 卸载EdgeGallery

```
bash uninstall.sh 
```