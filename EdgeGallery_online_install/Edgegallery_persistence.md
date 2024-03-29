### **Edgegallery nfs持久化安装指导**

前期准备：
1.安装kunernetes 1.18.7
2.安装helm 3.2.4
#### **1.安装nfs服务端**

apt update

apt install nfs-kernel-server

mkdir -p /nfs/data/

chmod -R 755 /nfs/data/

vim /etc/exports

/nfs/data/ 192.168.100.0/24(rw,no\_root\_squash,sync)
\#设置挂载本机数据的机器ip或网段

systemctl restart nfs-kernel-server

exportfs -v

#### 2.  **安装nfs客户端**

下载离线安装包解包

cd ./helm/helm-charts/stable/

helm install nfs-client-provisioner --set
nfs.server=&lt;nfs\_sever\_ip&gt; --set nfs.path=/nfs/data/
nfs-client-provisioner-1.2.8.tgz \# &lt;nfs\_sever\_ip&gt;为本机的ip

#####  **if k8s version is greater than 1.20.0 , install nfs client using below steps**
```
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=<sever_ip> --set nfs.path=/nfs/data/
```

#### 3.  **开启持久化**
在线安装将Edgegallery-values.yaml 中设置persistence 状态为true  \
Edgegallery-values.yaml 网址：https://gitee.com/edgegallery/installer/blob/master/EdgeGallery_online_install/edgegallery-values.yaml
  
#### 4. **ARM架构安装镜像**

ARM架构机器做持久化 nfs-client-provisioner-1.2.8.tgz 中value.yaml的镜像修改为quay.io/codayblue/nfs-subdir-external-provisioner-arm64:latest
