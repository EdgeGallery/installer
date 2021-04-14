# EdgeGallery Ansible离线安装指导


EdgeGallery离线安装是为单机环境提供的安装方式，便于各种只有局域网无公网环境进行Kubernetes与EdgeGallery安装。

与在线部署一致，离线部署也是基于Ubuntu系统，Kubernetes，支持x86_64和ARM64架构。

## 1. 节点设置与各节点依赖组件及版本

  EdgeGallery支持多节点部署与单节点（All-In-One）部署两种模式。

### 1.1 单节点部署（AIO） 

1. 一个部署控制节点

    部署控制节点建议选择有互联网访问权限的机器，便于进行Python与Ansible安装，以及下载EdgeGallery离线安装包。

    部署控制节点需预安装如下依赖组件，若部署控制节点无互联网访问权限，可以参考下一节内容进行Ansible的离线安装。

    以下版本为经过开发与测试验证的可使用版本，推荐使用，其他版本未经验证。

    | Module     | Version | Arch            |
    |------------|---------|-----------------|
    | Ubuntu     | 18.04   | ARM 64 & X86_64 |
    | Python     | 3.6.9   | ARM 64 & X86_64 |
    | pip3       | 9.0.1   | ARM 64 & X86_64 |
    | Ansible    | 2.10.7  | ARM 64 & X86_64 |

2. 一个待部署节点

    该部署节点除操作系统ububntu 18.04外，无需进行其他任何安装操作。节点最低配置建议使用：

    - 4CPU
    - 16G内存
    - 100G硬盘
    - 单网卡或者多网卡。

    待部署节点与部署控制节点可以为同一节点。

### 1.2 多节点部署

1. 一个部署控制节点

    多节点部署控制节点的要求与单节点部署控制节点要求一致。一个部署控制节点可以同时控制多组待部署节点进行k8s以及EdgeGallery平台部署。

2. 多个待部署节点

    待部署节点分为一个Master节点和一个或多个Worker节点。节点要求与单节点部署要求一致。

## 2. 部署控制节点配置

  本文所涉及的所有操作均是在部署控制节点进行，整个部署过程， **无需** 登录待部署节点进行任何操作。

### 2.1 登录部署控制节点

  部署控制节点已提前安装好Ubuntu 18.04操作系统，python3.6与pip3。

### 2.2 部署控制节点需要安装Ansible工具：

  - 在线安装Ansible：

      ```
      #推荐在python3环境下安装ansible
      apt install -y python3-pip
      pip3 install ansible
      ```

  - 离线安装Ansible：

      1. 在可访问互联网的机器上下载[ _X86 Ansible离线安装包_ ](https://edgegallery.obs.cn-east-3.myhuaweicloud.com/ansible-offline-install-python3-x86.tar.gz)或者[ _ARM64 Ansible离线安装包_  ](https://edgegallery.obs.cn-east-3.myhuaweicloud.com/ansible-offline-install-python3-arm64.tar.gz)
      2. 拷贝安装包到部署控制节点任意目录，此处假设下载的是x86的安装包，拷贝到部署控制节点的/home目录
      3. 在部署控制节点上执行以下操作，安装Ansible

            ```
            cd /home
            tar -xvf ansible-offline-install-python3-x86.tar.gz

            # 安装Ansible
            pip3 install -f ansible-offline-install-python3-x86 --no-index ansible

            # 查看ansible安装结果
            ansible --version
            ```

### 2.3 下载EdgeGallery离线安装包

EdgeGallery的所有离线安装包均可在EdgeGallery官网进行下载。请[点击进入官网](https://www.edgegallery.org/)，选择对应架构（x86或arm64）下的边缘（edge）部署、中心（controller）部署或边缘+中心（all）部署对应的离线安装包。

本指导以x86-all为例，介绍如何在x86环境下进行EdgeGallery的单节点与多节点部署。

1. 在有互联网访问权限的机器上[ _下载EdgeGallery中心+边缘的x86架构离线包_ ](https://edgegallery.obs.cn-east-3.myhuaweicloud.com/releases/v1.1/x86/EdgeGallery-v1.1-all-x86.tar.gz)，拷贝到部署控制节点上，假设为/home目录。登录部署控制节点，解压EG离线安装包。

    ```
    cd /home
    tar -xvf EdgeGallery-v1.1-all-x86.tar.gz
    ```

2. 配置从部署控制节点到master和worker节点的ssh免密登录

    2.1. 需要安装sshpass：

    ```
    # 查看sshpass是否安装
    sshpass -V

    # 若未安装，则安装sshpass
    cd /home/ansible-all-x86-latest
    dpkg -i -G -E sshpass_1.06-1_amd64.deb

    # 查看sshpass是否安装成功
    sshpass -V
    ```

    2.2 部署控制节点/root/.ssh/目录下需要有id_rsa和id_rsa.pub文件，若没有，执行以下命令，并连按三次Enter键生成：

    ```
    ssh-keygen -t rsa
    ```

    2.3 在部署控制节点执行以下命令，配置部署控制节点免密登录所有待部署节点权限，依次替换`<master-or-worker-node-ip>`为各节点（Master和Worker）私有IP，`<master-or-worker-node-root-password>`为对应的节点的root用户登录密码, `<ssh-port>`为ssh登录的端口，默认为22。

    ```
    sshpass -p <master-or-worker-node-root-password> ssh-copy-id -p <ssh-port> -o StrictHostKeyChecking=no root@<master-or-worker-node-ip>
    ```

## 3. EdgeGallery部署--部署k8s与EdgeGallery

本安装部署使用EG Ansible部署脚本，可进行IaaS层（k8s）和PaaS层（EdgeGallery）安装部署。若已有k8s，仅需部署EdgeGallery，请参考下一节指导。

下表中列出当前Ansible脚本提供的一些配置场景模板，可直接使用离线安装包中的这些模板（在install文件夹下）进行相应场景的安装与卸载。

| EG_MODE    | NODE_MODE  | install yml                    | uninstall yml                    |
|------------|------------|--------------------------------|----------------------------------|
| all        | aio        | eg_all_aio_install.yml         | eg_all_aio_uninstall.yml         |
|            | muno       | eg_all_muno_install.yml        | eg_all_muno_uninstall.yml        |
| controller | aio        | eg_controller_aio_install.yml  | eg_controller_aio_uninstall.yml  |
|            | muno       | eg_controller_muno_install.yml | eg_controller_muno_uninstall.yml |
| edge       | aio        | eg_edge_aio_install.yml        | eg_edge_aio_uninstall.yml        |
|            | muno       | eg_edge_muno_install.yml       | eg_edge_muno_uninstall.yml       |

 
### 3.1. 配置待部署节点信息

请参考部署控制节点的/home/ansible-all-x86-latest/install文件夹里的hosts-aio和hosts-muno进行节点配置。

- 单节点部署配置，将host-aio中的信息改成待部署节点IP，如下所示：

    ```
    [master]
    xxx.xxx.xxx.xxx
    ```

- 多节点部署配置，参考hosts-muno文件进行master和worker节点的配置，当前仅支持一台master节点，一台或多台worker节点。部署控制节点也可以作为某一个master或者worker节点。

    ```
    [master]
    xxx.xxx.xxx.xxx

    [worker]
    xxx.xxx.xxx.xxx
    xxx.xxx.xxx.xxx
    ```

- ssh的端口不是默认的22端口时：

    ```
    [master]
    xxx.xxx.xxx.xxx
    [master:vars]
    ansible_ssh_port=xx

    [worker]
    xxx.xxx.xxx.xxx
    xxx.xxx.xxx.xxx
    [worker:vars]
    ansible_ssh_port=xx
    ```

### 3.2. 部署涉及的参数配置

  部署输入参数在文件/home/ansible-all-x86-latest/install/var.yml中。输入参数请参考以下信息进行配置：

  ```
  # 部署过程中搭建的Harbor服务器的admin用户的密码
  HARBOR_ADMIN_PASSWORD: Harbor@edge

  # Appstore，developer等页面的访问ip，默认为master节点的私有IP，可在此设置为master节点的公网IP
  # PORTAL_IP: 111.222.333.444

  # master节点的网卡名
  # 如果master节点是单网卡，则可以不设置这两个变量，会在部署时自动获取master节点的静态IP对应的网卡名称
  # 如果master节点是多网卡，需要在此设置以下两个变量为不同的两个网卡的名称
  # EG_NODE_EDGE_MP1: eth0
  # EG_NODE_EDGE_MM5: eth0
  ```

### 3.3. 执行部署

执行部署时只需要指定相应的inventory文件（host-aio或host-muno）和模板文件即可。

```
cd /home/ansible-all-x86-latest/install

# 单节点部署
ansible-playbook --inventory hosts-aio eg_all_aio_install.yml

# 多节点部署
ansible-playbook --inventory hosts-muno eg_all_muno_install.yml
```

## 4. EdgeGallery部署--已有k8s，仅部署EdgeGallery

若机器已部署k8s（AIO或者多节点部署均可），则可以直接部署EdgeGallery。以下仅以EG_MODE为all，NODE_MODE为muno为例，介绍如何跳过k8s部署步骤，直接部署EG。

```
---

# IaaS Deployment on Master and Worker Node
- hosts: master
  become: yes
  vars:
    - OPERATION: install
    - EG_MODE: all
    - NODE_MODE: muno
    - K8S_NODE_TYPE: master
  vars_files:
    - ./var.yml
    - ./default-var.yml
  roles:
    - init
#    - k8s
    - eg_prepare

- hosts: worker
  become: yes
  vars:
    - OPERATION: install
    - EG_MODE: all
    - NODE_MODE: muno
    - K8S_NODE_TYPE: worker
  vars_files:
    - ./var.yml
    - ./default-var.yml
  roles:
    - init
#    - k8s
    - eg_prepare
```

在上面给出的文件eg_all_muno_install.yml部分内容中，注释掉master和worker的`- k8s`这行，即可采用如下命令部署EG。

```
ansible-playbook --inventory hosts-muno eg_all_muno_install.yml
```

## 5. EdgeGallery卸载

根据具体安装的场景，对应下面表格中的卸载文件，执行以下命令进行卸载。

| EG_MODE    | NODE_MODE  | install yml                    | uninstall yml                    |
|------------|------------|--------------------------------|----------------------------------|
| all        | aio        | eg_all_aio_install.yml         | eg_all_aio_uninstall.yml         |
|            | muno       | eg_all_muno_install.yml        | eg_all_muno_uninstall.yml        |
| controller | aio        | eg_controller_aio_install.yml  | eg_controller_aio_uninstall.yml  |
|            | muno       | eg_controller_muno_install.yml | eg_controller_muno_uninstall.yml |
| edge       | aio        | eg_edge_aio_install.yml        | eg_edge_aio_uninstall.yml        |
|            | muno       | eg_edge_muno_install.yml       | eg_edge_muno_uninstall.yml       |

```
# 单节点部署环境的卸载
ansible-playbook --inventory hosts-aio eg_all_aio_uninstall.yml

# 多节点部署环境的卸载
ansible-playbook --inventory hosts-muno eg_all_muno_uninstall.yml
```

## 6. EdgeGallery用户自定义部署

除以上给出的部署模板，用户也可以进行自定义部署，通过编写部署模板，自定义需要部署的EdgeGallery组件。

用户可参照如下文件eg_all_muno_install.yml进行自定义部署。


```
---

# IaaS Deployment on Master and Worker Node
- hosts: master
  become: yes
  vars:
    - OPERATION: install
    - EG_MODE: all
    - NODE_MODE: muno
    - K8S_NODE_TYPE: master
  vars_files:
    - ./var.yml
    - ./default-var.yml
  roles:
    - init
    - k8s
    - eg_prepare

- hosts: worker
  become: yes
  vars:
    - OPERATION: install
    - EG_MODE: all
    - NODE_MODE: muno
    - K8S_NODE_TYPE: worker
  vars_files:
    - ./var.yml
    - ./default-var.yml
  roles:
    - init
    - k8s
    - eg_prepare

# PaaS Deployment on Master
- hosts: master
  become: yes
  vars:
    - OPERATION: install
    - EG_MODE: all
    - NODE_MODE: muno
    - K8S_NODE_TYPE: master
  vars_files:
    - ./var.yml
    - ./default-var.yml
  roles:
    - mep
    - mecm-mepm
    - user-mgmt
    - mecm-meo
    - mecm-fe
    - appstore
    - developer
    - atp
    - eg_check
```

如上所列，此处以多节点部署为例，指导用户如何进行自定义部署。若待部署环境已部署k8s，则无需重复部署k8s，参考第4节内容进行设置。
本节仅介绍如何自定义EdgeGallery各模块。

- init（ **必选** ）：对离线安装包进行解压操作，并将所需文件传输到各待部署节点进行部署准备工作。
- eg_prepare（ **必选** ）：EG部署前的必要准备工作，会进行一些特殊的网络配置，harbor安装，其他所需资源创建等。
- mep（可选）：与EG的其他模块无特殊依赖关系，可以选择部署或者不部署。
- mecm-mepm（可选）：与EG的其他模块无特殊依赖关系，可以选择部署或者不部署。
- user-mgmt（**必选**）：是以下所有模块的依赖，若部署以下任意模块，需提前部署user-mgmt模块，用户用户管理。
- mecm-meo（可选）：除依赖user-mgmt外，与其他模块无特殊依赖关系。
- mecm-fe（可选）：除依赖user-mgmt外，与其他模块无特殊依赖关系。
- appstore（可选）：除依赖user-mgmt外，与其他模块无特殊依赖关系。
- developer（可选）：除依赖user-mgmt外，与其他模块无特殊依赖关系。
- atp（可选）：除依赖user-mgmt外，与其他模块无特殊依赖关系。
- eg_check（可选）：不依赖任何模块，仅对已安装的模块进行检查，打印前台界面访问IP+Port。

上述列出的所有模块，除init，eg_prepare与user-mgmt是必须的之外，其他均为可选。