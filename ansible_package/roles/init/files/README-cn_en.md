# EdgeGallery AnsibleOffline installation guide


EdgeGalleryOffline installation is an installation method provided for a stand-alone environment，Convenient for various environments with only LAN but no public networkKubernetesversusEdgeGalleryinstallation。

Consistent with online deployment，Offline deployment is also based onUbuntusystem，Kubernetes，stand byx86_64withARM64Architecture。

## 1. Node settings and dependent components and versions of each node

  EdgeGallerySupport multi-node deployment and single node（All-In-One）Deploy two modes。

### 1.1 Single node deployment（AIO） 

1. A deployment control node

    It is recommended to select a machine with Internet access permission for deployment of control nodes，Easy to proceedPythonversusAnsibleinstallation，And downloadEdgeGallery离线installation包。

    The following dependent components need to be pre-installed to deploy the control node，If the deployment control node does not have Internet access rights，You can refer to the next sectionAnsibleOffline installation。

    The following versions are usable versions that have been developed and tested，Recommended Use，Other versions are not verified。

    | Module     | Version | Arch            |
    |------------|---------|-----------------|
    | Ubuntu     | 18.04   | ARM 64 & X86_64 |
    | Python     | 3.6.9   | ARM 64 & X86_64 |
    | pip3       | 9.0.1   | ARM 64 & X86_64 |
    | Ansible    | 2.10.7  | ARM 64 & X86_64 |

2. A node to be deployed

    The deployment node except the operating systemububntu 18.04outer，No need to perform any other installation operations。Recommended minimum node configuration：4CPU，16GRAM，100Ghard disk，Single network card or multiple network cards。

    The node to be deployed and the deployment control node can be the same node。

### 1.2 Multi-node deployment

1. A deployment control node

    The requirements for multi-node deployment control nodes are the same as those for single-node deployment control nodes。One deployment control node can control multiple groups of nodes to be deployed at the same timek8sas well asEdgeGalleryPlatform deployment。

2. Multiple nodes to be deployed

    The nodes to be deployed are divided into oneMasterNode and one or moreWorkernode。node要求与单node部署要求一致。

## 2. Deployment control node configuration

  All operations involved in this article are performed on the deployment control node，The entire deployment process， **No need** Log in to the node to be deployed for any operation。

   **Log in to the deployment control node** （Installed in advanceububntu 18.04operating system，python3.6versuspip3），Do the following：

### 2.1. The deployment control node needs to be installedAnsibletool：

  - Online installationAnsible：

      ```
      #Recommended inpython3Installation in the environmentansible
      apt install -y python3-pip
      pip3 install ansible
      ```

  - Offline installationAnsible：

      1. Download on a machine with internet access[ _X86 AnsibleOffline installation package_ ](https://release.edgegallery.org/ansible-offline-install-python3-x86.tar.gz)or[ _ARM64 AnsibleOffline installation package_  ](https://release.edgegallery.org/ansible-offline-install-python3-arm64.tar.gz)
      2. Copy the installation package to any directory of the deployment control node，It is assumed here that the download isx86Installation package，Copy to the deployment control node/hometable of Contents
      3. Perform the following operations on the deployment control node，installationAnsible

            ```
            cd /home
            tar -xvf ansible-offline-install-python3-x86.tar.gz

            # installationAnsible
            pip3 install -f ansible-offline-install-python3-x86 --no-index ansible

            # ViewansibleInstallation result
            ansible --version
            ```

### 2.2. downloadEdgeGalleryOffline installation package

EdgeGalleryAll of the offline installation packages are available on the official platform[https://release.edgegallery.org/](https://release.edgegallery.org/)Download。Please click to enter[ _Official platform_ ](https://release.edgegallery.org/)，Choose the corresponding architecture（x86orarm64）Lower edge（edge）deploy、center（controller）deployor边缘+center（all）deploy对应的离线安装包。

This guide is based onx86-allAs an example，Introduce how tox86Under the environmentEdgeGallerySingle-node and multi-node deployment。

1. On a machine with internet access[ _downloadEdgeGallerycenter+Marginalx86Architecture offline package_ ](https://release.edgegallery.org/daily/x86/all/ansible-all-x86-latest.tar.gz)，Copy to the deployment control node，Suppose to be/hometable of Contents。Log in to the deployment control node，UnzipEGOffline installation package。

    ```
    cd /home
    tar -xvf ansible-all-x86-latest.tar.gz
    ```

2. Configuration from the deployment control node tomasterwithworkerNodalsshPassword-free login

    2.1. Need to installsshpass：

    ```
    # ViewsshpassWhether to install
    sshpass -V

    # If not installed，Then installsshpass
    cd /home/ansible-all-x86-latest
    dpkg -i -G -E sshpass_1.06-1_amd64.deb

    # ViewsshpassIs the installation successful
    sshpass -V
    ```

    2.2 Deploy the control node/root/.ssh/Need to haveid_rsawithid_rsa.pubfile，If not，Execute the following command，And press it three timesEnterKey generation：

    ```
    ssh-keygen -t rsa
    ```

    2.3 Execute the following command on the deployment control node，Configure deployment control node password-free login to all nodes to be deployed，Replace in turn`<master-or-worker-node-ip>`For each node（MasterwithWorker）privateIP，`<master-or-worker-node-root-password>`For the corresponding noderootUser login password。

    ```
    sshpass -p <master-or-worker-node-root-password> ssh-copy-id -o StrictHostKeyChecking=no root@<master-or-worker-node-ip>
    ```

## 3. EdgeGallerydeploy--deployk8sversusEdgeGallery

This installation and deployment useEG AnsibleDeployment script，Can proceedIaaSFloor（k8s）withPaaSFloor（EdgeGallery）Installation and deployment。If alreadyk8s，Just deployEdgeGallery，Please refer to the next section for guidance。

The following table lists the currentAnsibleSome configuration scenario templates provided by the script，These templates in the offline installation package can be used directly（ininstallUnder folder）Install and uninstall the corresponding scene。

| EG_MODE    | NODE_MODE  | install yml                    | uninstall yml                    |
|------------|------------|--------------------------------|----------------------------------|
| all        | aio        | eg_all_aio_install.yml         | eg_all_aio_uninstall.yml         |
|            | muno       | eg_all_muno_install.yml        | eg_all_muno_uninstall.yml        |
| controller | aio        | eg_controller_aio_install.yml  | eg_controller_aio_uninstall.yml  |
|            | muno       | eg_controller_muno_install.yml | eg_controller_muno_uninstall.yml |
| edge       | aio        | eg_edge_aio_install.yml        | eg_edge_aio_uninstall.yml        |
|            | muno       | eg_edge_muno_install.yml       | eg_edge_muno_uninstall.yml       |

 
### 3.1. Configure node information to be deployed

Please refer to the deployment control node/home/ansible-all-x86-latest/installIn the folderhosts-aiowithhosts-munoPerform node configuration。

- Single node deployment configuration，willhost-aioChange the information in the node to be deployedIP，As follows：

    ```
    # Node to be deployedIPfor192.168.0.110
    [master]
    192.168.0.110
    ```

- Multi-node deployment configuration，referencehosts-munoFile proceedmasterwithworkerNode configuration，Currently only supports onemasternode，One or moreworkernode。部署控制node也可以作为某一个masterorworkernode。

    ```
    [master]
    192.168.0.110
    [worker]
    192.168.0.111
    192.168.0.112
    ```

### 3.2. Parameter configuration involved in deployment

  Deploy input parameters in file/home/ansible-all-x86-latest/install/var.ymlin。Please refer to the following information to configure the input parameters：

  ```
  # Built during deploymentHarborServeradminUser's password
  HARBOR_ADMIN_PASSWORD: Harbor@edge

  # Appstore，developerWait for page visitip，The default ismasterNode privateIP，Can be set here asmasterNode's public networkIP
  # PORTAL_IP: 111.222.333.444

  # If not set，Will automatically get the static state of the node to be deployedIPCorresponding network card name
  # EG_NODE_EDGE_MP1: eth0
  # EG_NODE_EDGE_MM5: eth0
  ```

### 3.3. Perform deployment

You only need to specify the correspondinginventoryfile（host-aioorhost-muno）和模板file即可。

```
cd /home/ansible-all-x86-latest/install

# Single node deployment
ansible-playbook --inventory hosts-aio eg_all_aio_install.yml

# Multi-node deployment
ansible-playbook --inventory hosts-muno eg_all_muno_install.yml
```

## 4. EdgeGallerydeploy--Alreadyk8s，仅deployEdgeGallery

If the machine is deployedk8s（AIOOr multi-node deployment），You can deploy directlyEdgeGallery。The following is onlyEG_MODEforall，NODE_MODEformunofor例，Introduce how to skipk8sDeployment steps，Direct deploymentEG。

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

In the file given aboveeg_all_muno_install.ymlPart of the content，Comment outmasterwithworkerof`- k8s`This line，You can use the following command to deployEG。

```
ansible-playbook --inventory hosts-muno eg_all_muno_install.yml
```

## 5. EdgeGalleryUninstall

According to the specific installation scenario，Correspond to the uninstall file in the table below，Execute the following command to uninstall。

| EG_MODE    | NODE_MODE  | install yml                    | uninstall yml                    |
|------------|------------|--------------------------------|----------------------------------|
| all        | aio        | eg_all_aio_install.yml         | eg_all_aio_uninstall.yml         |
|            | muno       | eg_all_muno_install.yml        | eg_all_muno_uninstall.yml        |
| controller | aio        | eg_controller_aio_install.yml  | eg_controller_aio_uninstall.yml  |
|            | muno       | eg_controller_muno_install.yml | eg_controller_muno_uninstall.yml |
| edge       | aio        | eg_edge_aio_install.yml        | eg_edge_aio_uninstall.yml        |
|            | muno       | eg_edge_muno_install.yml       | eg_edge_muno_uninstall.yml       |

```
# Uninstallation of single node deployment environment
ansible-playbook --inventory hosts-aio eg_all_aio_uninstall.yml

# Uninstallation of multi-node deployment environment
ansible-playbook --inventory hosts-muno eg_all_muno_uninstall.yml
```

## 6. EdgeGalleryUser-defined deployment

In addition to the deployment template given above，Users can also customize deployment，By writing deployment templates，Customize what needs to be deployedEdgeGalleryComponent。

Users can refer to the following documentseg_all_muno_install.ymlMake a custom deployment。


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

As listed above，Take multi-node deployment as an example here，Instruct users how to customize deployment。If the environment to be deployed has been deployedk8s，No need to re-deployk8s，Reference section4Section content to set。
This section only describes how to customizeEdgeGalleryEach module。

- init（ **required** ）：Unzip the offline installation package，And transfer the required files to each node to be deployed for deployment preparation。
- eg_prepare（ **required** ）：EGNecessary preparations before deployment，Will carry out some special network configuration，harborinstallation，Creation of other required resources, etc.。
- mep（Optional）：versusEGNo special dependencies on other modules，You can choose to deploy or not to deploy。
- mecm-mepm（Optional）：versusEGNo special dependencies on other modules，You can choose to deploy or not to deploy。
- user-mgmt（Optional）：Is a dependency of all the following modules，If any of the following modules are deployed，Need to be deployed in advanceuser-mgmtModule，User user management。
- mecm-meo（Optional）：In addition to dependenceuser-mgmtouter，No special dependencies with other modules。
- mecm-fe（Optional）：In addition to dependenceuser-mgmtouter，No special dependencies with other modules。
- appstore（Optional）：In addition to dependenceuser-mgmtouter，No special dependencies with other modules。
- developer（Optional）：In addition to dependenceuser-mgmtouter，No special dependencies with other modules。
- atp（Optional）：In addition to dependenceuser-mgmtouter，No special dependencies with other modules。
- eg_check（Optional）：Does not depend on any modules，Only check the installed modules，Print front-end interface accessIP+Port。

All modules listed above，exceptinitversuseg_prepareIs a must，Others are optional。All elseEGIn the module，exceptuser-mgmtIs outside the dependencies of some modules，The remaining modules can be deployed independently。
