 
 

### 部署完成后实例化操作指导（v1.5.0版本）



##### 1.安装完成后的检查



使用ansible部署Edgegallery成功后会有部署提示，如果没有部署则表示部署过程中某个模块部署失败因而部署脚本退出

kubectl get pod --all-namespaces // 检查pod的运行状态，正常情况下pod的状态时running，

如果pod 的状态不是running 则需要进一步定位，例如：

kubectkl delete pod podname –n namespaces // 重启pod

kubectl describe pod podname –n namespaces // 查看pod

最后一步则需要手动实例化测试

##### 2.手动实例化测试


EdgeGallery web页面登陆需要用Chrome浏览器，目前设置的统一入口，https://master_IP:30095 （或者https://PORTAL_IP:30095）

![输入图片说明](images/2021-v1.5.0/image-30095.png)

###### 2.1 创建沙箱环境


集成开发-->系统管理-->沙箱管理

![输入图片说明](images/2021-v1.5.0/image-%E6%B2%99%E7%AE%B1.png)

创建沙箱
![输入图片说明](images/2021-v1.5.0/image-%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6.png)

K8S上传的config配置文件为：root/.kube/下的config文件

openstack沙箱环境为openstack的相关配置文件信息，将下面文件编辑成config文件上传：

export OS_USERNAME=admin

export OS_PASSWORD=******

export OS_PROJECT_NAME=admin

export OS_AUTH_URL=http://192.168.*.*/identity

export OS_IDENTITY_API_VERSION=3

export OS_PROJECT_DOMAIN_NAME=default

export OS_USER_DOMAIN_NAME=default

##### 2.2 上传镜像


集成开发-->系统管理-->系统镜像管理

![输入图片说明](images/2021-v1.5.0/image-%E9%95%9C%E5%83%8F.png)


容器镜像和虚拟机镜像：

![输入图片说明](images/2021-v1.5.0/image-%E9%95%9C%E5%83%8F.png)

##### 3.3 应用孵化


从菜单栏或者首页进入：

![输入图片说明](images/2021-v1.5.0/%E5%AD%B5%E5%8C%96.png)

新建应用,虚机或者容器:

![输入图片说明](images/2021-v1.5.0/image-%E5%88%9B%E5%BB%BA%E5%BA%94%E7%94%A8.png)

选择沙箱（需要部署相关能力时可在能力中心选择）：

![输入图片说明](images/2021-v1.5.0/image-shaxiang.png)

选择对应的沙箱：

![输入图片说明](images/2021-v1.5.0/image-shaxiang1.png)

###### 3.3.1 容器应用


容器类应用上传脚本yaml文件：

![输入图片说明](images/2021-v1.5.0/image-%E5%AE%B9%E5%99%A8.png)

上传yaml文件

![输入图片说明](images/2021-v1.5.0/image-yaml.png)

选择容器启动沙箱测试

![输入图片说明](images/2021-v1.5.0/image-test.png)

查看详情：

![输入图片说明](images/2021-v1.5.0/image%E8%AF%A6%E6%83%85.png)

###### 3.3.2 虚机应用

配置虚机网络创建虚机:

![输入图片说明](images/2021-v1.5.0/image-vm.png)

创建虚机配置：

![输入图片说明](images/2021-v1.5.0/image-%E9%85%8D%E7%BD%AE.png)

配置完成后启动测试：

![输入图片说明](images/2021-v1.5.0/image-testvm.png)

VNC登录，上传文件，生成镜像等功能体验。

##### 3.4 制作镜像

![输入图片说明](images/2021-v1.5.0/image-21.png)

选择打包预览，可以编辑预览生成的包：

![输入图片说明](images/2021-v1.5.0/image-22.png)

##### 3.5 边缘节点信息创建


![输入图片说明](images/2021-v1.5.0/image24.png)

MECM管理平台-系统-MEPM系统注册
新增mepm：
![输入图片说明](images/2021-v1.5.0/image-mepm.png)

MECM管理平台-边缘节点
新增边缘节点（上传对应边缘节点的config文件）：

![输入图片说明](images/2021-v1.5.0/image-25.png)


##### 3.6 测试认证

选择对应的测试场景进行测试：

![输入图片说明](images/2021-v1.5.0/image23.png)

测试完成成后选择发布：

![输入图片说明](images/2021-v1.5.0/image-26.png)

在应用仓库查看已发布的应用。

##### 3.7 MECM应用包部署

通过MECM部署应用到边缘

应用仓库注册

MECM管理平台-系统-应用仓库注册

![输入图片说明](images/2021-v1.5.0/image-28.png)

新增注册：

![输入图片说明](images/2021-v1.5.0/image-26.png)

MECM管理平台-系统-应用包管理  

同步APPSTORE仓库应用：

![输入图片说明](images/2021-v1.5.0/image-29.png)

选择同步完成的包进行分布部署：

![输入图片说明](images/2021-v1.5.0/image-31.png)