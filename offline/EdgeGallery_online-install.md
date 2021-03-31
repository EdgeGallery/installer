## EdgeGallery online  install guide 

### 一、安装kubernetes 1.18.7 版本
### 二、安装helm 3.2.4
wget -N https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz   x86下载helm网址  \
wget -N https://get.helm.sh/helm-v3.2.4-linux-arm64.tar.gz   ARM下载helm网址  \
tar -zxvf helm-v3.2.4-linux-amd64.tar.gz  \
cp ./linux-amd64/helm /usr/local/bin/  \
helm version 
### 三、安装harbor 
安装harbor指导链接：
https://gitee.com/edgegallery/installer/blob/master/offline/harbor_install/docker_compose_install_harbor.md
### 四、安装nfs持久化
#### 1. 安装nfs服务
apt-get install nfs-kernel-server \
mkdir -p /nfs/data/   \
chmod -R 755 /nfs/data/  \
vim /etc/exports  \
/nfs/data/ 192.168.100.0/24(rw,no_root_squash,sync) #设置挂载本机数据的机器ip或网段  \
systemctl restart nfs-kernel-server \
exportfs -v   
#### 2. 安装nfs客户端
下载离线安装包解包   
cd ./helm/helm-charts/stable/   \
helm install nfs-client-provisioner --set nfs.server=<nfs_sever_ip> --set nfs.path=/nfs/data/ nfs-client-provisioner-1.2.8.tgz # <nfs_sever_ip>为本机的ip  
### 五、安装edgegallery
#### 3、install service-center
helm install service-center-edgegallery  helm-charts/service-center  -f edgegallery-values.yaml
#### 4、install user-mgmt 
helm install user-mgmt-edgegallery   helm-charts/user-mgmt  -f      edgegallery-values.yaml
#### 5、install appstore
helm install appstore-edgegallery    helm-charts/appsrore   -f      edgegallery-values.yaml  --set appstoreBe.repository.dockerRepoEndpoint=$HARBOR_REPO_IP   --set appstoreBe.secretName=edgegallery-appstore-docker-secret  
#### 6、install developer 
helm install developer-edgegallery   helm-charts/developer  -f      edgegallery-values.yaml   --set developer.dockerRepo.endpoint=$HARBOR_REPO_IP    --set developer.dockerRepo.password=$HARBOR_PASSWORD  --set developer.dockerRepo.username=$HARBOR_USER
#### 7、install mecm-fe
helm install mecm-fe-edgegallery     helm-charts/mecm-fe    -f       edgegallery-values.yaml
#### 8、install mecm-meo             
helm install mecm-meo-edgegallery    helm-charts/mecm-fe    -f       edgegallery-values.yaml   --set ssl.secretName=edgegallery-mecm-ssl-secret 
--set mecm.secretName=edgegallery-mecm-secret --set mecm.repository.dockerRepoEndpoint=$HARBOR_REPO_IP  --set mecm.repository.sourceRepos="repo=$HARBOR_REPO_IP userName=$HARBOR_USER password=$HARBOR_PASSWORD"
#### 9、install atp
helm install atp-edgegallery         helm-charts/atp        -f       edgegallery-values.yaml    
#### 10、install  mecm-mepm
helm install mecm-mepm-edgegallery   helm-charts/mecm-mepm  -f       edgegallery-values.yaml  --set jwt.publicKeySecretName=mecm-mepm-jwt-public-secret --set ssl.secretName=mecm-mepm-ssl-secret --set mepm.secretName=edgegallery-mepm-secret 
#### 11、install mep
helm install mep-edgegallery         helm-charts/mep        -f       edgegallery-values.yaml  --set networkIsolation.ipamType=host-local   --set networkIsolation.phyInterface.mp1=eth0   --set networkIsolation.phyInterface.mm5=eth0   # 需要把eth0替换为自己的网卡名