
### 1.2 Version EdgeGallery Online Install Guide 
#### 安装环境要求：
1.服务器或虚拟机架构：x86_64或 arm_64  \
2.服务器或虚拟机的配置要求：不低于4cpu 16G内存 100G硬盘  \
3.操作系统：ubuntu 18.04
#### 一、安装kubernetes 1.18.7 版本
给docker.sock 文件设置权限（不可缺少此步骤） \
sudo chmod 666 /var/run/docker.sock
#### 二、安装helm 3.2.4
wget -N https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz   x86下载helm网址  \
wget -N https://get.helm.sh/helm-v3.2.4-linux-arm64.tar.gz   ARM下载helm网址  \
tar -zxvf helm-v3.2.4-linux-amd64.tar.gz  \
cp ./linux-amd64/helm /usr/local/bin/  \
helm version 
#### 三、安装harbor 
安装harbor指导链接：
https://gitee.com/edgegallery/installer/blob/master/EdgeGallery_online_install/docker_compose_install_harbor.md
#### 四、安装nfs持久化
##### 1. 安装nfs服务
  apt-get install nfs-kernel-server \
  mkdir -p /edgegallery/data/   \
  chmod -R 755 /edgegallery/data/  \
  vim /etc/exports  \
  /nfs/data/ 192.168.11.0/24(rw,no_root_squash,sync) #设置挂载本机数据的机器ip或网段  \
  systemctl restart nfs-kernel-server \
  exportfs -v   
  ##### 2.安装nfs客户端
  下载nfs客户端  \
  x86: https://gitee.com/edgegallery/installer/blob/master/EdgeGallery_online_install/nfs-client-amd/nfs-client-provisioner-1.2.8.tgz  \
  ARM: https://gitee.com/edgegallery/installer/blob/master/EdgeGallery_online_install/nfs-client-arm/nfs-client-provisioner-1.2.8.tgz  \
  helm install nfs-client-provisioner --set nfs.server=<nfs_sever_ip> --set nfs.path=/edgegallery/data/   nfs-client-provisioner-1.2.8.tgz   
  #<nfs_sever_ip>为本机的ip  
#### 五、生成edgegallery的secret
##### 1、生成所需的证书
  docker pull swr.ap-southeast-1.myhuaweicloud.com/edgegallery/deploy-tool:latest  
  export CERT_VALIDITY_IN_DAYS=365  \
  env="-e CERT_VALIDITY_IN_DAYS=$CERT_VALIDITY_IN_DAYS"   

  mkdir /root/keys/       \
  docker run $env -v /root/keys:/certs swr.ap-southeast-1.myhuaweicloud.com/edgegallery/deploy-tool:latest
##### 2、生成edgegallery-ssl-secret 
  kubectl create secret generic edgegallery-ssl-secret \  \
     --from-file=keystore.p12=/root/keys/keystore.p12 \  \
     --from-file=keystore.jks=/root/keys/keystore.jks  \  \
     --from-literal=keystorePassword=te9Fmv%qaq \  \
     --from-literal=keystoreType=PKCS12 \  \
     --from-literal=keyAlias=edgegallery \  \
     --from-literal=truststorePassword=te9Fmv%qaq  \  \
     --from-file=trust.cer=/root/keys/ca.crt \  \
     --from-file=server.cer=/root/keys/tls.crt \  \
     --from-file=server_key.pem=/root/keys/encryptedtls.key \ \
     --from-literal=cert_pwd=te9Fmv%qaq
##### 3、生成user-mgmt-jwt-secret
  kubectl create secret generic user-mgmt-jwt-secret \  \
     --from-file=publicKey=/root/keys/rsa_public_key.pem \ \
     --from-file=encryptedPrivateKey=/root/keys/encrypted_rsa_private_key.pem \ \
     --from-literal=encryptPassword=te9Fmv%qaq 
  
##### 4、生成mecm-mepm-ssl-secret
  kubectl create secret generic mecm-mepm-ssl-secret \ \
     --from-file=server_tls.key=/root/keys/tls.key \ \
     --from-file=server_tls.crt=/root/keys/tls.crt \ \
     --from-file=ca.crt=/root/keys/ca.crt  
##### 5、生成mecm-mepm-jwt-public-secret
  kubectl create secret generic mecm-mepm-jwt-public-secret \  \
     --from-file=publicKey=/root/keys/rsa_public_key.pem
 
##### 6.生成mep secret 以下是生成证书的步骤
  mkdir /root/mep_key  
  cd  /root/  \
  openssl rand -writerand .rnd  \
  cd   /root/mep_key     
###### 执行以下命令生成mep证书   
  openssl genrsa -out ca.key 2048 2>&1 >/dev/null   
  openssl req -new -key ca.key -subj /C=CN/ST=Peking/L=Beijing/O=edgegallery/CN=edgegallery -out ca.csr 2>&1 >/dev/null  \
  openssl x509 -req -days 365 -in ca.csr -extensions v3_ca -signkey ca.key -out ca.crt 2>&1 >/dev/null  

  openssl genrsa -out mepserver_tls.key 2048 2>&1 >/dev/null  \
  openssl rsa -in mepserver_tls.key -aes256 -passout pass:te9Fmv%qaq -out mepserver_encryptedtls.key 2>&1 >/dev/null  \
  echo -n te9Fmv%qaq > mepserver_cert_pwd 2>&1 >/dev/null    

  openssl req -new -key mepserver_tls.key -subj /C=CN/ST=Beijing/L=Beijing/O=edgegallery/CN=edgegallery -out mepserver_tls.csr 2>&1 >/dev/null  \
  openssl x509 -req -days 365 -in mepserver_tls.csr -extensions v3_req -CA ca.crt -CAkey ca.key -CAcreateserial -out mepserver_tls.crt 2>&1 >/dev/null  

  openssl genrsa -out jwt_privatekey 2048 2>&1 >/dev/null   \
  openssl rsa -in jwt_privatekey -pubout -out jwt_publickey 2>&1 >/dev/null   \
  openssl rsa -in jwt_privatekey -aes256 -passout pass:te9Fmv%qaq -out jwt_encrypted_privatekey 2>&1 >/dev/null   

###### 生成pg-secret   
  kubectl -n mep create secret generic pg-secret --from-literal=pg_admin_pwd=admin-Pass123 --from-literal=kong_pg_pwd=kong-Pass123  \ \
      --from-file=server.key=mepserver_tls.key --from-file=server.crt=mepserver_tls.crt
  
###### 生成mep-ssl    
 kubectl -n mep create secret generic mep-ssl --from-literal=root_key="$(openssl rand -base64 256 | tr -d '\n' | tr -dc '[[:alnum:]]' | cut -c -256)"\ \
      --from-literal=cert_pwd=te9Fmv%qaq --from-file=server.cer=mepserver_tls.crt --from-file=server_key.pem=mepserver_encryptedtls.key   \ \
      --from-file=trust.cer=ca.crt
   
###### 生成mepauth-secret  
  kubectl -n mep create secret generic mepauth-secret --from-file=server.crt=mepserver_tls.crt --from-file=server.key=mepserver_tls.key   \        
      --from-file=ca.crt=ca.crt --from-file=jwt_publickey=jwt_publickey  --from-file=jwt_encrypted_privatekey=jwt_encrypted_privatekey

#### 六、安装edgegallery
 ***以下的 'XXXXX' 'YYYYY' 'ZZZZZ' 分别表示 postgresql数据库密码、用户信息鉴权密码 、user-mgmt模块的redis密码。部署命令不提供密码默认值，需要用户在安装前自行设定密码值，密码必须同时使用大小写字母、数字和特殊符号组合，长度不小于8位，否则会因为密码复杂度无法满足要求而造成部署失败。**   \
 ***以下安装过程中的'HARBOR__IP' 'HARBOR_PASSWORD'表示[harbor安装指导](https://gitee.com/edgegallery/installer/blob/master/EdgeGallery_online_install/docker_compose_install_harbor.md)中设置的harbor ip和harbor的密码** 
##### 1、下载1.2版本helm-chart
  git clone -b Release-v1.2  https://gitee.com/edgegallery/helm-charts.git 
   
##### 2、修改edgegallery-values.yaml文件
  下载edgegallery-values.yaml地址：   \
  https://gitee.com/edgegallery/installer/blob/master/EdgeGallery_online_install/edgegallery-values.yaml    \
  sed -i 's/192.168.1.11/192.168.1.12/g'   edgegallery-values.yaml     #需要将192.168.1.12 替换为自己的ip 

##### 3、install service-center 
  helm install service-center-edgegallery  helm-charts/service-center  -f edgegallery-values.yaml  
  #如果安装失败或安装错误运行 helm delete service-center-edgegallery
##### 4、install user-mgmt 
  helm install user-mgmt-edgegallery   helm-charts/user-mgmt  -f    edgegallery-values.yaml     \ \
      --set  global.oauth2.clients.appstore.clientSecret=YYYYY   \ \
      --set  global.oauth2.clients.developer.clientSecret=YYYYY   \ \
      --set  global.oauth2.clients.mecm.clientSecret=YYYYY   \ \
      --set  global.oauth2.clients.atp.clientSecret=YYYYY     \ \
      --set  postgres.password=XXXXX  \ \
      --set  redis.password=ZZZZZ 
##### 5、install appstore
  helm install appstore-edgegallery  helm-charts/appstore  -f   edgegallery-values.yaml  \ \
      --set global.oauth2.clients.appstore.clientSecret=YYYYY   \ \
      --set appstoreBe.dockerRepo.endpoint=HARBOR__IP  \ \
      --set appstoreBe.dockerRepo.appstore.password=HARBOR_PASSWORD   \     
      --set appstoreBe.dockerRepo.appstore.username=admin  \ \
      --set appstoreBe.dockerRepo.developer.password=HARBOR_PASSWORD    \ \
      --set appstoreBe.dockerRepo.developer.username=admin  \ \
      --set postgres.password=XXXXX      
##### 6、install developer 
  helm install developer-edgegallery   helm-charts/developer  -f  edgegallery-values.yaml  \  
     --set global.oauth2.clients.developer.clientSecret=YYYYY  \ \
     --set developer.dockerRepo.endpoint=HARBOR__IP   \ \
     --set developer.dockerRepo.password=HARBOR_PASSWORD  \ \
     --set developer.dockerRepo.username=admin   \ \
     --set postgres.password=XXXXX  \ \
     --set developer.vmImage.password=123456       
##### 7、install mecm-meo     
  metric-server.yaml下载地址：  
  https://gitee.com/edgegallery/installer/blob/master/ansible_package/roles/k8s/files/metric-server.yaml  \
  kubectl apply -f metric-server.yaml      \
  helm install mecm-meo-edgegallery   helm-charts/mecm-meo   -f   edgegallery-values.yaml  \ \
      --set global.oauth2.clients.mecm.clientSecret=YYYYY \ \
      --set mecm.docker.fsgroup=$(getent group docker | cut -d: -f3)  \ \
      --set mecm.repository.dockerRepoEndpoint=HARBOR__IP   \ \
      --set mecm.repository.sourceRepos="repo=HARBOR_IP userName=admin password=HARBOR_PASSWORD"  \ \
      --set mecm.postgres.postgresPass=XXXXX  \ \
      --set mecm.postgres.inventoryDbPass=XXXXX  \ \
      --set mecm.postgres.appoDbPass=XXXXX  \ \
      --set mecm.postgres.apmDbPass=XXXXX
##### 8、install atp
  helm install atp-edgegallery    helm-charts/atp    -f    edgegallery-values.yaml     \ \
      --set global.oauth2.clients.atp.clientSecret=YYYYY    \ \
      --set postgres.password=XXXXX   
##### 9、install mecm-mepm
  mepm-service-account.yaml下载地址:         \
  https://gitee.com/edgegallery/installer/blob/master/ansible_package/roles/init/files/conf/manifest/mepm/mepm-service-account.yaml    \
  kubectl apply -f mepm-service-account.yaml    

  ingress helm-chart 下载地址：     \
  https://gitee.com/edgegallery/installer/blob/master/EdgeGallery_online_install/ingress-pankage/nginx-ingress-1.41.2.tgz   

  ingress.yaml下载地址:   
  https://gitee.com/edgegallery/installer/blob/master/ansible_install/roles/mecm-mepm/files/ingress.yaml 

  helm install  eg-ingress  nginx-ingress-1.41.2.tgz  \ \
      --set controller.service.type=NodePort  \ \
      --set controller.service.nodePorts.http=30102    \ \
      --set controller.service.nodePorts.https=31252  \ \
      --set controller.image.registry=""        \ \
      --set controller.image.repository=swr.ap-southeast-1.myhuaweicloud.com/eg-common/us.gcr.io/k8s-artifacts-prod/ingress-nginx/controller:v0.34.1 \ \
      --set controller.admissionWebhooks.patch.image.repository=swr.ap-southeast-1.myhuaweicloud.com/eg-common/jettech/kube-webhook-certgen:v1.0.0 \ \
      --set defaultBackend.image.repository=swr.ap-southeast-1.myhuaweicloud.com/eg-common/k8s.gcr.io/defaultbackend:1.5 \ \
      -f ingress.yaml

  helm install mecm-mepm-edgegallery helm-charts/mecm-mepm  -f  edgegallery-values.yaml  \ \
      --set jwt.publicKeySecretName=mecm-mepm-jwt-public-secret    \ \   
      --set ssl.secretName=mecm-mepm-ssl-secret    \ \
      --set mepm.postgres.postgresPass=XXXXX   \ \
      --set mepm.postgres.lcmcontrollerDbPass=XXXXX  \ \
      --set mepm.postgres.k8spluginDbPass=XXXXX   \ \
      --set mepm.postgres.ospluginDbPass=XXXXX  \ \
      --set mepm.postgres.apprulemgrDbPass=XXXXX
##### 10、install mep 
##### 10.1 创建路由 
  ip link add eg-mp1 link eth0 type macvlan mode bridge  #用自己本机的网卡名替代eth0  \
  ip addr add 200.1.1.2/24 dev eg-mp1  \
  ip link set dev eg-mp1 up   

  ip link add eg-mm5 link eth0 type macvlan mode bridge   #用自己本机的网卡名替代eth0  
  ip addr add 100.1.1.2/24 dev eg-mm5  \
  ip link set dev eg-mm5 up   
 
  eg-if.cfg文件地址：
  https://gitee.com/edgegallery/installer/blob/master/EdgeGallery_online_install/eg-if.cfg
  cp eg-if.cfg  /etc/network/interfaces.d/  

##### 10.3 安装mep-network
  multus.yaml、eg-sp-rbac.yaml、eg-sp-controller.yaml的下载地址:
  https://gitee.com/edgegallery/installer/tree/master/ansible_package/roles/init/files/conf/edge/network-isolation

  kubectl apply -f  multus.yaml       

  kubectl apply -f  eg-sp-rbac.yaml  

  sed -i 's?image: edgegallery/edgegallery-secondary-ep-controller:latest?image: edgegallery/edgegallery-secondary-ep-controller:v1.2.0?g' eg-sp- 
  controller.yaml       

  kubectl apply -f  eg-sp-controller.yaml   
##### 10.4 下载并解压macvlan 
  x86:  curl -LO  https://github.com/containernetworking/plugins/releases/download/v0.8.7/cni-plugins-linux-amd64-v0.8.7.tgz   
  arm： curl -LO  https://github.com/containernetworking/plugins/releases/download/v0.8.7/cni-plugins-linux-arm64-v0.8.7.tgz \
  解压下载的cni 文件后copy macvlan和host-local 到/opt/cni/bin 目录下`
##### 10.5 安装mep
  helm install mep-edgegallery     helm-charts/mep     -f    edgegallery-values.yaml \ \
     --set networkIsolation.ipamType=host-local   \ \         
     --set networkIsolation.phyInterface.mp1=eth0  \  \
     --set networkIsolation.phyInterface.mm5=eth0   \ \
     --set ssl.secretName=mep-ssl \ \
     --set postgres.kongPass=XXXXX      #需要把eth0替换为自己的网卡名
