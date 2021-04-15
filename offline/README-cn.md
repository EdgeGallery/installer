##                                     EdgeGallery离线安装说明


EdgeGallery离线安装程序是基于ubuntu x86_64或arm64体系结构的给Kubernetes的EdgeGallery部署提供了部署程序，方便各种只有局域网无公网环境，单机环境提供了新的安装方式

 

部署架构

![输入图片说明](https://images.gitee.com/uploads/images/2020/0921/161645_3dc80db9_8040887.png "图片1.png")

 

场景



支持的系统版本

![输入图片说明](https://images.gitee.com/uploads/images/2020/0908/175524_dc986df0_7639331.png "屏幕截图.png")

 

部署先决条件：

1.在部署前先通过上面的场景表，选择自己要部署的场景，准备好需要的服务器。

   部署服务器最低配置建议使用：4CPU,16G内存，100G硬盘，单网卡或者多网卡。
   根据需求准备服务器：
   做普通测试简单操作可按照最低配置部署成单节点，最少需要一台服务器。
   现实环境是中心和边缘时分开的，中心（deploy节点，master节点，worker节点）三台服务器，
   边缘最少一个，如果按照现实环境搭建测试环境，则最少需要4台服务器。


2.在准备好的服务器上安装Ubuntu 18.04操作系统(ububntu 18.04是经过安装测试的版本)。

3.下载离线安装程程序，[下载地址](http://release.edgegallery.org/，根据具建议使用v1.0.0-staging.tar.gz这个安装包
 
  （如果网速慢，可以使用多线程下载方式，具体操作可参考文档最后安装遇到的问题中多线程下载说明）

4.下载完安装包后解压即可（多节点安装，安装包需要上传到deploy node(也就是场景表中EG_NODE_DEPLOY_IP对应的机器）edgegallery安装的过程是在安装节点deploy node的机器上进行，deploy节点作为安装容器和helm仓库使用)。

5.该安装包里已经包含kubernetes安装程序，按照下面流程安装edgegallery时会自动先安装kubernetes。

#### **部署流程演示图：**

![输入图片说明](https://images.gitee.com/uploads/images/2020/1027/174217_3eb4e54f_8040887.png "屏幕截图.png")

 

 

 

 


 

#### **edgegallery部署**

安装程序如安装场景表中所列，支持单节点和多节点安装edgegallery,以下是各个场景下安装步骤:

  edgegallery版本更新后PORTAL_IP在env.sh脚本中也可以添加，edgegallery场景部署中PORTAL_IP作为门户网址访问使用，通常我们使用的是 
  CONTROLLER_MASTER_IPS地址；在使用双网卡或网卡的安装时候，DEPLOY_IP,MASTER_IPS，WORKER_IPS一般使用的是局域网IP地址，PORTAL_IP
  可以使用公网IP作为外部地址。
 

### **一．单节点安装edgegallery场景：** 


 **1.edgegallery部署：** 

在之前解压缩的文件夹下修改env.sh配置文件

vim env.sh                                      //编辑env文件

export OFFLINE_MODE=aio                              //设置离线安装模式

export EG_NODE_EDGE_MP1=***                            //***为网卡名

export EG_NODE_EDGE_MM5=***                            //***为网卡名

export EG_NODE_MASTER_IPS=192.168.99.100             //设置IP地址

PORTAL_IP=159.138.x.y                        //如果需要为edgegallery门户网站配置IP，默认情况下，PORTAL_IP设置为 
                                              EG_NODE_CONTROLLER_MASTER_IPS

//修改完env文件保存退出

source env.sh                                   //运行使编辑保存完的文件生效                                                            

bash eg.sh -i                                   //开始安装程序

 **2.edgegallery中心部署** 

在之前解压缩的文件夹下修改env.sh配置文件

vim  env.sh                                      //编辑env文件

export OFFLINE_MODE=aio                               //设置离线安装模式

export EG_NODE_EDGE_MP1=***                            //***为网卡名

export EG_NODE_EDGE_MM5=***                            //***为网卡名

export EG_NODE_CONTROLLER_MASTER_IPS=192.168.99.101   //设置IP地址

PORTAL_IP=159.138.x.y                        //如果需要为edgegallery门户网站配置IP，默认情况下，PORTAL_IP设置为 
                                              EG_NODE_CONTROLLER_MASTER_IPS

//修改完env文件保存退出 

source env.sh                                  //运行使编辑保存完的文件生效

bash eg.sh -i                                  //开始安装程序

 **3.edgegallery边缘部署** 

在之前解压缩的文件夹下修改env.sh配置文件

vim env.sh                                       //编辑env文件

export OFFLINE_MODE=aio                               //设置离线安装模式 

export EG_NODE_EDGE_MP1=***                            //***为网卡名

export EG_NODE_EDGE_MM5=***                            //***为网卡名        

export EG_NODE_EDGE_MASTER_IPS=192.168.99.104         //设置IP地址

//修改完env文件保存退出

source env.sh                                    //运行使编辑保存完的文件生效

bash eg.sh -i                                    //开始安装程序

###  **二．多节点部署edgegallery场景** 



 **-  多节点安装需要配置ssh无密登录：** 

 1）在deploy节点生生产密钥：

    ssh-keygen     //生成密钥，指令执行过程中凡是需要输入的地方直接按回车建就行

 2）在deploy节点将生成的id_rsa.pub文件copy到master和worker节点：

    scp /root/.ssh/id_rsa.pub  (master IP):/root/.ssh
      
    scp /root/.ssh/id_rsa.pub  (worker IP):/root/.ssh
      
 3）分别在deploy，master，worker节点执行免密：

    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

    设置/etc/ssh/ssh_config文件中

    StrictHostKeyChecking no   //vim编辑ssh_config文件将StrictHostKeyChecking参数设置为no

    systemctl restart sshd      //重启sshd服务

    systemctl status sshd         //查看sshd状态



 **1.edgegallery部署**     

在之前解压缩的文件夹下修改env.sh配置文件 

vim env.sh                                                   //编辑env文件

export OFFLINE_MODE=muno                                   //设置离线安装模式

export EG_NODE_EDGE_MP1=***                            //***为master网卡名

export EG_NODE_EDGE_MM5=***                            //***为master为网卡名

export EG_NODE_DEPLOY_IP=192.168.99.100                    //设置deploy节点IP地址
  
export EG_NODE_MASTER_IPS=192.168.99.101                   //设置master节点IP地址

export EG_NODE_WORKER_IPS=192.168.99.102,192.168.99.103   //设置work节点IP地址

PORTAL_IP=159.138.x.y                                    //如果需要为edgegallery门户网站配置IP，默认情况下，
                                                          PORTAL_IP设置为EG_NODE_CONTROLLER_MASTER_IPS

//修改完env文件保存退出

source env.sh                                       //运行使编辑保存完的文件生效

bash eg.sh -i                                      //开始安装程序


 **2.edgegallery中心部署** 

在之前解压缩的文件夹下修改env.sh配置文件

vim env.sh                                           //编辑env文件

export OFFLINE_MODE=muno                                  //设置离线安装模式

export EG_NODE_EDGE_MP1=***                                      //***为master网卡名

export EG_NODE_EDGE_MM5=***                                      //***为master网卡名

export EG_NODE_DEPLOY_IP=192.168.99.100                     //设置deploy节点IP地址

export EG_NODE_CONTROLLER_MASTER_IPS=192.168.99.101       //设置master节点IP地址

export EG_NODE_CONTROLLER_WORKER_IPS=192.168.99.102,192.168.99.103 //设置work节点IP地址

PORTAL_IP=159.138.x.y                                    //如果需要为edgegallery门户网站配置IP，默认情况下，
                                                          PORTAL_IP设置为EG_NODE_CONTROLLER_MASTER_IPS

//修改完env文件保存退出

source env.sh                                        //运行使编辑保存完的文件生效

bash eg.sh -i                                        //开始安装程序

 **3.edgegallery边缘部署** 

在之前解压缩的文件夹下修改env.sh配置文件

vim env.sh                                                      //编辑env文件

export OFFLINE_MODE=muno                                       //设置离线安装模式

export EG_NODE_EDGE_MP1=***                                      //***为master网卡名

export EG_NODE_EDGE_MM5=***                                      //***为master网卡名

export EG_NODE_DEPLOY_IP=192.168.99.100                          //设置deploy节点IP地址

export EG_NODE_EDGE_MASTER_IPS=192.168.99.104                  //设置master节点IP地址

export EG_NODE_EDGE_WORKER_IPS=192.168.99.105,192.168.99.106   //设置work节点IP地址

//修改完env文件保存退出

source env.sh                                             //运行使编辑保存完的文件生效

bash eg.sh -i                                             //开始安装程序


###  **三.Kubernetes部署** 


​      该安装程序还提供了通过在env.sh中设置env变量，仅部署kubernetes的选项：

 **1.单节点部署kubernetes** 

 vim  env.sh                                   //编辑env文件

export OFFLINE_MODE=aio                             //设置离线安装模式

export K8S_NODE_MASTER_IPS=192.168.100.120          //设置IP地址

//修改完env文件保存退出

source env.sh                                 //运行使编辑保存完的文件生效

bash eg.sh -i                                 //开始安装程序

 **2.多节点部署kubernetes** 

vim  env.sh                                  //编辑env文件

export OFFLINE_MODE=muno                            //修改离线安装模式

export K8S_NODE_MASTER_IPS=192.168.100.120          //设置master节点IP地址  

export K8S_NODE_WORKER_IPS=192.168.100.120          //设置work节点IP地址

export K8S_NODE_DEPLOY_IP=192.168.100.120           //设置deploy节点IP地址 

//修改完env文件保存退出

source env.sh                                //运行使编辑保存完的文件生效

bash eg.sh -i                                //开始安装程序


#### **手动实例化图示：**(只支持用谷歌浏览器访问web页面)
![输入图片说明](https://images.gitee.com/uploads/images/2020/0921/161759_6f13ae7a_8040887.png "图片4.png")

新增超级管理员权限账号密码（建议安装完成后修改此密码）：

账号：admin  密码：Admin@321

![输入图片说明](https://images.gitee.com/uploads/images/2021/0415/180035_d4814889_8040887.png "屏幕截图.png")

![输入图片说明](https://images.gitee.com/uploads/images/2021/0415/180122_1f44fb27_8040887.png "屏幕截图.png")

测试验证注意点：

APPLCM注册：

在MECM上完成APPLCM注册。

![输入图片说明](https://images.gitee.com/uploads/images/2020/1027/174517_a702a2bb_8040887.png "屏幕截图.png")

(IP地址为边缘节点IP,端口30204)

![输入图片说明](https://images.gitee.com/uploads/images/2020/1027/174556_6517a16a_8040887.png "屏幕截图.png")

边缘节点注册：

![输入图片说明](https://images.gitee.com/uploads/images/2020/1027/174634_bdcdae73_8040887.png "屏幕截图.png")

配置文件上传：

配置文件为要注册的边缘节点/root/.kube/ 下config文件，下载并保存该文件在自己电脑上，在此位置上传配置文件。

![输入图片说明](https://images.gitee.com/uploads/images/2020/1027/174710_1f35f6cf_8040887.png "屏幕截图.png")

在中心侧添加沙箱环境：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0415/175741_8e634d4d_8040887.png "屏幕截图.png")
 

  
配置完成后退出。

在Developer（30092）网页上完成部署测试：

添加新项目：

![输入图片说明](https://images.gitee.com/uploads/images/2020/1027/174841_a53b87e1_8040887.png "屏幕截图.png")

基本信息填写：

![输入图片说明](https://images.gitee.com/uploads/images/2020/1027/174949_78233167_8040887.png "屏幕截图.png")

按照上述选择完成项目创建。

构建&测试：

![输入图片说明](https://images.gitee.com/uploads/images/2020/1027/175822_5ea52a73_8040887.png "屏幕截图.png")

参数配置：

![输入图片说明](https://images.gitee.com/uploads/images/2020/1027/175924_e2df337c_8040887.png "屏幕截图.png")

选择之前插入的边缘节点服务器信息:

![输入图片说明](https://images.gitee.com/uploads/images/2020/1027/180035_d5ebfa02_8040887.png "屏幕截图.png")

完成构建测试：

![输入图片说明](https://images.gitee.com/uploads/images/2020/1027/180115_f721ee5e_8040887.png "屏幕截图.png")

发布到应用商店：

![输入图片说明](https://images.gitee.com/uploads/images/2020/1027/180153_9ed9eb8f_8040887.png "屏幕截图.png")


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