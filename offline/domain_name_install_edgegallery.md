域名访问edgegallery部署指导
===========================

域名配置可以分为三步：

1.在公有云配置域名与服务器ip间的映射

2.在服务器上安装k8s和ingress

3.配置ingress，建立域名与k8s service间的关系

1.添加域名
----------

在华为云添加域名过程：在业务栏查找
域名注册→域名解析→公网域名解析→点击对应的公网域名→添加记录集→填写域名→填写iP

![](media/image1.png){width="7.889583333333333in"
height="4.691666666666666in"}

2.在机器上安装k8s
-----------------

(具体步骤参https://zhuanlan.zhihu.com/p/138554103)

安装helm
--------

wget *https://get.helm.sh/helm-v3.2.4-linux-*amd64.tar.gz

tar -zxvf helm-v3.2.4-linux-amd64.tar.gz

cp ./linux-amd64/helm /usr/local/bin/

helm version

4.**安装ingress**

kubectl label node &lt;node\_name&gt; node=edge
\#&lt;node\_name&gt;指本机的hostname

wget
https://kubernetes-charts.storage.googleapis.com/nginx-ingress-1.41.2.tgz

helm install nginx-ingress-controller nginx-ingress-1.41.2.tgz --set
controller.kind=DaemonSet --set controller.nodeSelector.node=edge --set
controller.hostNetwork=true

### *编辑value.yaml文件*

cd /root/

git clone *https://gitee.com/edgegallery/helm-charts.git*

在/root/helm-charts/edgegallery-center目录下编辑 value.yaml文件
开启ingress、ssl，更新hosts
和oauth填写上面添加的域名，根据需求决定是否开启sms

### 配置ingress.yaml

通过kind类型为ingress的yaml文件配置ingress，也可以通过helm
chart包进行ingress配置，此处采用第二种方式

helm install edgegallery-ingress /root/helm-charts/edgegallery-center -f
/root/helm-charts/edgegallery-center/values.yaml
\#部署ingress配置实现访问域名与k8s service间的映射

5.登录swr镜像仓库
-----------------

docker登录swr

docker login -u ap-southeast-1@0K1RQ5EAF2QRKQWQNFY0 -p
5468d8a0ebc64936a8196742d601bb95b99f1d94ad19c686488831e3dae79bb3
swr.ap-southeast-1.myhuaweicloud.com

k8s配置镜像拉取密钥

kubectl create secret docker-registry swrregcred \\

--docker-server=https://swr.ap-southeast-1.myhuaweicloud.com/v2/ \\

--docker-username=ap-southeast-1@0K1RQ5EAF2QRKQWQNFY0 \\

--docker-password=5468d8a0ebc64936a8196742d601bb95b99f1d94ad19c686488831e3dae79bb3

kubectl patch serviceaccount default -p '{"imagePullSecrets": \[{"name":
"swrregcred"}\]}'

6.生成ca和ssl证书文件
---------------------

docker pull
swr.ap-southeast-1.myhuaweicloud.com/edgegallery/deploy-tool:latest

export CERT\_VALIDITY\_IN\_DAYS=365

env="-e CERT\_VALIDITY\_IN\_DAYS=\$CERT\_VALIDITY\_IN\_DAYS"

mkdir /root/helm-charts/keys/

docker run \$env -v /root/helm-charts/keys:/certs
edgegallery/deploy-tool:latest

cd /root/helm-charts/keys/ \#用容器创建ca和ssl证书文件

从离线安装包copy postgres\_init.sql文件

wget http://release.edgegallery.org/daily/x86/edge/v1.0.1.tar.gz

tar -zxvf v1.0.1.tar.gz

cp ./conf/keys/postgres\_init.sql /root/helm-charts/keys

7.生成secret
------------

kubectl create secret generic edgegallery-ingress-secret \\

--from-file=ca.crt=ca.crt \\

--from-file=tls.crt=tls.crt \\

--from-file=tls.key=tls.key

kubectl create secret generic edgegallery-ssl-secret \\

--from-file=keystore.p12=keystore.p12 \\

--from-literal=keystorePassword=te9Fmv%qaq \\

--from-literal=keystoreType=PKCS12 \\

--from-literal=keyAlias=edgegallery \\

--from-file=trust.cer=ca.crt \\

--from-file=server.cer=tls.crt \\

--from-file=server\_key.pem=encryptedtls.key \\

--from-literal=cert\_pwd=te9Fmv%qaq

kubectl create secret generic user-mgmt-jwt-secret \\

--from-file=publicKey=rsa\_public\_key.pem \\

--from-file=encryptedPrivateKey=encrypted\_rsa\_private\_key.pem \\

--from-literal=encryptPassword=te9Fmv%qaq

kubectl create secret generic edgegallery-mecm-ssl-secret \\

--from-file=keystore.p12=keystore.p12 \\

--from-file=keystore.jks=keystore.jks \\

--from-literal=keystorePassword=te9Fmv%qaq \\

--from-literal=keystoreType=PKCS12 \\

--from-literal=keyAlias=edgegallery \\

--from-literal=truststorePassword=te9Fmv%qaq

kubectl create secret generic edgegallery-mecm-secret \\

--from-file=postgres\_init.sql=postgres\_init.sql \\

--from-literal=postgresPassword=te9Fmv%qaq \\

--from-literal=postgresApmPassword=te9Fmv%qaq \\

--from-literal=postgresAppoPassword=te9Fmv%qaq \\

--from-literal=postgresInventoryPassword=te9Fmv%qaq \\

--from-literal=edgeRepoUserName=admin \\

--from-literal=edgeRepoPassword=admin123

8.安装controller的模块
----------------------

> helm install service-center-edgegallery      /root/helm-charts/service-center        -f         /root/helm-charts/edgegallery-center/values.yaml 
> 
> helm install user-mgmt-edgegallery           /root/helm-charts/user-mgmt              -f         /root/helm-charts/edgegallery-center/values.yaml
>
> helm install developer-edgegallery             /root/helm-charts/developer                -f         /root/helm-charts/edgegallery-center/values.yaml
> 
>helm install appstore-edgegallery               /root/helm-charts/appstore                  -f         /root/helm-charts/edgegallery-center/values.yaml
> 
> helm install atp-edgegallery                         /root/helm-charts/atp                             -f         /root/helm-charts/edgegallery-center/values.yaml
>
> helm install mecm-fe-edgegallery               /root/helm-charts/mecm-fe                   -f         /root/helm-charts/edgegallery-center/values.yaml
> 
>helm install mecm-meo-edgegallery          /root/helm-charts/mecm-meo               -f         /root/helm-charts/edgegallery-center/values.yaml    --set ssl.secretName=edgegallery-mecm-ssl-secret    --set mecm.secretName=edgegallery-mecm-secret
