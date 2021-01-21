# EdgeGallery安装指导书

## 简介

​为了满足客户不同需求EdgeGallery安装提供了单节点和多节点离线安装模式，以下是部署架构图、安装模式、软件系统版本、部署前环境检查
、部署流程演示图、EdgeGallery部署步骤、EdgeGallery卸载步骤、部署完成后环境检查和手动实例化测试的详细介绍，请认真阅读。

## 部署架构图

![输入图片说明](https://images.gitee.com/uploads/images/2020/0921/161645_3dc80db9_8040887.png "图片1.png") 

 

## 安装模式介绍

​EdgeGallery是由Controller和Edge两部分组成，一个EdgeGallery环境只能有一个Controller但可以有一个或多个Edge，以下提供的场景有
EdgeGallery整体的安装、Controller单独安装和Edge单独安装的安装的方式，这些安装方式又分为单节点安装和多节点安装模式，多节点安装
至少需要三台机器,分别作为deploy node、master node、worker node，可以根据自己的需要选择合适的模块和安装方式根据EdgeGallery安
装步骤去安装。

deploy node: deploy node作用是给master和worker安装EdgeGallery,同时作为docker 仓库、helm仓库。

master node: master node是 k8s的控制节点和worker node组成集群，根据部署架构图可以看出EdgeGallery是以k8s为基础承载的，
EdgeGallery的模块也是和k8一样分布在集群了不同机器上。

worker node:  worker node 和master node组成集群，对master起到负载均衡的作用。

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/163543_b70bd69f_7624663.png "屏幕截图.png")

## 系统软件版本

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/163745_9282c719_7624663.png "屏幕截图.png")

 
## 部署前环境检查

a. 在部署前先根据上面的安装模式表，选择自己要部署安装的模块和安装模式，准备好需要的服务器

注:服务器最低配置要求：4CPU,内存16G,硬盘100G。 

b. 在服务器上安装Ubuntu 18.04操作系统。

c. 根据要安装的模块下载相应的EdgeGallery-v1.0.tar.gz安装包，注意如果多节点安装则需要把安装包下载或上传到deploy node上。

## 部署流程图

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/175751_b598d0e0_7624663.png "屏幕截图.png")
 

## EdgeGallery部署步骤

### EdgeGallery整体安装

#### 单节点安装EdgeGallery步骤

tar -zxvf  EdgeGallery-v1.0.tar.gz -C  /root/eg/    	//解压安装包到合适的路径下 

vim env.sh   						// 编辑env.sh，请注意以下需要编辑的行需要删掉开头的‘#’符号

export OFFLINE_MODE=aio   			//设置安装模式，单节点模式设置为aio

PORTAL_IP=192.168.1.1   			//设置EdgeGallery web页面访问IP，可以为本机公网IP或自己本地能访问到本机的私网IP

export EG_NODE_EDGE_MP1=*    		// ‘*’代表本机的网卡名 可以用‘ip addr’ 命令查询

export EG_NODE_EDGE_MM5=*   			// ‘*’代表本机的网卡名  可以和MP1设置一样的网卡名

export EG_NODE_MASTER_IPS=192.168.1.1   	//设置本机的私网IP

保存配置的env.sh退出

source  env.sh   		//运行脚本使以上配置生效

bash  eg.sh  -i   			//开始安装Edgegalley，大约10min后可以安装完成

 

#### 多节点安装EdgeGallery步骤

ssh-key-gen   		//在deploy node生成密钥，生成密钥过程中需要输入的步骤敲回车键直到命令执行完毕

scp /root/.ssh/id_rsa.pub [master私网IP]:/root/.ssh/authorized_keys	//把deploy node的公钥拷贝到master node实现deploy node点可以免密登录master node

scp /root/.ssh/id_rsa.pub [worker私网 IP]:/root/.ssh/authorized_keys	//把deploy node的公钥拷贝到worker node实现deploy node点可以免密登录worker node

mv  /root/.ssh/id_rsa.pub  /root/.ssh/authorized_keys		//把deploy node的公钥改名为authorized_keys 实现deploy node可以免密登录机

在deploy node依次登录master node、worker node和deploy node点检查是否可以免密登录（本步骤不可忽略）

在deploy node配置变量：

tar -zxvf EdgeGallery-v1.0.tar.gz -C  /root/eg/		//解压安装到合适的路径下 

vim env.sh           		//编辑env.sh，请注意以下需要编辑的行需要删掉开头的”#”符号

export OFFLINE_MODE=muno   	//设置安装模式，多节点模式设置为muno

PORTAL_IP=192.168.1.1       		//设置EdgeGallery web页面访问IP，必须为master node公网IP或自己本地网络能访问到的私网IP

export EG_NODE_DEPLOY_IP=192.168.99.100		//设置deploy node私网IP地址

export EG_NODE_MASTER_IPS=192.168.99.101		//设置master node私网IP地址

export EG_NODE_WORKER_IPS=192.168.99.102,192.168.99.103   //设置worker node私网IP地址

export EG_NODE_EDGE_MP1=*  	// ‘*’代表master node的网卡名 可以用‘ip addr’命令查询

export EG_NODE_EDGE_MM5=*   		// ‘*’代表master node的网卡名  可以和MP1设置一样的网卡名

保存配置的env.sh退出

source  env.sh         	//运行脚本使以上配置生效

bash  eg.sh  -i        		//开始安装Controller，大约6min后可以安装完成

 

### Controller节点安装

#### 单节点安装Controller步骤

tar -zxvf  EdgeGallery-v1.0.tar.gz  -C  /root/eg/  //解压安装到合适的路径下 

vim env.sh   					// 编辑env.sh，请注意以下需要编辑的行需要删掉开头的’#’符号

export OFFLINE_MODE=aio   		//设置安装模式,单节点模式设置为aio

PORTAL_IP=192.168.1.1   	 //设置EdgeGallery web页面访问IP，可以为本机公网IP或自己本地能访问到本机的私网IP

export EG_NODE_CONTROLLER_MASTER_IPS=192.168.99.101   	//设置本机的私网IP

保存配置的env.sh退出

source  env.sh   	//运行脚本使以上配置生效

bash  eg.sh  -i   		//开始安装Controller，大约6 min后可以安装完成

 

#### 多节点安装Controller步骤

ssh-keygen  	//在deploy node生成密钥，生成密钥过程中需要输入的步骤敲回车键直到命令执行完毕

scp /root/.ssh/id_rsa.pub [master私网IP]:/root/.ssh/authorized_keys  	//把deploy node的公钥拷贝到master node实现deploy node点可以免密登录master node 
scp /root/.ssh/id_rsa.pub [worker私网IP]:/root/.ssh/authorized_keys 	//把deploy node的公钥拷贝到worker node实现deploy node点可以免密登录worker node

mv  /root/.ssh/id_rsa.pub  /root/.ssh/authorized_keys  		//把deploy node的公钥改名为authorized_keys 实现deploy node可以免密登录

在deploy node依次登录master node、worker node和deploy node点检查是否可以免密登录（本步骤不可忽略）

在deploy node配置变量：

tar -zxvf  EdgeGallery-v1.0.tar.gz  -C  /root/eg/   		//解压安装到合适的路径下 

vim env.sh   						//编辑env.sh，请注意以下需要编辑的行需要删掉开头的”#”符号

export OFFLINE_MODE=muno   			//设置安装模式,多节点模式设置为muno

PORTAL_IP=192.168.1.1  				//设置EdgeGallery web页面访问IP，必须为master node公网IP或私网IP

export EG_NODE_DEPLOY_IP=192.168.99.100  	//设置deploy node私网IP地址

export EG_NODE_CONTROLLER_MASTER_IPS=192.168.99.101	//设置master node私网IP地址

export EG_NODE_CONTROLLER_WORKER_IPS=192.168.99.102,192.168.99.103		//设置worker node私网IP地址

保存配置的env.sh退出

source  env.sh   		//运行脚本使以上配置生效

bash  eg.sh  -i   		//开始安装Controller，大约6min后可以安装完成

 

### Edge节点安装

#### 单节点安装Edge步骤

tar -zxvf  EdgeGallery-v1.0.tar.gz  -C  /root/eg/   			//解压安装包到合适的路径下 

vim env.sh   							//编辑env.sh，请注意以下需要编辑的行需要删掉开头的’#’符号

export OFFLINE_MODE=aio   				//设置安装模式,单节点模式设置为aio

export EG_NODE_EDGE_MP1=*    			// ‘*’代表本机的网卡名 可以用’ip addr’命令查询

export EG_NODE_EDGE_MM5=*   				// ’*’代表本机的网卡名  可以和MP1设置一样的网卡名

export EG_NODE_EDGE_MASTER_IPS=192.168.1.1  //设置本机的私网IP

保存配置的env.sh退出

source  env.sh   		//运行脚本使以上配置生效

bash  eg.sh  -i   			//开始安装edge，大约5min后可以安装完成

 

#### 多节点安装Edge步骤

ssh-keygen  		//在deploy node生成密钥，生成密钥过程中需要输入的步骤敲回车键直到命令执行完毕

scp /root/.ssh/id_rsa.pub [master私网IP]:/root/.ssh/authorized_keys	//把deploy node的公钥拷贝到master node实现deploy node点可以免密登录master node


scp /root/.ssh/id_rsa.pub [worker私网IP]:/root/.ssh/authorized_keys 	//把deploy node的公钥拷贝到worker node实现deploy node点可以免密登录worker node

mv  /root/.ssh/id_rsa.pub  /root/.ssh/authorized_keys  		//把deploy node的公钥改名为authorized_keys 实现deploy node可以免密登录

在deploy node依次登录master node、worker node和deploy node点检查是否可以免密登录（本步骤不可忽略）

在deploy node配置变量：

tar -zxvf  EdgeGallery-v1.0.tar.gz  -C  /root/eg/   		//解压安装到合适的路径下 

vim env.sh  	 					//编辑env.sh，请注意以下需要编辑的行需要删掉开头的”#”符号

export OFFLINE_MODE=muno   			//设置安装模式,多节点模式设置为muno

export EG_NODE_DEPLOY_IP=192.168.99.100  	//设置deploy node私网IP地址

export EG_NODE_EDGE_MASTER_IPS=192.168.99.101 				//设置master node私网IP地址

export EG_NODE_EDGE_WORKER_IPS=192.168.99.102,192.168.99.103 	//设置worker node 私网IP

export EG_NODE_EDGE_MP1=*    		// ‘*’代表master node的网卡名，可以用ip addr 命令查询

export EG_NODE_EDGE_MM5=*   			// ‘*’代表master node的网卡名,可以和MP1设置一样的网卡名

保存配置的env.sh退出

source  env.sh   					//运行脚本使以上配置生效

bash   eg.sh  -i   					//开始安装edge，大约5min后可以安装完成

 

## 部署完成后环境检查

Edgegallery部署成功会在最后的部署输出中会显示Edgegallery的图标和部署成功的提示，如果没有部署则表示部署过程中某个模块部署
失败因而部署脚本退出

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/164339_a5a586a9_7624663.png "屏幕截图.png")

kubectl get pod --all-namespaces  		// 检查pod的运行状态，正常情况下pod的状态时running，如果pod 的状态不
是running 则需要进一步定位，例如：
重启pod:  kubectl delete pod podname –n namespaces    
查看pod:  kubectl describe pod podname –n namespaces

最后一步则需要手动实例化测试

 

## EdgeGallery卸载步骤

bash eg.sh -u      	//卸载EdgeGallery, k8s保留

bash eg.sh -u all    	//卸载EdgeGallery和k8s 

 

 

## 插入边缘节点信息

选择多节点安装EdgeGallery或Controller 在master node 执行以下操作：

kubectl exec -it developer-be-postgres-0  /bin/bash   	//进入developer-be-postgres pod

psql -U developer developerdb       			//登陆数据库

insert into tbl_service_host(host_id, user_id, name, address, architecture, status, protocol, ip, os, port_range_min, port_range_max, port, delete) values ('3c55ac26-60e9-42c0-958b-1bf7ea4da60a', 'admin', 'Node1', 'XIAN', 'X86', 'NORMAL', 'https', '192.168.101.245', 'Ubuntu', 30000, 32767, 30204, null);

// 这条sql命令中 IP:是Edge的IP ,选择多节点安装Edgegaller时 IP:是master node IP,

选择多节点安装Edge时 IP:是master node IP ，arm环境需要将X86改为ARM

 

## 手动实例化测试

**EdgeGallery web页面登陆需要用Chrome浏览器**

### 注册用户登录MECM

#### 登录MECM界面

a) 登录网址: https://PORTAL_IP:30093  PORTAL_IP 是安装时在env.sh配置的PORTAL_IP 的IP

b) 在登录网址后看到的是MECM的概览页面此时登录用的guest用户，只有浏览页面的权限，不能执行有效的操作，需要点击右上角的“登录”跳转到登录页面

 ![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/164615_591ce0ab_7624663.png "屏幕截图.png")

#### 注册用户

到登录页面后，点击“免费注册”跳转后注册用户

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/164645_b0c0fbc8_7624663.png "屏幕截图.png") 

输入账号、密码、确认密码、电话、公司、选择性别、勾选我已同意并阅读、点击同意协议

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/164701_3e5c0efc_7624663.png "屏幕截图.png") 

输入账号密码，拖动滚动条完成验证并点击登录

 ![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/164717_8054421c_7624663.png "屏幕截图.png")
###  外部系统注册

#### AppLCM注册

登录MECM后，点击系统→AppLCM注册系统

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/164926_9dfa4171_7624663.png "屏幕截图.png") 

 

点击‘新增注册’注册AppLCM ,  IP地址为边缘节点IP,多节点安装只需输入master node IP即可，端口是30204

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/165418_9694ad04_7624663.png "屏幕截图.png")
 

#### AppRule注册

点击系统→AppRuleMGR→新增注册

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/165434_3dd945f0_7624663.png "屏幕截图.png")
 

输入IP地址为边缘节点IP,多节点安装只需输入master节点IP即可,端口30206，点击确定

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/165456_7012f816_7624663.png "屏幕截图.png")
 

#### 边缘节点注册

点击系统→边缘节点注册系统→新增注册

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/165515_86e3a8b9_7624663.png "屏幕截图.png")

输入IP地址为边缘节点IP,多节点安装只需输入master节点IP即可,选择安装环境的架和硬件能力

（没有可以不选）硬件品牌和型号 ，选择AppLCM IP，App Rule MGR IP,填写边缘IP，输入边缘仓库端口

点击确认

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/165530_00db4109_7624663.png "屏幕截图.png")

配置文件上传：

配置文件为要的边缘节点/root/.kube/ 下config文件，下载config文件，点击上传文件，看到提示‘你已成功上传配置文件’，则上传成功

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/165540_9956c1dc_7624663.png "屏幕截图.png")
 

### 在Developer 页面部署测试

网址:https://PORTAL_IP:30092  PORTAL_IP 是安装时在env.sh配置的PORTAL_IP 的IP

#### 添加新项目

登录后点击“工作空间”→点击添加新项目的“+”图标

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/165600_87f30845_7624663.png "屏幕截图.png") 

#### 基本信息填写

注意选择架构要匹配安装环境的架构

![输入图片说明](https://images.gitee.com/uploads/images/2021/0112/165620_a0f54b75_7624663.png "屏幕截图.png")

 

按照上述选择完成项目创建。

#### 部署调测

![输入图片说明](https://images.gitee.com/uploads/images/2021/0114/151806_2184322d_7624663.png "屏幕截图.png")

上传yaml文件

![输入图片说明](https://images.gitee.com/uploads/images/2021/0114/151916_35245a2c_7624663.png "屏幕截图.png")

#### 开始部署

![输入图片说明](https://images.gitee.com/uploads/images/2021/0114/151947_28a07f25_7624663.png "屏幕截图.png")

部署完成后点击应用发布：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0114/152008_3fdd0076_7624663.png "屏幕截图.png")
 

无规则使用时可直接下一步:


![输入图片说明](https://images.gitee.com/uploads/images/2021/0114/152039_fd823333_7624663.png "屏幕截图.png")

点击应用认证进行安全，遵从性以及沙箱测试：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0114/152112_0c0a1c2e_7624663.png "屏幕截图.png")
 

等待前面测试完成后，可发布到APP应用商店

 