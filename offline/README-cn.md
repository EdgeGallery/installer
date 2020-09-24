##                                     edgegallery离线安装说明


EdgeGallery离线安装程序是基于ubuntu x86_64或arm64体系结构的给Kubernetes的EdgeGallery部署提供了部署程序，方便各种只有局域网无公网环境，单机环境提供了新的安装方式

 

部署架构

![输入图片说明](https://images.gitee.com/uploads/images/2020/0921/161645_3dc80db9_8040887.png "图片1.png")

 

场景

![输入图片说明](https://images.gitee.com/uploads/images/2020/0923/090906_afebe8b1_8040887.png "图片5.png")

支持的系统版本

![输入图片说明](https://images.gitee.com/uploads/images/2020/0908/175524_dc986df0_7639331.png "屏幕截图.png")

 

部署先决条件：

1.在部署前先通过上面的场景表，选择自己要部署的场景，准备好需要的服务器。

2.在准备好的服务器上安装Ubuntu 18.04操作系统(ububntu 18.04是经过安装测试的版本)。

3.下载离线安装程序，下载路径http://159.138.137.155，根据具体安装环境下载对应的安装包，建议使用/all/v0.9-CodeFreeze.tar.gz这个安装包。  

4.下载完安装包后解压即可（多节点安装，安装包需要上传到deploy node(也就是场景表中EG_NODE_DEPLOY_IP对应的机器）edgegallery安装的过程是在安装节点deploy node的机器上进行，deploy node只负责给其它节点安装edgegallery它本身不安装任何东西)。

5.该安装包里已经包含kubernetes安装程序，按照下面流程安装edgegallery时会自动先安装kubernetes。

#### **部署流程演示图：**

![输入图片说明](https://images.gitee.com/uploads/images/2020/0921/161738_6be158df_8040887.png "图片3.png") 

 

 

 

 

#### **手动实例化图示：**
![输入图片说明](https://images.gitee.com/uploads/images/2020/0921/161759_6f13ae7a_8040887.png "图片4.png")

 

#### **edgegallery部署**

安装程序如安装场景表中所列，支持单节点和多节点安装edgegallery,以下是各个场景下安装步骤:

一．单节点安装edgegallery场景：

1.edgegallery部署：

在之前解压缩的文件夹下修改env.sh配置文件

vim env.sh                                      //编辑env文件

export OFFLINE_MODE = aio                              //修改离线安装模式

export EG_NODE_MASTER_IPS = 192.168.99.100             //设置IP地址

//修改完env文件保存退出

source env.sh                                   //运行使编辑保存完的文件生效                                                            

bash eg.sh -i                                   //开始安装程序

2.edgegallery中心部署

在之前解压缩的文件夹下修改env.sh配置文件

vim  env.sh                                      //编辑env文件

export OFFLINE_MODE = aio                               //修改离线安装模式

export EG_NODE_CONTROLLER_MASTER_IPS = 192.168.99.101   //设置IP地址

//修改完env文件保存退出 

source env.sh                                  //运行使编辑保存完的文件生效

bash eg.sh -i                                  //开始安装程序

3.edgegallery边缘部署

在之前解压缩的文件夹下修改env.sh配置文件

vim env.sh                                       //编辑env文件

export OFFLINE_MODE = aio                               //修改离线安装模式         

export EG_NODE_EDGE_MASTER_IPS = 192.168.99.104         //设置IP地址

//修改完env文件保存退出

source env.sh                                    //运行使编辑保存完的文件生效

bash eg.sh -i                                    //开始安装程序

二．多节点部署edgegallery场景

1.edgegallery部署    

在之前解压缩的文件夹下修改env.sh配置文件 

vim env.sh                                                   //编辑env文件

export OFFLINE_MODE = muno                                   //修改离线安装模式

export EG_NODE_DEPLOY_IP = 192.168.99.100                    //设置deploy节点IP地址
  
export EG_NODE_MASTER_IPS = 192.168.99.101                   //设置master节点IP地址

export EG_NODE_WORKER_IPS = 192.168.99.102, 192.168.99.103   //设置work节点IP地址

//修改完env文件保存退出

source env.sh                                       //运行使编辑保存完的文件生效

bash eg.sh -i                                      //开始安装程序

2.edgegallery中心部署

在之前解压缩的文件夹下修改env.sh配置文件

vim env.sh                                           //编辑env文件

export OFFLINE_MODE = muno                                  //修改离线安装模式

export EG_NODE_DEPLOY_IP=192.168.99.100                     //设置deploy节点IP地址

export EG_NODE_CONTROLLER_MASTER_IPS = 192.168.99.101       //设置master节点IP地址

export EG_NODE_CONTROLLER_WORKER_IPS= 192.168.99.102, 192.168.99.103 //设置work节点IP地址

//修改完env文件保存退出

source env.sh                                        //运行使编辑保存完的文件生效

bash eg.sh -i                                        //开始安装程序

3.edgegallery边缘部署

在之前解压缩的文件夹下修改env.sh配置文件

vim env.sh                                                      //编辑env文件

export OFFLINE_MODE = muno                                       //修改离线安装模式

export EG_NODE_DEPLOY_IP=192.168.99.100                          //设置deploy节点IP地址

export EG_NODE_EDGE_MASTER_IPS = 192.168.99.104                  //设置master节点IP地址

export EG_NODE_EDGE_WORKER_IPS= 192.168.99.105, 192.168.99.106   //设置work节点IP地址

//修改完env文件保存退出

source env.sh                                             //运行使编辑保存完的文件生效

bash eg.sh -i                                             //开始安装程序

三.Kubernetes部署

​      该安装程序还提供了通过在env.sh中设置env变量，仅部署kubernetes的选项：

1.单节点部署kubernetes

 vim  env.sh                                   //编辑env文件

export OFFLINE_MODE=aio                             //修改离线安装模式

export K8S_NODE_MASTER_IPS=192.168.100.120          //设置IP地址

//修改完env文件保存退出

source env.sh                                 //运行使编辑保存完的文件生效

bash eg.sh -i                                 //开始安装程序

2.多节点部署kubernetes

vim  env.sh                                  //编辑env文件

export OFFLINE_MODE=muno                            //修改离线安装模式

export K8S_NODE_MASTER_IPS=192.168.100.120          //设置master节点IP地址  

export K8S_NODE_WORKER_IPS=192.168.100.120          //设置work节点IP地址

export K8S_NODE_DEPLOY_IP=192.168.100.120           //设置deploy节点IP地址 

//修改完env文件保存退出

source env.sh                                //运行使编辑保存完的文件生效

bash eg.sh -i                                //开始安装程序

#### **卸载**

在安装过程中使用相同的env.sh，source env.sh。然后按照以下步骤进行卸载

source env.sh                     //运行使编辑保存完的文件生效

bash eg.sh -u all                 // 完全卸载所以程序

bash eg.sh -u controller          //卸载中心节点

bash eg.sh -u edge                //卸载边缘节点