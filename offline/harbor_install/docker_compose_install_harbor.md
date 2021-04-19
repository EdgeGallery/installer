### DOCKER_COMPOSE_INSTALL_HARBOR
#### 1.Install docker and docker-compose
##### 1.1install docker 
apt-get install  docker.io 
##### 1.2 install docker-compose
要求docker-compose version >1.18 \
sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
chmod +x /usr/local/bin/docker-compose   
#### 1.3生成damon.json文件（下文所有的119.8.1.11需替换为自己的ip) 
cat <<EOF | tee /etc/docker/daemon.json   
{                                               
    "insecure-registries":["119.8.63.144"]     
}  \
EOF
#### 2.Download harbor offline pankage and set harbor.yml文件
wget https://github.com/goharbor/harbor/releases/download/v2.0.6/harbor-offline-installer-v2.0.6.tgz \
tar -zxvf harbor-offline-installer-v2.0.6.tgz \
cd harbor \
mkdir data_volume  #创建数据挂载目录 \
mkdir cert         #创建证书存放目录  \
mv  harbor.yml.tmpl harbor.yml  修改配置文件名称 
##### 设置hostname 
hostname: 192.168.1.11  #在harbor.yml的第五行设置hostname，设置hostname的ip是用于harbor web访问的ip \
在第8行和第10行的 http  port:80 前加#      #去掉http用https访问harbor web 
##### 设置证书目录
certificate: /root/harbor/cert/ca.crt   #文件的17行 \
private_key: /root/harbor/cert/ca.key   #文件的18行 
##### 设置数据挂载目录
data_volume: /root/harbor/data_volume/
##### 生成证书
cd /root/  \
openssl rand -writerand .rnd   
cd harbor/cert/  \
openssl genrsa -out ca.key 4096  \
openssl req -x509 -new -nodes -sha512 -days 3650 \
    -subj "/C=CN/ST=Guangzhou/L=Guangzhou/O=example/CN=192.168.1.11" \
    -key ca.key \
    -out ca.crt \
mkdir -p /etc/docker/certs.d/192.168.1.11:443/   \
cp /root/harbor/cert/ca.crt   /root/harbor/cert/ca.key    /etc/docker/certs.d/192.168.1.11:443/  \
cd /etc/docker/certs.d/192.168.1.11:443/  \
openssl x509 -inform PEM -in ca.crt -out ca.cert   \
mv ca.key  192.168.1.11.key   \
mv ca.cert 192.168.1.11.cert   
#### 重启docker
systemctl daemon-reload  
systemctl restart docker 
#### 3.安装harbor
cd  /root/harbor/   \
./install.sh    #脚本安装harbor 
##### docker login harbor
docker login -uadmin -pHarbor12345 192.168.1.11
##### 生成harbor secret
kubectl create secret docker-registry  harbor  --docker-server=https://192.168.1.11 --docker-username=admin  --docker-password=Harbor12345 \
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "harbor"}]}'
#### 4.登录harbor web界面
登录url https://192.168.1.11
##### 创建项目
创建appstore developer mecm 三个项目 \
![输入图片说明](https://images.gitee.com/uploads/images/2021/0331/145024_f78e2fed_7624663.png "屏幕截图.png")
