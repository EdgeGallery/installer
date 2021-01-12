##                                     EdgeGallery安装指导书

## 简介

​        为了满足客户不同需求EdgeGallery安装提供了单节点和多节点离线安装模式，以下是部署架构图、安装模式、软件系统版本、部署前环境检查、部署流程演示图、EdgeGallery部署步骤、EdgeGallery卸载步骤、部署完成后环境检查和手动实例化测试的详细介绍，请认真阅读。

部署架构

![输入图片说明](https://images.gitee.com/uploads/images/2020/0921/161645_3dc80db9_8040887.png "图片1.png")

 

安装模式介绍
EdgeGallery是由Controller和Edge两部分组成，一个EdgeGallery环境只能有一个Controller但可以有一个或多个Edge，以下提供的场景有EdgeGallery整体的安装、Controller单独安装和Edge单独安装的安装的方式，这些安装方式又分为单节点安装和多节点安装模式，多节点安装至少需要三台机器,分别作为deploy node、master node、worker node，可以根据自己的需要选择合适的模块和安装方式根据EdgeGallery 安装步骤去安装。

deploy node: deploy node作用是给master和worker安装EdgeGallery,同时作为docker 仓库、helm仓库。

master node: master node是 k8s的控制节点和worker node组成集群，根据部署架构图可以看出EdgeGallery是以k8s为基础承载的，EdgeGallery的模块也是和k8一样分布在集群了不同机器上。

worker node:  worker node 和master node组成集群，对master起到负载均衡的作用。

![输入图片说明](https://images.gitee.com/uploads/images/2020/1231/165312_f56ce4ee_8040887.png "屏幕截图.png")

支持的系统版本

| Module     | Version | Arch           |
| ---------- | ------- | -------------- |
| Ubuntu     | 18.04   | ARM_64&X86__64 |
| Docker     | 18.09   | ARM_64&X86__64 |
| Helm       | 3.2.4   | ARM_64&X86__64 |
| Kubernetes | 1.18.7  | ARM_64&X86__64 |

 

 

部署前环境检查

a. 在部署前先根据上面的安装模式表，选择自己要部署安装的模块和安装模式，准备好需要的服务器

**注****：****服务器最低配置要求：4CPU,内存16G,硬盘100G。** 

b. 在服务器上安装Ubuntu 18.04操作系统。

c. 根据要安装的模块下载相应的EdgeGallery-v1.0.tar.gz安装包，注意如果多节点安装则需要把安装包下载或上传到deploy node上。

#### **部署流程演示图：**

![输入图片说明](https://images.gitee.com/uploads/images/2020/1027/174217_3eb4e54f_8040887.png "屏幕截图.png")

 

 

 

 


 

#### **EdgeGallery部署步骤**
### EdgeGallery整体安装

#### 单节点安装EdgeGallery步骤


tar -zxvf  EdgeGallery-v1.0.tar.gz -C  /root/eg/    	//解压安装包到合适的路径下 

vim env.sh   						// 编辑env.sh，请注意以下需要编辑的行需要删掉开头的‘#’符号

export OFFLINE_MODE=aio   			//设置安装模式，单节点模式设置为aio

PORTAL_IP=192.168.1.1   				//设置EdgeGallery web页面访问IP，可以为本机公网IP或自己本地能访问到本机的私网IP

export EG_NODE_EDGE_MP1=*    		// ‘*’代表本机的网卡名 可以用‘ip addr’ 命令查询

export EG_NODE_EDGE_MM5=*   			// ‘*’代表本机的网卡名  可以和MP1设置一样的网卡名

export EG_NODE_MASTER_IPS=192.168.1.1   	//设置本机的私网IP

保存配置的env.sh退出

source  env.sh   		//运行脚本使以上配置生效

bash  eg.sh  -i   			//开始安装Edgegalley，大约10min后可以安装完成

 

#### 多节点安装EdgeGallery步骤

ssh-key-gen   		//在deploy node生成密钥，生成密钥过程中需要输入的步骤敲回车键直到命令执行完毕

scp /root/.ssh/id_rsa.pub [master IP]:/root/.ssh/authorized_keys	//把deploy node的公钥拷贝到master node实现deploy node点可以免密登录master node

scp /root/.ssh/id_rsa.pub [worker IP]:/root/.ssh/authorized_keys	//把deploy node的公钥拷贝到worker node实现deploy node点可以免密登录worker node

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

scp /root/.ssh/id_rsa.pub [master IP]:/root/.ssh/authorized_keys  	//把deploy node的公钥拷贝到master node实现deploy node点可以免密登录master node 
scp /root/.ssh/id_rsa.pub [worker IP]:/root/.ssh/authorized_keys 	//把deploy node的公钥拷贝到worker node实现deploy node点可以免密登录worker node

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

scp /root/.ssh/id_rsa.pub [master IP]:/root/.ssh/authorized_keys	//把deploy node的公钥拷贝到master node实现deploy node点可以免密登录master node


scp /root/.ssh/id_rsa.pub [worker IP]:/root/.ssh/authorized_keys 	//把deploy node的公钥拷贝到worker node实现deploy node点可以免密登录worker node

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

 

部署完成后环境检查

Edgegallery部署成功会在最后的部署输出中会显示Edgegalleryd的图标和部署成功的提示，如果没有部署则表示部署过程中某个模块部署失败因而部署脚本退出

![img](file:///C:\Users\ADMINI~1\AppData\Local\Temp\2\ksohtml7216\wps27.jpg) 

kubectl get pod --all-namespaces  		// 检查pod的运行状态，正常情况下pod的状态时running，如果pod 的状态不是running 则需要进一步定位，例如：重启pod  kubectl delete pod podname –n namespaces    查看pod: kubectl describe pod podname –n namespaces

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


#### **手动实例化图示：**(只支持用谷歌浏览器访问web页面)
![输入图片说明](https://images.gitee.com/uploads/images/2020/0921/161759_6f13ae7a_8040887.png "图片4.png")

测试验证注意点：

APPLCM注册：

在MECM上完成APPLCM注册。

![输入图片说明](https://images.gitee.com/uploads/images/2020/1228/182718_139e7f7d_8040887.png "屏幕截图.png")

(IP地址为边缘节点IP,端口30204)

![输入图片说明](https://images.gitee.com/uploads/images/2020/1027/174556_6517a16a_8040887.png "屏幕截图.png")

APPRULE注册：

在MECM上完成APPRULE注册。

![输入图片说明](https://images.gitee.com/uploads/images/2020/1228/184309_32d9c426_8040887.png "屏幕截图.png")

(IP地址为边缘节点IP,端口30206

![输入图片说明](https://images.gitee.com/uploads/images/2020/1228/183252_071b093e_8040887.png "屏幕截图.png")


边缘节点注册：

![输入图片说明](https://images.gitee.com/uploads/images/2020/1027/174634_bdcdae73_8040887.png "屏幕截图.png")

配置文件上传：

配置文件为要注册的边缘节点/root/.kube/ 下config文件，下载并保存该文件在自己电脑上，在此位置上传配置文件。

![输入图片说明](https://images.gitee.com/uploads/images/2020/1027/174710_1f35f6cf_8040887.png "屏幕截图.png")

在中心节点配置数据库：
  kubectl exec -it developer-be-postgres-0 /bin/sh         //进去容器
 
 psql -U developer developerdb                      
 
下面为1条指令，IP地址为边缘节点IP
  
insert into tbl_service_host(host_id, user_id, name, address, architecture, status, protocol, ip, os, port_range_min, port_range_max, 
port, delete) values ('3c55ac26-60e9-42c0-958b-1bf7ea4da60a', 'admin', 'Node1', 'XIAN', 'X86', 'NORMAL', 'https', '192.168.101.245', 
'Ubuntu', 30000, 32767, 30204, null);
  
配置完成后退出。

在Developer（30092）网页上完成部署测试：

添加新项目：

![输入图片说明](https://images.gitee.com/uploads/images/2020/1228/184502_e4f4f987_8040887.png "屏幕截图.png")

基本信息填写：

![输入图片说明](https://images.gitee.com/uploads/images/2020/1027/174949_78233167_8040887.png "屏幕截图.png")

按照上述选择完成项目创建。

部署调测：

![输入图片说明](https://images.gitee.com/uploads/images/2020/1228/184622_2ca52014_8040887.png "屏幕截图.png")

上传YAML文件：

![输入图片说明](https://images.gitee.com/uploads/images/2020/1228/184742_f7207614_8040887.png "屏幕截图.png")

开始部署:

![输入图片说明](https://images.gitee.com/uploads/images/2020/1228/184922_9c13e35d_8040887.png "屏幕截图.png")

部署完成后点击应用发布：

![输入图片说明](https://images.gitee.com/uploads/images/2020/1228/185315_c3735204_8040887.png "屏幕截图.png")

无规则使用时可直接下一步:

![输入图片说明](https://images.gitee.com/uploads/images/2020/1228/185450_d31efa03_8040887.png "屏幕截图.png")

点击应用认证进行安全，遵从性以及沙箱测试：

![输入图片说明](https://images.gitee.com/uploads/images/2020/1228/185712_10ac57f1_8040887.png "屏幕截图.png")

等待前面测试完成后，可发布到APP应用商店

#### **卸载**

在安装过程中使用相同的env.sh，source env.sh。然后按照以下步骤进行卸载

source env.sh                     //运行使编辑保存完的文件生效

bash eg.sh -u all                 // 完全卸载所以程序

bash eg.sh -u controller          //卸载中心节点

bash eg.sh -u edge                //卸载边缘节点

安装中问题汇总：
1. pod装置pending处理方法
安装完成后pod状态正常为running状态，kubectl get pos --all-namespaces

​ 如果status为pending状态：

​ ![输入图片说明](https://images.gitee.com/uploads/images/2020/0930/174214_10fc1169_8040887.png "POD.png")

A.检查虚机CPU，内存使用情况，确认资源是否够用。

B.检查node或者pod有没有污点

kubectl describe node | grep taint


如果存在污点删除污点后删除污点，

kubectl taint node hostname key:NoSchedule- //hostname为本机名称

2. MEP安装DNS问题
边缘环境测试，多网卡mp1和mm5网卡隔离，从mp1接口获取mep给的token失败

该原因为DNS有问题导致。

![输入图片说明](https://images.gitee.com/uploads/images/2020/0930/174238_7bdf76f3_8040887.png "DNS.png")

DNS的53端口，由于环境安全策略屏蔽了该端口，在华为云上打开此端口问题解决


  3.安装过程中K8S的8080端口问题导致安装K8S安装失败

具体情况如下：

![输入图片说明](https://images.gitee.com/uploads/images/2020/1020/091732_286e364b_8040887.png "8080-1.png")

该问题为K8S为安装成功：

kubeadm reset -f   

kubeadm init --kubernetes-version=1.18.7

根据上条指令提示执行下面的命令：

mkdir -p $HOME/.kube

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

完成后重新执行bash eg.sh -i安装即可

这样安装过程中可能会使个别pod存在污点导致pod状态一直为pending状态，可以直接使用

kubectl taint nodes --all node-role.kubernetes.io/master-  删除污点。

在继续安装bash eg.sh -i即可，或者安装过程中重新打开一个窗口您使用kebuctl get pod --all-spaces中有pod状态为pending状态，

且安装进程一直在等待该pod running 也可以直接使用上述删除污点的指令，安装流程也会直接向下执行。

  4.多线程下载说明
    
安装axel包：

  sudo apt install axel

多线程下载：

axel -n 10 -o /tmp/ http://release.edgegallery.org/x86/all/EdgeGallery-v0.9.tar.gz

其中-n  10  表示10线程
-o  /tmp/   下载保存文件目录为/tmp/