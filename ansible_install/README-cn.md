# EdgeGallery Ansible离线安装指导


EdgeGallery离线安装是为单机环境提供的安装方式，便于各种只有局域网无公网环境进行EdgeGallery安装。

与在线部署一致，离线部署也是基于Ubuntu系统，Kubernetes，支持x86_64和ARM64体系结构。

## 1. 部署架构

![输入图片说明](https://images.gitee.com/uploads/images/2020/0921/161645_3dc80db9_8040887.png "图片1.png")

## 2. 部署场景

| 节点模式 | EdgeGallery组件 | 集群    |所需机器    |
|---------|---------------|-----------|-----------|
| 单节点   | All           | 同一个集群 |  1台     |
|         | Controller    | 同一个集群 |  1台     |
|         | Edge          | 同一个集群 |  1台     |
| 多节点   | All           |           |       |
|         | Controller    |           |      |
|         | Edge          |           |       |


## 3. 部署依赖组件及版本


| Module     | Version | Arch            |
|------------|---------|-----------------|
| Ubuntu     | 18.04   | ARM 64 & X86_64 |
| Docker     | 18.09   | ARM 64 & X86_64 |
| Helm       | 3.2.4   | ARM 64 & X86_64 |
| Kubernetes | 1.18.7  | ARM 64 & X86_64 |
| Ansible    | 2.10.4  | ARM 64 & X86_64 |


## 4. 部署前置条件：

1. 在部署前先通过上面的场景表，选择自己要部署的场景，准备好所需服务器。

   - 部署服务器最低配置建议使用：4CPU,16G内存，100G硬盘，单网卡或者多网卡。
   - 根据需求准备服务器：
       - 做普通测试简单操作可按照最低配置部署成单节点，最少需要一台服务器。
       - 现实环境是中心和边缘分开部署，中心（deploy节点，master节点，worker节点）三台服务器，边缘最少一个，最少需要4台服务器。

2. 在准备好的服务器上安装Ubuntu 18.04操作系统(ububntu 18.04是经过安装测试的版本)。

3. 下载离线安装程序，[http://release.edgegallery.org/](http://release.edgegallery.org)，选择对应模式和架构的ansible-latest.tar.gz离线包。

5. 该安装包里已经包含kubernetes、Docker安装程序，按照下面流程安装EdgeGallery时会自动先安装kubernetes。

## 5. 部署流程演示图：

![输入图片说明](https://images.gitee.com/uploads/images/2020/1027/174217_3eb4e54f_8040887.png "屏幕截图.png")


## 6. edgegallery部署

安装程序如安装场景表中所列，支持单节点和多节点安装edgegallery,以下是各个场景下安装步骤:

  edgegallery版本更新后PORTAL_IP在env.sh脚本中也可以添加，edgegallery场景部署中PORTAL_IP作为门户网址访问使用，通常我们使用的是 
  CONTROLLER_MASTER_IPS地址；在使用双网卡或网卡的安装时候，DEPLOY_IP,MASTER_IPS，WORKER_IPS一般使用的是局域网IP地址，PORTAL_IP
  可以使用公网IP作为外部地址。
 

### 一、单节点安装edgegallery场景


 **1.edgegallery部署：** 


### 二、多节点部署edgegallery场景

 **-  多节点安装需要配置ssh无密登录：** 

 1）在deploy节点生产密钥：

    ssh-keygen     //生成密钥，指令执行过程中凡是需要输入的地方直接按回车建就行

 2）在deploy节点将生成的id_rsa.pub文件copy到master和worker节点：

    scp /root/.ssh/id_rsa.pub  (master IP):/root/.ssh
      
    scp /root/.ssh/id_rsa.pub  (worker IP):/root/.ssh
      
 3）分别在deploy，master，worker节点执行免密：

 **1.edgegallery部署**     


###  三.Kubernetes部署


该安装程序还提供了通过在env.sh中设置env变量，仅部署kubernetes的选项：

 **1.单节点部署kubernetes** 


#### **卸载**

在安装过程中使用相同的env.sh，source env.sh。然后按照以下步骤进行卸载
