# EdgeGallery Ansible Offline Installation

This guide is for EdgeGallery (EG) offline installation when there is no public network with the environment.

The same as online installation, the offline installation is also based on Ubuntu OS and Kubernetes/k3s, supports x86_64 and ARM64 as well.

## 1. The Dependencies and How to Set Nodes

  EdgeGallery supports Multi Node and All-In-One (AIO) deployment now.

### 1.1 AIO Deployment

#### 1.1.1 Need One Ansible Controller Node

  There is a kindly suggestion to choose a machine which can access Internet as the Ansible controller node,
  that will be helpful for installing Python, pip3 and Ansible, as well as downloading the EdgeGallery Offline Packages.

  The components in the following table should be installed on Ansible controller node in advance.
  If the Ansible controller node has no Internet access, you could refer to [section 2.2 for
  how to install Ansible offline](#22-install-ansible).

  The following versions are the suggested ones which have been proved to work well by EG developers and testers.

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

   **INFO: The Ansible controller node and the Master Node could be the same node.** 

### 1.2 Multi-Node Deployment

#### 1.2.1 Need One Ansible Controller Node

  The requirements of the Ansible controller node here are the same as the AIO deployment in the previous section.
  There only need one single Ansible controller node which can work as the control center to
  deploy several k8s clusters and EG PaaS.

#### 1.2.2 Need Several Master and Worker Nodes

  The k8s Cluster could be one Master node (only support one master node now) and several Worker nodes (less than 12).
  And the requirements of these Nodes are all the same as Section 1.1.2.

## 2. How to Config the Ansible Controller Node

  The commands in the following sections are all executed on  **Ansible controller node**  and there is  **no commands** 
  that need to be executed on any k8s/k3s nodes.

### 2.1 Login Ansible Controller Node

  The Ansible controller node should already install ububntu 18.04, python3.6 and pip3 in advance.

### 2.2 Install Ansible

  - Ansible Online Installation

      ```
      # Recommend to install Ansible with python3
      apt install -y python3-pip
      pip3 install ansible
      ```

  - Ansible Offline Installation

      1. Download [ _X86 Ansible package_ ](https://edgegallery.obs.cn-east-3.myhuaweicloud.com/ansible-offline-install-python3-x86.tar.gz) or [ _ARM64 Ansible package_  ](https://edgegallery.obs.cn-east-3.myhuaweicloud.com/ansible-offline-install-python3-arm64.tar.gz) on a machine that can access Internet.
      2. Copy the package to Ansible controller node, e.g. `/home`
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

All EG offline packages could be found on [EdgeGallery Download Page](https://www.edgegallery.org/en/downloaden/).
Users need to choose the package with exact architecture (x86 or arm64) and EG Mode (edge, controller or all).

The following guide takes x86 architecture and "all" mode (edge + controller) as the example to introduce
how to deploy EG in both single node and multi nodes cases.

1. Download EG offline package "all" mode on x86 on a machine that can access Internet, and copy it to Ansible controller node, e.g. `/home`

    ```
    cd /home
    tar -xvf EdgeGallery-v1.3.0-all-x86.tar.gz
    ```

2. Set password-less ssh from Ansible controller node to other nodes

    2.1. sshpass required：

    ```
    # Check whether sshpass installed
    sshpass -V

    # If not, install sshpass
    cd /home/EdgeGallery-v1.3.0-all-x86
    dpkg -i -G -E sshpass_1.06-1_amd64.deb

    # Check whether sshpass installed successfully
    sshpass -V
    ```

    2.2 There should be `id_rsa` and `id_rsa.pub` under `/root/.ssh/`, if not, do the following to generate them:

    ```
    ssh-keygen -t rsa
    ```

    2.3 Do the following to set the password-less ssh, execute the command several times for all master and worker nodes
        one by one where `<master-or-worker-node-ip>` is the private IP, `<master-or-worker-node-root-password>` is
        the password of root user of that node and `<ssh-port>` is the port used to ssh which default is 22.

    ```
    sshpass -p <master-or-worker-node-root-password> ssh-copy-id -p <ssh-port> -o StrictHostKeyChecking=no root@<master-or-worker-node-ip>
    ```

## 3. EdgeGallery Deployment

Currently, the Ansible scripts support deploying both IaaS (k8s or k3s) and PaaS (EG).

The Harbor deployment in role `eg_prepare` could only work on x86 machines, and it will be deployed automatically
during the EG deployment on x86.

However, when deploying on arm64 machines, you should prepare a x86 machine and install Harbor on it manually before
deploying EG on those arm64 machines. That's because Harbor hasn't provided arm64 Docker images now.
Please [refer to Section 6 to install Harbor manually](#6-how-to-install-harbor-manually-on-x86) before deploying EG.

The following table gives all deployment scenarios pre-defineded in the EG offline package (under `/home/EdgeGallery-v1.3.0-all-x86/install/` directory),
and you can use them directly to deploy EG.


| EG_MODE    | NODE_MODE  | install yml                    | uninstall yml                    |
|------------|------------|--------------------------------|----------------------------------|
| all        | aio        | eg_all_aio_install.yml         | eg_all_aio_uninstall.yml         |
|            | muno       | eg_all_muno_install.yml        | eg_all_muno_uninstall.yml        |
| controller | aio        | eg_controller_aio_install.yml  | eg_controller_aio_uninstall.yml  |
|            | muno       | eg_controller_muno_install.yml | eg_controller_muno_uninstall.yml |
| edge       | aio        | eg_edge_aio_install.yml        | eg_edge_aio_uninstall.yml        |
|            | muno       | eg_edge_muno_install.yml       | eg_edge_muno_uninstall.yml       |

 
### 3.1. How to Config Ansible Inventory

Ansible inventory is used to set the master and worker nodes info which used to ssh to these nodes by Ansible.
Please refer to the files, `hosts-aio` and `hosts-muno` under `/home/EdgeGallery-v1.3.0-all-x86/install`, to do the Ansible inventory configuration.

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

- SSH user must be root, if failed with the log "Timeout (12s) waiting for privilege escalation prompt: ", then need to set the user to be root.

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

NOTE: only supports one master and several worker (less than 12) nodes.
Also the Ansible controller node can also act as one of the master or worker node.

### 3.2. How to Set the Parameters

  All parameters that user could set are in file `/home/EdgeGallery-v1.3.0-all-x86/install/var.yml`.

  ```
  # Set the regex name of the network interface for calico
  NETWORK_INTERFACE: eth.*

  # Could be true or false
  # true: Deploy k8s NFS Server to keep the persistence of all pods' data
  # false: No need to keep the persistence of all pods' data
  # for k3s, could only be false because k3s doesn't support persistence storage now
  ENABLE_PERSISTENCE: true

  # ip for portals, will be set to private IP of master node default or reset it to be the public IP of master node here
  # PORTAL_IP: xxx.xxx.xxx.xxx

  # IP of the Controller master which is used for Edge to connect
  # If you deploy Controller and Edge together in one cluster, then ther is no need to set this param
  # CONTROLLER_MASTER_IP: xxx.xxx.xxx.xxx

  # NIC name of master node
  # If master node is with single NIC, not need to set it here and will get the default NIC name during the run time
  # If master node is with multiple NICs, should set it here to be 2 different NICs
  # EG_NODE_EDGE_MP1: eth0
  # EG_NODE_EDGE_MM5: eth0

  # Email Server Config for User Mgmt
  usermgmt_mail_enabled: false
  # If usermgmt_mail_enabled is true, then the following 4 params need to be set
  # usermgmt_mail_host: xxxxx
  # usermgmt_mail_port: xxxxx
  # usermgmt_mail_sender: xxxxx
  # usermgmt_mail_authcode: xxxxx
  ```

### 3.3. How to Set the Passwords

  All passwords needed are in file `/home/EdgeGallery-v1.3.0-all-x86/install/password-var.yml`. The Ansible scripts
  don't provide any default password now, and  **all passwords are needed to be given by users before deploying.
  All passwords must include capital letters, lowercase letters, numbers and special characters and whose
  length must be no less than 8 characters. Otherwise, the deployment will failed because of these simple passwords.** 

  ```
  # Set the Password of Harbor admin account, no default value, must set by users here
  HARBOR_ADMIN_PASSWORD: xxxxx

  # postgresPassword is used for all postgres DB of all roles, no default value, must set by users here
  postgresPassword: xxxxx

  # oauth2ClientPassword is used for user mgmt, no default value, must set by users here
  oauth2ClientPassword: xxxxx

  # Redis Password used by user mgmt, no default value, must set by users here
  userMgmtRedisPassword: xxxxx
  ```

### 3.4. How to Deploy

It only needs to specify the inventory file (`host-aio` or `host-muno`) and the scenario file when deploying.

```
cd /home/EdgeGallery-v1.3.0-all-x86/install

# AIO Deployment
ansible-playbook --inventory hosts-aio eg_all_aio_install.yml

# Multi Node Deployment
ansible-playbook --inventory hosts-muno eg_all_muno_install.yml
```

## 4. Uninstall EdgeGallery

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

## 5. How to Install EdgeGallery with Self-defined Demand

Besides using the scenario files given in the offline packages, users can choose which roles to deploy and which don't
with the `ansible-playbook` command lines by using options `--tags` and `--skip-tags`.

The following commands skip roles mep and mecm-mepm when deploying multi-node EG with all (edge+controller) mode. 

```
ansible-playbook --inventory hosts-muno eg_all_muno_install.yml --skip-tags=mep,mecm-mepm
```

All roles in the deployment are list below. Users could choose some of them according to your own demand.

- init (**mandatory**): Unarchive EG offline package and copy related files to master or worker nodes
- k8s (optional): choose either k8s or k3s
- k3s (optional): choose either k8s or k3s
- eg_prepare (**mandatory**): Setup for deploying EG which do some network configuration, install Harbor, create some k8s resources et al.
- mep (**mandatory**): Independent with other EG modules, could deploy or not deploy
- mecm-mepm (optional): Independent with other EG modules except mep
- user-mgmt (**mandatory**): The dependency module of all the following modules which used to do the User Management for all web portals
- mecm-meo (optional): Independent with other EG modules except the user-mgmt
- mecm-fe (optional): Independent with other EG modules except the user-mgmt
- appstore (optional): Independent with other EG modules except the user-mgmt
- developer (optional): Independent with other EG modules except the user-mgmt
- atp (optional): Independent with other EG modules except the user-mgmt
- eg_check (optional): Independent with all other EG modules and only check the deployed modules and print the Web portal URL

In summary, all modules are optional except init, eg_prepare, mep and user-mgmt. mep is the mandatory role for edge and
user-mgmt is the mandatory one for controller.

## 6. How to Install Harbor Manually on X86

When you want to deploy EG on arm64 machines, you need to install Harbor manually on a x86 machine before deploying EG.

### 6.1 Deploy Harbor on X86

1. Install Docker and docker-compose because Harbor is rely on them
2. Config `/etc/docker/daemon.json`, add the following section. `xxx.xxx.xxx.xxx` is the private or public IP of this machine
   and can be accessed by the arm64 cluster. If there is no this file, create it.

   ```
   {
       "insecure-registries" : ["xxx.xxx.xxx.xxx"]
   }
   ```

3. Restart Docker Service

   ```
   systemctl restart docker.service
   ```

4. Download Harbor offline install package and put it on `/home`
5. Install Harbor, you can directly copy and paste all commands except the xxx.xxx.xxx.xxx and <password> which should be
   the IP given in step 2 and the password you want to set for Harbor

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
6. Login Harbor, login successfully means Harbor has been installed successfully

   ```
   docker login -u admin -p $HARBOR_ADMIN_PASSWORD $HARBOR_IP
   ```

### 6.2 Config Harbor on Ansible Controller Node

   The params related to Harbor should be set on Ansible controller Node before deploying EG.
   Please set `HarborIP` in the end of file `/home/EdgeGallery-v1.3.0-all-x86/install/default-var.yml` as the IP given in step 2 in the previous section.

   ```
   # If harbor is setup in a remote system, then mention the remote system IP as harbor IP
   #HarborIP: xxx.xxx.xxx.xxx
   ```

### 6.3 Deploy EG on Ansible Controller Node

   After installing Harbor successfully on that x86 machine, go on to refer to [Section 3 to deploy EG](#3-edgegallery-deployment) on Ansible Controller Node. 

## 7. Trouble Shoot

1. **error**:    fatal: [1.2.3.4]: FAILED! => {"msg": "Timeout (12s) waiting for privilege escalation prompt: "}
- **solution**: deploy eg as a 'root' user

2. **error**:    ESTABLISH SSH CONNECTION FOR USER: None
- **solution**: append '-e "ansible_user=root"' to ansible-playbook command
- **eg**: ansible-playbook --inventory hosts-aio eg_all_aio_uninstall.yml -e "ansible_user=root"

3. **Info**: For more verbosity add '-v' flag to ansible-playbook command
- **eg1**:  ansible-playbook --inventory hosts-aio eg_all_aio_uninstall.yml -vvv
- **eg2**:  ansible-playbook --inventory hosts-aio eg_all_aio_uninstall.yml -v
