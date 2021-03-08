# EdgeGallery Ansible离线安装指导


EdgeGallery离线安装是为单机环境提供的安装方式，便于各种只有局域网无公网环境进行EdgeGallery安装。

与在线部署一致，离线部署也是基于Ubuntu系统，Kubernetes，支持x86_64和ARM64体系结构。

## 1. 部署依赖组件及版本


| Module     | Version | Arch            |
|------------|---------|-----------------|
| Ubuntu     | 18.04   | ARM 64 & X86_64 |
| Docker     | 18.09   | ARM 64 & X86_64 |
| Helm       | 3.2.4   | ARM 64 & X86_64 |
| Kubernetes | 1.18.7  | ARM 64 & X86_64 |
| Ansible    | 2.9.18  | ARM 64 & X86_64 |


## 2. 部署前置条件：

1. 在部署前准备好所需服务器，需在root用户权限下执行部署操作，非root用户暂不支持：

    - 一台master节点：用于部署k8s master node，最低配置建议使用：4CPU,16G内存，100G硬盘，单网卡或者多网卡
    - 一台或多台worker节点：用于部署k8s worker node，最低配置建议使用：4CPU,16G内存，100G硬盘，单网卡或者多网卡，All-in-one（AIO）部署不需要worker节点
    - 一台部署控制节点：若仅用于部署控制，无特殊配置要求；若同时用作master或worker，则需满足上述master或worker的配置要求

2. 在准备好的服务器上安装Ubuntu 18.04操作系统(ububntu 18.04是经过安装测试的版本)

## 3. 部署控制节点配置

登录部署控制节点，做如下操作：

1. 部署控制节点需要安装Ansible工具：

    - 在线安装Ansible：

        ```
        #推荐在python3环境下安装ansible
        apt install -y python3-pip
        pip3 install ansible
        ```

    - 离线安装Ansible（目前离线Ansible安装仅支持X86架构下基于python2.7环境下安装，python3环境以及ARM64架构下的ansible离线安装包后续会提供）：

        - 在可访问互联网的机器上下载[Ansible离线安装包](https://release.edgegallery.org/ansible-offline-install.tar)
        - 拷贝安装包到部署控制节点任意目录，此处假设为/home目录
        - 在部署控制节点上执行以下操作，安装Ansible

            ```
            cd /home
            tar -xvf ansible-offline-install.tar

            # 如果没有python2.7，执行以下脚本安装，如果已有，直接跳到下一步，安装Ansible
            cd /home/ansible-offline/python2.7
            bash python2.7-offline-install.sh

            # 安装Ansible
            cd /home/ansible-offline
            bash ansible-offline-install.sh

            # 查看ansible安装结果
            ansible --version
            ```

2. 配置部署控制节点到master和worker节点的免密登录

    - 需要安装sshpass，若上一步采用的离线安装Ansible，则已包含sshpass安装；若为在线环境，采用如下方式安装：

        ```
        # 查看sshpass是否安装
        sshpass -V

        # 若未安装，则安装sshpass
        apt-get install -y sshpass
        ```

    - 部署控制节点/root/.ssh/目录下需要有id_rsa和id_rsa.pub文件，若没有，执行以下命令，并连按三次Enter键生成：

        ```
        ssh-keygen -t rsa
        ```

    - 逐个节点（所有master和worker节点）执行以下命令，配置部署控制节点免密登录其他节点权限

        ```
        sshpass -p <master-or-worker-node-root-password> ssh-copy-id -o StrictHostKeyChecking=no root@<master-or-worker-node-ip>
        ```


3. 在有互联网访问权限的机器上下载EdgeGallery离线安装包并拷贝至部署控制节点，[http://release.edgegallery.org/](http://release.edgegallery.org)，选择对应模式和架构的ansible-latest.tar.gz离线包。（用于Ansible部署的离线包与之前shell脚本的离线包不同，需要重新下载）
（最近几天的mecm-meo helm charts有问题，导致部署失败，可以暂时[下载3月1日的版本](https://release.edgegallery.org/daily/x86/all/eg-all-amd64-latest-2021-03-01-02-33-39.tar.gz)）进行测试验证。

4. 在有互联网访问权限的机器上下载Ansible离线安装脚本并拷贝至部署控制节点任意目录（假设存放在/home下），脚本在[EG Gitee installer仓库](https://gitee.com/edgegallery/installer)中，存放在[ansible_install目录里](https://gitee.com/edgegallery/installer/tree/master/ansible_install)。


## 4. EdgeGallery部署--裸机部署k8s与EdgeGallery

本安装部署使用EG Ansible部署脚本，可进行IaaS层和PaaS层安装场景操作。支持从裸机进行k8s部署，并部署EG相应模块。若已有k8s，仅需部署EdgeGallery，请参考下一节。

下表中列出当前Ansible脚本提供的一些配置场景模板，可直接使用这些模板进行相应场景的安装与卸载。

| EG_MODE    | NODE_MODE  | install yml                    | uninstall yml                    |
|------------|------------|--------------------------------|----------------------------------|
| all        | aio        | eg_all_aio_install.yml         | eg_all_aio_uninstall.yml         |
|            | muno       | eg_all_muno_install.yml        | eg_all_muno_uninstall.yml        |
| controller | aio        | eg_controller_aio_install.yml  | eg_controller_aio_uninstall.yml  |
|            | muno       | eg_controller_muno_install.yml | eg_controller_muno_uninstall.yml |
| edge       | aio        | eg_edge_aio_install.yml        | eg_edge_aio_uninstall.yml        |
|            | muno       | eg_edge_muno_install.yml       | eg_edge_muno_uninstall.yml       |

 
1. 配置节点信息

请参考/home/installer/ansible_install文件夹里的hosts-aio和hosts-muno进行节点配置。

- 单节点配置，若此部署控制节点也作为master节点，则host-aio保持不变，在localhost即本机部署；若需要在另一节点上进行AIO部署，则将host-aio中的信息改成待部署节点IP，如下所示：

    ```
    # 部署控制节点也是AIO待部署节点
    [master]
    localhost ansible_connection=local

    # 待部署节点是另一台机器，例如IP为192.168.0.110
    [master]
    192.168.0.110
    ```

- 多节点配置，参考/home/installer/ansible_install/hosts-muno文件进行master和worker节点的配置，当前仅支持一台master节点，一台或多台worker节点。部署控制节点也可以作为某一个master或者worker节点。

    ```
    [master]
    192.168.0.110
    [worker]
    192.168.0.111
    192.168.0.112
    ```

2. 全部配置输入参数在文件/home/installer/ansible_install/var.yml中。输入参数请参考以下信息进行配置：

    ```
    # 离线或在线部署，当前仅支持离线部署
    NETWORK_MODE: offline

    # 架构是 amd64 or arm64
    ARCH: amd64

    # 安装EG版本，Ansible脚本目前仅支持安装latest版本，即EG_IMAGE_TAG为latest，HELM_TAG为1.1.0
    EG_IMAGE_TAG: latest
    HELM_TAG: 1.1.0

    # 数据持久化存储，目前仅支持false
    ENABLE_PERSISTENCE: false

    # 若数据持久化为true，则需要提供如下两个变量值
    # NFS_SERVER_IP:
    # NFS_PATH:

    # EG离线安装包在部署控制节点上的绝对路径
    TARBALL_FILE: "/home/eg-all-amd64-latest-2021-03-01-02-33-39.tar.gz"

    # 是否需要拷贝离线包到待安装节点，建议选yes，若待安装节点上已有上述离线安装包的解压文件，置为no可以加快部署速度
    COPY_TAR_TO_TARGET: yes

    # Appstore，developer等页面的访问ip，默认为master节点的私有IP，可在此设置为master节点的公网IP
    # PORTAL_IP: 111.222.333.444

    # 离线安装包在待部署节点上解压后存放的路径
    TARBALL_PATH: /home/edgegallery-offline

    # 是否在安装前或者卸载后删除上述解压后的文件夹
    TARBALL_PATH_CLEANUP: true

    # 如果没有设置，会自动获取待部署节点静态IP对应的网卡名称
    # EG_NODE_EDGE_MP1: eth0
    # EG_NODE_EDGE_MM5: eth0

    # 各模块使用的默认端口，不建议更改，未验证改成其他端口是否能正常工作
    APPSTORE_PORT: 30091
    DEVELOPER_PORT: 30092
    MECM_PORT: 30093
    ATP_PORT: 30094
    USER_MGMT_PORT: 30067
    LAB_PORT: 30096
    ```

3. 执行部署

以下仅以EG_MODE为all，NODE_MODE为aio为例，介绍怎么使用ansible部署，其他模式的部署与此类似，只需要指定相应的inventory文件和执行文件即可。

```
ansible-playbook --inventory hosts-aio eg_all_aio_install.yml
```

## 5. EdgeGallery部署--已有k8s，仅部署EdgeGallery

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

## 6. EdgeGallery卸载

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
ansible-playbook --inventory hosts-muno eg_all_muno_uninstall.yml
```