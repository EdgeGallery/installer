# EdgeGallery Ansible离线安装指导

EdgeGallery离线安装是为单机环境提供的安装方式，便于各种只有局域网无公网环境进行Kubernetes、k3s与EdgeGallery安装。

与在线部署一致，离线部署也是基于Ubuntu系统，Kubernetes或k3s，支持x86_64和ARM64架构。

## 1. 节点设置与各节点依赖组件及版本

  EdgeGallery支持多节点部署与单节点（All-In-One）部署两种模式。

### 1.1 单节点部署（AIO） 

1. 一个部署控制节点

    部署控制节点建议选择有互联网访问权限的机器，便于进行Python，pip3与Ansible安装，以及下载EdgeGallery离线安装包。

    部署控制节点需预安装如下依赖组件，若部署控制节点无互联网访问权限，可以参考[2.2节进行Ansible的离线安装](#22-部署控制节点需要安装ansible工具)，python与pip3安装请自行安装。

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

    **注：待部署节点与部署控制节点可以为同一节点。** 
 
### 1.2 多节点部署

1. 一个部署控制节点

    多节点部署控制节点的要求与单节点部署控制节点要求一致。一个部署控制节点可以同时控制多组待部署节点进行k8s以及EdgeGallery平台部署。

2. 多个待部署节点

    待部署节点分为一个Master节点与一个或多个（少于12）Worker节点。节点要求与单节点部署要求一致。

## 2. 部署控制节点配置

  本文所涉及的所有操作均是在部署控制节点进行，整个部署过程，**无需**登录待部署节点进行任何操作。

### 2.1 登录部署控制节点

  部署控制节点已提前安装好Ubuntu 18.04操作系统，python3.6与pip3。

### 2.2 部署控制节点需要安装Ansible工具

  - 在线安装Ansible：

      ```
      #推荐在python3环境下安装ansible
      apt install -y python3-pip
      pip3 install ansible
      ```

  - 离线安装Ansible：

      1. 在可访问互联网的机器上下载[ _X86 Ansible离线安装包_ ](https://edgegallery.obs.cn-east-3.myhuaweicloud.com/ansible-offline-install-python3-x86.tar.gz)或者[ _ARM64 Ansible离线安装包_  ](https://edgegallery.obs.cn-east-3.myhuaweicloud.com/ansible-offline-install-python3-arm64.tar.gz)
      2. 拷贝安装包到部署控制节点任意目录，此处假设下载的是x86的Ansible离线安装包，拷贝到部署控制节点的`/home`目录
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

EdgeGallery的所有离线安装包均可在EdgeGallery官网进行下载。请[点击进入官网下载页面](https://www.edgegallery.org/software-download-4/)，选择对应架构（x86或arm64）下的边缘（edge）部署、中心（controller）部署或边缘+中心（all）部署对应的离线安装包。

本指导以x86-all为例，介绍如何在x86环境下进行EdgeGallery的单节点与多节点部署。

1. 在有互联网访问权限的机器上下载EdgeGallery中心+边缘的x86架构离线包，拷贝到部署控制节点上，假设为`/home`目录。登录部署控制节点，解压EG离线安装包。

    ```
    cd /home
    tar -xvf EdgeGallery-v1.3.0-all-x86.tar.gz
    ```

2. 配置从部署控制节点到master和worker节点的ssh免密登录

    2.1. 需要安装sshpass：

    ```
    # 查看sshpass是否安装
    sshpass -V

    # 若未安装，则安装sshpass
    cd /home/EdgeGallery-v1.3.0-all-x86
    dpkg -i -G -E sshpass_1.06-1_amd64.deb

    # 查看sshpass是否安装成功
    sshpass -V
    ```

    2.2 部署控制节点`/root/.ssh/`目录下需要有`id_rsa`和`id_rsa.pub`文件，若没有，执行以下命令，并连按三次Enter键生成：

    ```
    ssh-keygen -t rsa
    ```

    2.3 在部署控制节点执行以下命令，配置部署控制节点免密登录所有待部署节点权限，依次替换`<master-or-worker-node-ip>`为各节点（Master和Worker）私有IP，`<master-or-worker-node-root-password>`为对应的节点的root用户登录密码, `<ssh-port>`为ssh登录的端口，默认为22。

    ```
    sshpass -p <master-or-worker-node-root-password> ssh-copy-id -p <ssh-port> -o StrictHostKeyChecking=no root@<master-or-worker-node-ip>
    ```

## 3. EdgeGallery部署

本安装部署使用EG Ansible部署脚本，可进行IaaS层（k8s或k3s）和PaaS层（EdgeGallery）安装部署。

其中PaaS层部署中会进行Harbor安装，当前仅支持x86_64架构，本部署过程会自动安装并配置好Harbor，无需额外操作。

但是Harbor当前暂未提供基于ARM64架构的容器镜像，暂不支持在ARM64架构上进行部署。在ARM64架构上部署EG时需要用户在安装前参考[第6节内容手动进行harbor安装](#6-x86机器手动部署harbor)，成功后再进行EG安装。

下表中列出当前Ansible脚本提供的一些配置场景模板，可直接使用离线安装包中的这些模板（在`install`文件夹下）进行相应场景的安装与卸载。

| EG_MODE    | NODE_MODE  | install yml                    | uninstall yml                    |
|------------|------------|--------------------------------|----------------------------------|
| all        | aio        | eg_all_aio_install.yml         | eg_all_aio_uninstall.yml         |
|            | muno       | eg_all_muno_install.yml        | eg_all_muno_uninstall.yml        |
| controller | aio        | eg_controller_aio_install.yml  | eg_controller_aio_uninstall.yml  |
|            | muno       | eg_controller_muno_install.yml | eg_controller_muno_uninstall.yml |
| edge       | aio        | eg_edge_aio_install.yml        | eg_edge_aio_uninstall.yml        |
|            | muno       | eg_edge_muno_install.yml       | eg_edge_muno_uninstall.yml       |

 
### 3.1. 配置待部署节点信息

请参考部署控制节点的`/home/EdgeGallery-v1.3.0-all-x86/install`文件夹里的`hosts-aio`和`hosts-muno`进行节点配置。

- 单节点部署配置，将`host-aio`中的信息改成待部署节点IP，如下所示：

    ```
    [master]
    xxx.xxx.xxx.xxx
    ```

- 多节点部署配置，参考`hosts-muno`文件进行master和worker节点的配置，当前仅支持一台master节点，一台或多台worker节点。部署控制节点也可同时作为某一个master或者worker节点。

    ```
    [master]
    xxx.xxx.xxx.xxx

    [worker]
    xxx.xxx.xxx.xxx
    xxx.xxx.xxx.xxx
    ```

- Ansible控制节点与master是同一节点，可以使用localhost替代IP，以加快文件拷贝速度。
    ```
    [master]
    localhost ansible_connection=local
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

- 若默认ssh用户不是root，会提示错误"Timeout (12s) waiting for privilege escalation prompt: "，则需要显示指定ssh的用户为root：

    ```
    [master]
    xxx.xxx.xxx.xxx
    [master:vars]
    ansible_ssh_port=xx
    ansible_ssh_user=root

    [worker]
    xxx.xxx.xxx.xxx
    xxx.xxx.xxx.xxx
    [worker:vars]
    ansible_ssh_port=xx
    ansible_ssh_user=root
    ```

### 3.2. 部署涉及的参数配置

  部署输入参数在文件`/home/EdgeGallery-v1.3.0-all-x86/install/var.yml`中。输入参数请参考以下信息进行配置：

  ```
  # 设置calico所使用的网卡的匹配模式，如下表示使用名为eth0、eth1等的网卡
  NETWORK_INTERFACE: eth.*

  # 是否需要开启数据持久化，开启后，重新部署EdgeGallery某个模块，可以恢复之前的数据
  # 若基于k3s部署EG，则持久化必须设置成false，当前暂不支持k3s场景下的数据持久化
  ENABLE_PERSISTENCE: true

  # 集群的Master节点的私网IP
  MASTER_IP: xxx.xxx.xxx.xxx

  # Appstore，developer等页面的访问ip，默认为host inventory文件中给出的master节点的IP，可在此设置为master节点的公网IP
  # PORTAL_IP: xxx.xxx.xxx.xxx

  # 中心侧的master节点IP，用于边缘侧的mecm-mepm访问中心侧的file-system使用
  # 如果是边缘和中心部署在同一集群，则不需要提供此IP
  # CONTROLLER_MASTER_IP: xxx.xxx.xxx.xxx

  # master节点的网卡名
  # 如果master节点是单网卡，则可以不设置这两个变量，会在部署时自动获取master节点的静态IP对应的网卡名称
  # 如果master节点是多网卡，需要在此设置以下两个变量为不同的两个网卡的名称
  # EG_NODE_EDGE_MP1: eth0
  # EG_NODE_EDGE_MM5: eth0

  # 是否设置邮箱服务器，设置为false，则无法使用用户登录时的找回密码功能，其他功能无任何影响
  usermgmt_mail_enabled: false
  # 如果上述参数设置为true，则需要给出如下参数值，可根据自己选定的发件邮箱类型，自行搜索如何开启对应邮箱SMTP服务并获取如下值
  # usermgmt_mail_host: xxxxx
  # usermgmt_mail_port: xxxxx
  # usermgmt_mail_sender: xxxxx
  # usermgmt_mail_authcode: xxxxx

  ```

### 3.3. 部署涉及的密码配置

  部署所需密码在文件`/home/EdgeGallery-v1.3.0-all-x86/install/password-var.yml`中。 **部署脚本自身不提供密码默认值，需要用户在安装前自行设定密码值。密码必须同时使用大小写字母、数字和特殊符号组合，长度不小于8位，否则会因为密码复杂度无法满足要求而造成部署失败。** 

  ```
  # 部署过程中搭建的Harbor服务器的admin用户的密码，不提供默认值，必须由用户自行设定
  # x86环境为用户自行设置的密码，后续会使用该密码自动部署Harbor，用户可用该密码登录Harbor
  # arm64环境为用户在另一台x86上预先安装的Harbor的密码，后续会使用该密码连接预先安装的Harbor
  HARBOR_ADMIN_PASSWORD: xxxxx

  # 部署过程中涉及的所有postgres数据库密码，不提供默认值，必须由用户自行设定
  postgresPassword: xxxxx

  # 部署过程中涉及的所有用户信息鉴权的密码，不提供默认值，必须由用户自行设定
  oauth2ClientPassword: xxxxx

  # user-mgmt模块涉及的redis密码，不提供默认值，必须由用户自行设定
  userMgmtRedisPassword: xxxxx

  # 所有用到的证书生成时使用的密码
  certPassword: xxxxx
  ```

### 3.4. 执行部署

执行部署时只需要指定相应的inventory文件（`host-aio`或`host-muno`）和模板文件即可。

```
cd /home/EdgeGallery-v1.3.0-all-x86/install

# 单节点部署
ansible-playbook --inventory hosts-aio eg_all_aio_install.yml

# 多节点部署
ansible-playbook --inventory hosts-muno eg_all_muno_install.yml
```

## 4. EdgeGallery卸载

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

## 5. EdgeGallery用户自定义部署

除以上给出的部署模板，用户也可以进行自定义部署，以满足更多、更灵活的个性化需求。通过添加选项`--skip-tags`和`--tags`到`ansible-playbook`命令行，自定义需要跳过或部署的EdgeGallery组件。
如下命令表示进行EG的多节点部署，但是跳过其中的mep与mecm-mepm两个模块，部署其他所有模块。

```
ansible-playbook --inventory hosts-muno eg_all_muno_install.yml --skip-tags=mep,mecm-mepm
```

当前EG部署涉及的所有模块如下所示，用户可以根据需要选择其中的多个模块进行自定义部署。

- init（ **必选** ）：对离线安装包进行解压操作，并将所需文件传输到各待部署节点进行部署准备工作。
- k8s（可选）：k8s与k3s二选一即可
- k3s（可选）：k8s与k3s二选一即可
- eg_prepare（ **必选** ）：EG部署前的必要准备工作，会进行一些特殊的网络配置，harbor安装，其他所需资源创建等。
- mep（**必选**）：与EG的其他模块无特殊依赖关系，可以选择部署或者不部署。
- mecm-mepm（可选）：除依赖mep外，与其他模块无特殊依赖关系。
- user-mgmt（**必选**）：是以下所有模块的依赖，若部署以下任意模块，需提前部署user-mgmt模块(用户管理)。
- mecm-meo（可选）：除依赖user-mgmt外，与其他模块无特殊依赖关系。
- mecm-fe（可选）：除依赖user-mgmt外，与其他模块无特殊依赖关系。
- appstore（可选）：除依赖user-mgmt外，与其他模块无特殊依赖关系。
- developer（可选）：除依赖user-mgmt外，与其他模块无特殊依赖关系。
- atp（可选）：除依赖user-mgmt外，与其他模块无特殊依赖关系。
- eg_check（可选）：不依赖任何模块，仅对已安装的模块进行检查，打印前台界面访问IP+Port。

上述列出的所有模块，除init，eg_prepare，mep与mecm-mepm之外，其他均为可选。其中mep是边缘侧必选模块，user-mgmt是中心侧必选模块。

## 6. x86机器手动部署Harbor

当需要将EG部署在ARM64架构机器上时，由于Harbor本身当前并未支持ARM64架构部署，所以需要先在一台x86_64机器上手动部署Harbor，之后再在ARM64架构机器上部署EG。

### 6.1 在x86机器上部署Harbor

1. 安装docker与docker-compose，Harbor安装是依赖docker-compose方式的

2. 配置`/etc/docker/daemon.json`，新增如下字段，其中`xxx.xxx.xxx.xxx`为本x86_64机器的私有或公网IP，需要与EG所在机器互通，若无该文件，需新建

    ```
    {
        "insecure-registries" : ["xxx.xxx.xxx.xxx"]
    }
    ```

3. 重启docker服务

    ```
    systemctl restart docker.service
    ```

4. [点击下载Harbor安装包](https://edgegallery.obs.cn-east-3.myhuaweicloud.com/harbor.tar.gz)，放在x86_64机器的`/home`目录

5. 安装Harbor，其中`xxx.xxx.xxx.xxx`与第2步相同，`<password>`为用户设置的harbor admin登录密码，其他命令直接拷贝即可

    ```
    cd /root
    openssl rand -writerand .rnd

    cd /home
    mkdir harbor
    tar -xvf harbor.tar.gz -C harbor

    export HARBOR_ROOT=/home/harbor
    export HARBOR_DATA_VOLUME=/root/harbor/data_volume
    export HARBOR_IP=xxx.xxx.xxx.xxx
    export HARBOR_ADMIN_PASSWORD=<password>

    cd $HARBOR_ROOT/cert
    openssl genrsa -out ca.key 4096
    openssl req -x509 -new -nodes -sha512 -days 3650 -subj "/C=CN/ST=Guangzhou/L=Guangzhou/O=example/CN="$HARBOR_IP -key ca.key -out ca.crt
    openssl x509 -inform PEM -in ca.crt -out ca.cert

    mkdir -p /etc/docker/certs.d/$HARBOR_IP:443
    cp $HARBOR_ROOT/cert/ca.cert /etc/docker/certs.d/$HARBOR_IP:443

    sed -i "s/hostname: .*/hostname: $HARBOR_IP/g" $HARBOR_ROOT/harbor.yml
    sed -i "s#certificate: .*#certificate: $HARBOR_ROOT/cert/ca.crt#g" $HARBOR_ROOT/harbor.yml
    sed -i "s#private_key: .*#private_key: $HARBOR_ROOT/cert/ca.key#g" $HARBOR_ROOT/harbor.yml
    sed -i "s#data_volume: .*#data_volume: $HARBOR_DATA_VOLUME#g" $HARBOR_ROOT/harbor.yml
    sed -i "s/harbor_admin_password: .*/harbor_admin_password: $HARBOR_ADMIN_PASSWORD/g" $HARBOR_ROOT/harbor.yml

    cd $HARBOR_ROOT
    bash install.sh
    ```

6. docker登录Harbor，成功登录表示Harbor安装成功，否则表示Harbor安装失败

    ```
    docker login -u admin -p $HARBOR_ADMIN_PASSWORD $HARBOR_IP
    ```

### 6.2 在Ansible控制节点上配置Harbor

  Harbor参数配置在文件`/home/EdgeGallery-v1.3.0-all-x86/install/default-var.yml`中。需要设置文件末尾的HarborIP参数为6.1节中第2步的x86机器的IP：

  ```
  # 如果Harbor是手动部署在本k8s或k3s集群master节点之外的机器，需要设置其IP
  HarborIP: xxx.xxx.xxx.xxx
  ```

### 6.3 在Ansible控制节点上部署EG

  Harbor部署成功后，可回到[第3节继续进行EG的部署](#3-edgegallery部署)。
