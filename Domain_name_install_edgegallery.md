## 域名访问Edgegallery部署指导

===========================

域名配置可以分为三步：

1.在公有云配置域名与服务器ip间的映射

2.在服务器上安装k8s和ingress

3.配置ingress，建立域名与k8s service间的关系

### 一、添加域名

----------

在华为云添加域名过程:在业务栏查找
域名注册→域名解析→公网域名解析→点击对应的公网域名→添加记录集→填写域名→填写iP（‘值’代表

![输入图片说明](https://images.gitee.com/uploads/images/2021/0415/154047_cf5f94ee_7624663.png "aa.png")
### 二、在机器上安装k8s

-----------------

(具体步骤参https://zhuanlan.zhihu.com/p/138554103)

### 三、安装helm

--------

wget https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz

tar -zxvf helm-v3.2.4-linux-amd64.tar.gz

cp ./linux-amd64/helm /usr/local/bin/

helm version

### 四、安装ingress


kubectl label node &lt;node\_name&gt; node=edge
\#&lt;node\_name&gt;指本机的hostname

wget
https://kubernetes-charts.storage.googleapis.com/nginx-ingress-1.41.2.tgz

helm install nginx-ingress-controller nginx-ingress-1.41.2.tgz --set
controller.kind=DaemonSet --set controller.nodeSelector.node=edge --set
controller.hostNetwork=true

#### 编辑value.yaml文件

cd /root/

git clone *https://gitee.com/edgegallery/helm-charts.git*

在/root/helm-charts/edgegallery-center目录下编辑 value.yaml文件
开启ingress、ssl，更新hosts
和oauth填写上面添加的域名，根据需求决定是否开启sms

#### 配置ingress.yaml

通过kind类型为ingress的yaml文件配置ingress，也可以通过helm
chart包进行ingress配置，此处采用第二种方式

helm install edgegallery-ingress /root/helm-charts/edgegallery-center -f
/root/helm-charts/edgegallery-center/values.yaml
\#部署ingress配置实现访问域名与k8s service间的映射

### 后续操作按照在线安装指导操作 网址：
https://gitee.com/edgegallery/installer/blob/master/EdgeGallery_online_install/EdgeGallery_online_installation_guide.md
