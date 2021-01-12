## 新增边缘节点指导书

### 安装边缘节点准备

1.准备1台服务器，最低配置要求：4CPU,内存16G,硬盘100G。 

2.在服务器上安装Ubuntu 18.04操作系统。

3.根据服务器架构下载v1.0.0.tar.gz安装包

X86_64架构安装包网址：http://release.edgegallery.org/x86/edge/v1.0.0.tar.gz

ARM_64架构安装包网址：http://release.edgegallery.org/arm64/edge/v1.0.0.tar.gz


### 边缘节点安装步骤

tar -zxvf  v1.0.0.tar.gz  -C  /root/eg/   //解压安装包到合适的路径下 

vim env.sh   //编辑env.sh，请注意以下需要编辑的行需要删掉开头的’#’符号

export OFFLINE_MODE=aio   //设置安装模式,单节点模式设置为aio

export EG_NODE_EDGE_MP1=*    // ‘*’代表本机的网卡名 可以用’ip addr’命令查询

export EG_NODE_EDGE_MM5=*   // ’*’代表本机的网卡名 可以和MP1设置一样的网卡名

export EG_NODE_EDGE_MASTER_IPS=192.168.1.1   //设置本机的私网ip

保存配置的env.sh退出

source  env.sh   //运行脚本使以上配置生效

bash  eg.sh -i   //开始安装edge，大约5min后可以安装完成


### 安装完成后检查环境

命令：kubectl get pod --all-namespaces  // 检查pod,所有的pod状态为running ,则环境正常

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/185955_b278b54d_7624663.png "屏幕截图.png")


### 外部系统注册

#### APPLCM注册

登录mecm后，点击系统→applcm注册系统

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/190253_f61c2ee9_7624663.png "屏幕截图.png")
 

点击’新增注册’注册applcm ,  ip地址为边缘节点ip，端口是30204

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/190308_93d0f8f3_7624663.png "屏幕截图.png")
 

#### APPRULE注册

点击系统→apprulemgr→新增注册

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/190325_352507ee_7624663.png "屏幕截图.png")
 

输入IP地址为边缘节点IP,端口30206，点击确定

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/190338_fb67eaf6_7624663.png "屏幕截图.png")
 

#### 边缘节点注册

点击系统→边缘节点注册系统→新增注册

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/190357_9708d2e6_7624663.png "屏幕截图.png")

输入IP地址为边缘节点IP，选择安装环境的架和硬件能力（没有可以不选）硬件品牌和型号 ，选择applcm ip，apprulemgr ip,填写边缘ip，输入边缘仓库端口，点击确认

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/190420_546ee5e2_7624663.png "屏幕截图.png")

配置文件上传：

配置文件为要的边缘节点/root/.kube/ 下config文件，下载config 文件，点击上传文件，看到提示‘你已成功上传配置文件’，则上传成功

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/190434_66384ecf_7624663.png "屏幕截图.png")

 

 