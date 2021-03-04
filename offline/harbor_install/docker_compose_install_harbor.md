### DOCKER_COMPOSE_INSTALL_HARBOR
#### 1.Install docker and docker-compose
##### install docker 
apt-get install  docker.io 
##### install docker-compose
要求docker-compose version >1.18 \
curl -L https://get.daocloud.io/docker/compose/releases/download/1.26.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose \
chmod +x /usr/local/bin/docker-compose 
##### 修改docker.service
在ExecStart 行后面加 '--insecure-registry Ip:port',如下例 \
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --insecure-registry 192.168.1.11:443
#### 2.Download harbor offline pankage and set harbor.yml文件
wget https://github.com/goharbor/harbor/releases/download/v2.0.6/harbor-offline-installer-v2.0.6.tgz \
tar -zxvf harbor-offline-installer-v2.0.6.tgz \
cd harbor \
mkdir data_volume  #创建数据挂载目录 \
mkdir cert         #创建证书存放目录  \
mv  harbor.yml.temp harbor.yml  修改配置文件名称 
##### 设置hostname 
hostname: 192.168.1.11  #在harbor.yml的第五行设置hostname，设置hostname的ip是用于harbor web访问的ip \
在第8行和第10行的 http  port:80 前加#      #去掉http 用https 访问harbor web 
##### 设置证书目录
certificate: /root/harbor/cert/ca.crt   #文件的17行 \
private_key: /root/harbor/cert/ca.key   #文件的18行 
##### 设置数据挂载目录
data_volume: /root/harbor/data/
##### 生成证书
cd /root/ 
openssl rand -writerand .rnd   
cd harbor/cert/  \
openssl genrsa -out ca.key 4096  \
openssl req -x509 -new -nodes -sha512 -days 3650 \
    -subj "/C=CN/ST=Guangzhou/L=Guangzhou/O=example/CN=192.168.1.11" \
    -key ca.key \
    -out ca.crt \
mdkir -p /etc/docker/certs.d/192.168.1.11:443/   \
cp /root/harbor/cert/ca.key   /root/harbor/cert/ca.key    /etc/docker/certs.d/92.168.1.11/  \
cd /etc/docker/certs.d/192.168.1.11:443/  \
openssl x509 -inform PEM -in cacert.pem -out ca.crt   \
mv ca.key  192.168.1.11:key   \
mv ca.cert 192.168.1.11.cert   \
systemctl daemon-reload  \
systemctl restart docker 
#### 3.安装harbor
cd  /root/harbor/   \
./install.sh    #脚本安装harbor 
##### docker login harbor
docker login -uadmin -pHarbor12345 192.168.1.11:443
#### 4.登录harbor web界面
登录url https://192.168.1.11:443
##### 创建项目

