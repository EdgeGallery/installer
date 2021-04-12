# EdgeGallery Ansible Offline Installation

This Guide is for EdgeGallery (EG) offline installation when there is no public network with the environment.

The same as online installation, the offline installation is also based on Ubuntu OS and Kubernetes, supports x86_64 and ARM64 as well.

## 1. The Dependencies and How to Set Nodes

  EdgeGallery supports Multi Node and All-In-One (AIO) deployment now.

### 1.1 AIO Deployment

#### 1.1.1 Need one Ansible controller node

  We suggest you to choose a machine which can access internet as the Ansible controller node,
  that will be helpful for installing Python and Ansible, as well as downloading the EdgeGallery Offline Packages.

  The following components in the table should be installed on Ansible controller node in advance.
  If the Ansible controller node has no internet access, you could refer to next section for
  how to install Ansible offline.

  The follwing versions are the suggested versions which have been proved to work by EG developers and testers.

  | Module     | Version | Arch            |
  |------------|---------|-----------------|
  | Ubuntu     | 18.04   | ARM 64 & X86_64 |
  | Python     | 3.6.9   | ARM 64 & X86_64 |
  | pip3       | 9.0.1   | ARM 64 & X86_64 |
  | Ansible    | 2.10.7  | ARM 64 & X86_64 |

#### 1.1.2. Need One Master Node

  The Master Node should only install Ubuntu 18.04 and with the following hardware resources:

  - 4CPU
  - 16G RAM
  - 100G Storage
  - Single or Multi NIC

  INFO: The Ansible controller node and the Master Node could be the same node.

### 1.2 Multi-Node Deployment

#### 1.2.1 Need one Ansible controller node

  The requirement of the Ansible controller node here are the same as the AIO deployment in the previous section.
  There only need one single Ansible controller node which can work as the control center to
  deploy several k8s clusters and EG PaaS.

#### 1.2.2 Need Several Master and Worker Nodes

  The k8s Cluster could be one Master node (only support one master node now) and several Worker nodes (less than 12).
  And the requirements of these Nodes are all the same as Section 1.1.2.

## 2. How to Config the Ansible Controller Node

  The commands in the following sections are all executed on  **Ansible controller node**  and there is  **no commands** 
  that need to be executed on any other nodes.

### 2.1 Login Ansible controller node

  The Ansible controller node should already install ububntu 18.04, python3.6 and pip3 in advance.

### 2.2 Install Ansible:

  - Ansible Online Installation

      ```
      # Recommend to install Ansible with python3
      apt install -y python3-pip
      pip3 install ansible
      ```

  - Ansible Offline Installation

      1. Download [ _X86 Ansible package_ ](https://edgegallery.obs.cn-east-3.myhuaweicloud.com/ansible-offline-install-python3-x86.tar.gz) or [ _ARM64 Ansible package_  ](https://edgegallery.obs.cn-east-3.myhuaweicloud.com/ansible-offline-install-python3-arm64.tar.gz) on a machine that can access internet.
      2. Copy the package to Ansible controller node, e.g. /home
      3. Do the following commands to install Ansible

            ```
            # Here take the x86 as example
            cd /home
            tar -xvf ansible-offline-install-python3-x86.tar.gz

            # Install Ansible
            pip3 install -f ansible-offline-install-python3-x86 --no-index ansible

            # Check Whether Ansible installed successfully
            ansible --version
            ```

### 2.3 Download EdgeGallery Offline Package

All EG offline packages could be found on Edgegallery Home Page.
Users need to choose the package with exact architecture (x86 or arm64) and EG Mode (edge, controller or all).

The following guide takes x86 architecture and "all" mode (edge + controller) as the example to introduce
how to deploy EG in single node and multi nodes cases.

1. [ _Download EG offline package ("all" mode on x86)_ ](https://edgegallery.obs.cn-east-3.myhuaweicloud.com/releases/v1.1/x86/EdgeGallery-v1.1-all-x86.tar.gz)
    on a machine that can access internet, and copy it to Ansible controller node, e.g. /home

    ```
    cd /home
    tar -xvf ansible-all-x86-latest.tar.gz
    ```

2. Set password-less ssh from Ansible controller node to other nodes

    2.1. sshpass required：

    ```
    # Check whether sshpass installed
    sshpass -V

    # If not, install sshpass
    cd /home/ansible-all-x86-latest
    dpkg -i -G -E sshpass_1.06-1_amd64.deb

    # Check whether sshpass installed successfully
    sshpass -V
    ```

    2.2 There should be id_rsa and id_rsa.pub under /root/.ssh/, if not, do the following to generate them:

    ```
    ssh-keygen -t rsa
    ```

    2.3 Do the following to set the password-less ssh, execute the command several times for all master and worker nodes
        one by one where `<master-or-worker-node-ip>` is the private IP and `<master-or-worker-node-root-password>` is
        the password of root user of that node.

    ```
    sshpass -p <master-or-worker-node-root-password> ssh-copy-id -o StrictHostKeyChecking=no root@<master-or-worker-node-ip>
    ```

## 3. EdgeGallery Deployment -- Deploy Both k8s and EdgeGallery

Currently, the Ansible scripts support deploying both IaaS (k8s) and PaaS (EG). If the k8s cluster has already been
deployed, then you can jump to the next section for deploying EG only.

The following table gives some deployment scenarios pre-defineded in the EG offline package (under `/home/ansible-all-x86-latest/install/` directory),
and you can use them directly to deploy EG.


| EG_MODE    | NODE_MODE  | install yml                    | uninstall yml                    |
|------------|------------|--------------------------------|----------------------------------|
| all        | aio        | eg_all_aio_install.yml         | eg_all_aio_uninstall.yml         |
|            | muno       | eg_all_muno_install.yml        | eg_all_muno_uninstall.yml        |
| controller | aio        | eg_controller_aio_install.yml  | eg_controller_aio_uninstall.yml  |
|            | muno       | eg_controller_muno_install.yml | eg_controller_muno_uninstall.yml |
| edge       | aio        | eg_edge_aio_install.yml        | eg_edge_aio_uninstall.yml        |
|            | muno       | eg_edge_muno_install.yml       | eg_edge_muno_uninstall.yml       |

 
### 3.1. How to config Ansible Inventory

Ansible inventory is used to set the master and worker nodes info which used to ssh to these nodes by Ansible.
Please refer to the files, `hosts-aio` and `hosts-muno` under /home/ansible-all-x86-latest/install to do the ansible inventory configuration.

- AIO Inventory, replace the exactly master node IP in file `host-aio`:

    ```
    [master]
    xxx.xxx.xxx.xxx
    ```

- Multi Node Inventory, refer to file `hosts-muno` and replace the master and worker nodes IPs:

    ```
    [master]
    xxx.xxx.xxx.xxx

    [worker]
    xxx.xxx.xxx.xxx
    xxx.xxx.xxx.xxx
    ```

- SSH port is not the default value 22, should add some more info about the ssh port

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

NOTE: Release v1.1 only supports one master and several worker (less than 12) nodes.
Also the Ansible controller node can also act as one of the master or worker node.

### 3.2. How to Set the Parameters

  All parameters that user could set are in file /home/ansible-all-x86-latest/install/var.yml.

  ```
  # Set the Password of Harbor admin account
  HARBOR_ADMIN_PASSWORD: Harbor@edge

  # ip for portals, will be set to private IP of master node default or reset it to be the public IP of master node here
  # PORTAL_IP: xxx.xxx.xxx.xxx

  # NIC name of master node
  # If master node is with single NIC, not need to set it here and will get the default NIC name during the run time
  # If master node is with multiple NICs, should set it here to be 2 different NICs
  # EG_NODE_EDGE_MP1: eth0
  # EG_NODE_EDGE_MM5: eth0
  ```

### 3.3. How to Deploy

It only needs to specify the inventory file (host-aio or host-muno) and the scenario file when deploying.

```
cd /home/ansible-all-x86-latest/install

# AIO Deployment
ansible-playbook --inventory hosts-aio eg_all_aio_install.yml

# Multi Node Deployment
ansible-playbook --inventory hosts-muno eg_all_muno_install.yml
```

## 4. EdgeGallery Deployment -- Deploy EdgeGallery only

If the k8s cluster is already there, you can deploy EG directly. Here take the multi node deploy
with 'all' EG mode as the example to introduce how to skip the k8s deployment and directly deploy EG.

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

As showing in the previous file, it only needs to comment out 2 lines of `- k8s`, then the k8s deployment has been skipped.
After that, use the same command to deploy EG as the previous section.

```
ansible-playbook --inventory hosts-muno eg_all_muno_install.yml
```

## 5. Uninstall EdgeGallery

Please refer to the following table to find out which uninstall scenario file should be chosen to do the uninstall operation
according to the install scenario file chosen before.

| EG_MODE    | NODE_MODE  | install yml                    | uninstall yml                    |
|------------|------------|--------------------------------|----------------------------------|
| all        | aio        | eg_all_aio_install.yml         | eg_all_aio_uninstall.yml         |
|            | muno       | eg_all_muno_install.yml        | eg_all_muno_uninstall.yml        |
| controller | aio        | eg_controller_aio_install.yml  | eg_controller_aio_uninstall.yml  |
|            | muno       | eg_controller_muno_install.yml | eg_controller_muno_uninstall.yml |
| edge       | aio        | eg_edge_aio_install.yml        | eg_edge_aio_uninstall.yml        |
|            | muno       | eg_edge_muno_install.yml       | eg_edge_muno_uninstall.yml       |

```
# Uninstall AIO Deployment
ansible-playbook --inventory hosts-aio eg_all_aio_uninstall.yml

# Uninstall Multi Node Deployment
ansible-playbook --inventory hosts-muno eg_all_muno_uninstall.yml
```

## 6. How to install EdgeGallery with self-defined Scenario File

Besides using the scenario files given in the offline packages, users can self-define the scenario
files to decide which modules you want to deploy and which you don't.

You can refer to the following eg_all_muno_install.yml to learn how to self-define the scenario file.

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

The file is deploying multiple node cluster with both edge and controller. The self-defined deployment
of EG only are introduced in Section 4. Here only introduce how to self-define EG modules.

Besides of k8s, there are 11 parts related to the EG deployment. Some of them are setup modules and others are EG modules.

- init (**mandatory**): Unarchive EG offline package and copy related files to master or worker nodes
- eg_prepare (**mandatory**): Setup for deploying EG which do some network configuration, install Harbor, create some k8s resources et al.
- mep (optional): Independent with other EG modules, could deploy or not deploy
- mecm-mepm (optional): Independent with other EG modules, could deploy or not deploy
- user-mgmt (**mandatory**): The dependency module of all the following modules which used to do the User Management for all web portals
- mecm-meo (optional): Independent with other EG modules except the user-mgmt
- mecm-fe (optional): Independent with other EG modules except the user-mgmt
- appstore (optional): Independent with other EG modules except the user-mgmt
- developer (optional): Independent with other EG modules except the user-mgmt
- atp (optional): Independent with other EG modules except the user-mgmt
- eg_check (optional): Independent with all other EG modules and only check the deployed modules and print the Web portal URL

In summary, all modules are optional except init, eg_prepare and user-mgmt.