
### EdgeGallery online  install guide 
#### 安装环境要求：
1.服务器或虚拟机架构：x86_64或 arm_64  \
2.服务器或虚拟机的配置要求：不低于4cpu 16G内存 100G硬盘  \
3.操作系统：ubuntu 18.04
#### 一、安装kubernetes 1.18.7 版本
#### 二、安装helm 3.2.4
wget -N https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz   x86下载helm网址  \
wget -N https://get.helm.sh/helm-v3.2.4-linux-arm64.tar.gz   ARM下载helm网址  \
tar -zxvf helm-v3.2.4-linux-amd64.tar.gz  \
cp ./linux-amd64/helm /usr/local/bin/  \
helm version 
#### 三、安装harbor 
安装harbor指导链接：
https://gitee.com/edgegallery/installer/blob/master/offline/harbor_install/docker_compose_install_harbor.md
#### 四、安装nfs持久化
##### 1. 安装nfs服务
  apt-get install nfs-kernel-server \
  mkdir -p /nfs/data/   \
  chmod -R 755 /nfs/data/  \
  vim /etc/exports  \
  /nfs/data/ 192.168.100.0/24(rw,no_root_squash,sync) #设置挂载本机数据的机器ip或网段  \
  systemctl restart nfs-kernel-server \
  exportfs -v   
  ##### 2.安装nfs客户端
  下载nfs客户端 
  x86: https://gitee.com/OSDT/dashboard/projects/edgegallery/installer/blob/master/offline/Edgegallery_online_install/nfs-client-amd/nfs-client-provisioner-1.2.8.tgz  \
  ARM: https://gitee.com/OSDT/dashboard/projects/edgegallery/installer/blob/master/offline/Edgegallery_online_install/nfs-client-arm/nfs-client-provisioner-1.2.8.tgz    \
  helm install nfs-client-provisioner --set nfs.server=<nfs_sever_ip> --set nfs.path=/nfs/data/     nfs-client-provisioner-1.2.8.tgz # <nfs_sever_ip>为本机的ip  
  #### 五、生成edgegallery的secret
  ##### 1、生成所需的证书
  docker pull swr.ap-southeast-1.myhuaweicloud.com/edgegallery/deploy-tool:latest  
  export CERT_VALIDITY_IN_DAYS=365  \
  env="-e CERT_VALIDITY_IN_DAYS=$CERT_VALIDITY_IN_DAYS"   \
  mkdir /root/keys/     \
  docker run $env -v /root/keys:/certs swr.ap-southeast-1.myhuaweicloud.com/edgegallery/deploy-tool:latest
  ##### 2、生成edgegallery-ssl-secret 
  kubectl create secret generic edgegallery-ssl-secret \
     --from-file=keystore.p12=/root/keys/keystore.p12 \
     --from-literal=keystorePassword=te9Fmv%qaq \
     --from-literal=keystoreType=PKCS12 \
     --from-literal=keyAlias=edgegallery \
     --from-file=trust.cer=/root/keys/ca.crt \
     --from-file=server.cer=/root/keys/tls.crt \
     --from-file=server_key.pem=/root/keys/encryptedtls.key \
     --from-literal=cert_pwd=te9Fmv%qaq
  ##### 3、生成user-mgmt-jwt-secret
  kubectl create secret generic user-mgmt-jwt-secret \
     --from-file=publicKey=/root/keys/rsa_public_key.pem \
     --from-file=encryptedPrivateKey=/root/keys/encrypted_rsa_private_key.pem \
     --from-literal=encryptPassword=te9Fmv%qaq 
  ##### 4、生成edgegallery-appstore-docker-secret
  （下文$HARBOR_USER：本机ip  $HARBOR_USER:admin   $HARBOR_PASSWORD:默认Harbor12345 也可以自己定，安装完成后在harbor web页面改密码） \
  kubectl create secret generic edgegallery-appstore-docker-secret \
     --from-literal=devRepoUserName=$HARBOR_USER	 \
     --from-literal=devRepoPassword=$HARBOR_PASSWORD    \
     --from-literal=appstoreRepoUserName=$HARBOR_USER	 \
     --from-literal=appstoreRepoPassword=$HARBOR_PASSWORD
  ##### 5、生成edgegallery-mecm-secret
  kubectl create secret generic edgegallery-mecm-secret \
     --from-file=postgres_init.sql=/root/keys/postgres_init.sql \
     --from-literal=postgresPassword=te9Fmv%qaq \
     --from-literal=postgresApmPassword=te9Fmv%qaq \
     --from-literal=postgresAppoPassword=te9Fmv%qaq \
     --from-literal=postgresInventoryPassword=te9Fmv%qaq \
     --from-literal=dockerRepoUserName=$HARBOR_USER	 \
     --from-literal=dockerRepoPassword=$HARBOR_PASSWORD
  ##### 6、生成mecm-mepm-ssl-secret
  kubectl create secret generic mecm-mepm-ssl-secret \
     --from-file=server_tls.key=/root/keys/tls.key \
     --from-file=server_tls.crt=/root/keys/tls.crt \
     --from-file=ca.crt=/root/keys/ca.crt
  ##### 7、生成mecm-mepm-jwt-public-secret
  kubectl create secret generic mecm-mepm-jwt-public-secret \
     --from-file=publicKey=/root/keys/rsa_public_key.pem
  ##### 8、生成edgegallery-mepm-secret
  kubectl create secret generic edgegallery-mepm-secret \
     --from-file=postgres_init.sql=/root/keys/postgres_init.sql \
     --from-literal=postgresPassword=te9Fmv%qaq \
     --from-literal=postgresLcmCntlrPassword=te9Fmv%qaq \
     --from-literal=postgresk8sPluginPassword=te9Fmv%qaq 
  #### 六、安装edgegallery
  ##### 1、选择自己需要的helm-chart版本下载(以下是各个版本的下载地址)
  git clone -b master  https://gitee.com/edgegallery/helm-charts.git \ 
  git clone -b Release-v1.0 https://gitee.com/edgegallery/helm-charts.git  \
  git clone -b Release-v1.0.1   https://gitee.com/edgegallery/helm-charts.git 
  ##### 2、修改edgegallery-values.yaml文件
  下载edgegallery-values.yaml   \
  https://gitee.com/OSDT/dashboard/projects/edgegallery/installer/blob/master/offline/Edgegallery_online_install/edgegallery-values.yaml  #edgegallery values.yaml 的   \
  sed -i 's/192.168.1.11/192.168.1.12/g'   edgegallery-values.yaml   #需要将192.168.1.12 替换为自己的ip \
  sed -i ‘s/latest/v1.01/g’  edgegallery-values.yaml  #用自己的版本替代v1.01 
  ##### 3、install service-center
  helm install service-center-edgegallery  helm-charts/service-center  -f edgegallery-values.yaml  
  如果安装失败或安装错误运行 helm delete service-center-edgegallery
  ##### 4、install user-mgmt 
  helm install user-mgmt-edgegallery   helm-charts/user-mgmt  -f      edgegallery-values.yaml
  #####5、install appstore
  helm install appstore-edgegallery    helm-charts/appsrore   -f      edgegallery-values.yaml  --set appstoreBe.repository.dockerRepoEndpoint=$HARBOR_REPO_IP   --set appstoreBe.secretName=edgegallery-appstore-docker-secret  
  ##### 6、install developer 
  helm install developer-edgegallery   helm-charts/developer  -f      edgegallery-values.yaml   --set developer.dockerRepo.endpoint=$HARBOR_REPO_IP    --set developer.dockerRepo.password=$HARBOR_PASSWORD  --set developer.dockerRepo.username=$HARBOR_USER
  ##### 7、install mecm-fe
  helm install mecm-fe-edgegallery      helm-charts/mecm-fe    -f       edgegallery-values.yaml
  ##### 8、install mecm-meo             
  helm install mecm-meo-edgegallery   helm-charts/mecm-fe    -f      edgegallery-values.yaml   --set ssl.secretName=edgegallery-mecm-ssl-secret 
  --set mecm.secretName=edgegallery-mecm-secret --set mecm.repository.dockerRepoEndpoint=$HARBOR_REPO_IP  --set mecm.repository.sourceRepos="repo=$HARBOR_REPO_IP userName=$HARBOR_USER password=$HARBOR_PASSWORD"
  ##### 9、install atp
  helm install atp-edgegallery           helm-charts/atp        -f       edgegallery-values.yaml    
 ##### 10、install  mecm-mepm
  helm install mecm-mepm-edgegallery   helm-charts/mecm-mepm  -f       edgegallery-values.yaml  --set jwt.publicKeySecretName=mecm-mepm-jwt-public-secret --set ssl.secretName=mecm-mepm-ssl-secret --set mepm.secretName=edgegallery-mepm-secret 
  ##### 11、install mep
  helm install mep-edgegallery         helm-charts/mep        -f       edgegallery-values.yaml  --set networkIsolation.ipamType=host-local   --set networkIsolation.phyInterface.mp1=eth0   --set networkIsolation.phyInterface.mm5=eth0      # 需要把eth0替换为自己的网卡名