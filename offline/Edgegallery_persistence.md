### **Edgegallery nfs持久化安装指导**


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

#### 3.  **开启持久化**
在values.yaml 中设置persistence 状态为enabled
  
#### 4. **ARM架构安装镜像**

ARM架构机器做持久化 nfs-client-provisioner-1.2.8.tgz 中value.yaml的镜像修改为quay.io/codayblue/nfs-subdir-external-provisioner-arm64:latest
