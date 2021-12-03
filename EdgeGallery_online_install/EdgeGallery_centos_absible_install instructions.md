
                    
  #  EdgeGallery在centos系统安装指导 #
     
  目前在centos环境安装有两种方式，在线安装和离线安装，两者都有相同的地方，目前部分插件是.deb格式的，我们需要使用相应的centos版本的插件。

  本次主要讲下离线安装，在线安装此部分也可参考。
  


   # 1. ansible安装 #

   
   离线安装需要使用ansible,centos版本建议使用7.0以上.
  
   建议使用下载 ansible-4.8.0.tar.gz 进行安装
   
    pip3 install ansible    /在线或者手动安装
  
   
   # 2.ssh免密设置 #
   
   建议使用sshpass-1.06-2.el7.x86_64.rpm安装包

    yum install sshpass    /在线安装
   
   或者
  
    yum install --downloadonly --downloaddir=/root/ sshpass    /或者下载到本地后手动安装

    sshpass -V         /查看ssh版本   

   设置免密：

   部署控制节点/root/.ssh/目录下需要有id_rsa和id_rsa.pub文件，若没有，执行以下命令，并连按三次Enter键生成：

    ssh-keygen -t rsa
  
   在部署控制节点执行以下命令，配置部署控制节点免密登录所有待部署节点权限，依次替换<master-or-worker-node-ip>为各节点（Master和Worker）私有IP，<master-or-worker-node-root-password>为对应的节点的root用户登录密码, <ssh-port>为ssh登录的端口，默认为22

    sshpass -p <master-or-worker-node-root-password> ssh-copy-id -p <ssh-port> -o StrictHostKeyChecking=no root@<master-or-worker-node-ip>


   # 3.openssl检查 #
   
    openssl version   /检查openssl版本

    openssl建议使用1.1.1及以上版本

   我们已openssl-1.1.1c版本为例，下载对应的安装包

   ## 3.1 安装openssl ##

    tar -zxvf  openssl-1.1.1c.tar.gz

   进入openssl并编译

    cd openssl-1.1.1c

    ./config no-shared --libdir=lib
   
    make

    make install_sw

   ## 3.2、备份旧ssl执行以下命令 ##

    mv /usr/bin/openssl /usr/bin/openssl.bak

    mv /usr/include/openssl /usr/include/openssl.bak

    ln -s /usr/local/bin/openssl /usr/bin/openssl
  
    ln -s /usr/local/include/openssl /usr/include/openssl

    echo “/usr/local/lib64” >> /etc/ld.so.conf
  
    ldconfig -v
   
   # 4.按照ansible安装EG指导配置相关参数 #

   https://e.gitee.com/OSDT/repos/edgegallery/installer/blob/master/ansible_install/README-cn.md

    
   # 5.使用ansible安装 #

   EG安装的roles总计就下面这些步骤：
  
    roles:
    - { role: init, tags: ['init'] }
    - { role: k8s, tags: ['k8s'] }
    - { role: eg_prepare, tags: ['eg_prepare'] }
    - { role: mep, tags: ['mep'] }
    - { role: mecm-mepm, tags: ['mecm-mepm'] }
    - { role: healthcheck, tags: ['healthcheck'] }
    - { role: user-mgmt, tags: ['user-mgmt'] }
    - { role: mecm-meo, tags: ['mecm-meo'] }
    - { role: appstore, tags: ['appstore'] }
    - { role: developer, tags: ['developer'] }
    - { role: atp, tags: ['atp'] }
    - { role: healthcheck-m, tags: ['healthcheck-m'] }
    - { role: file-system, tags: ['file-system'] }
    - { role: eg_check, tags: ['eg_check'] }

   EG模块是不依耐某些固定系统，安装的问题主要出现K8S和eg_prepare中个别依耐，我们前三步骤单独安装

   ## 5.1 执行安装init ##
     
    cd /home/EdgeGallery-v1.3.0-all-x86/install
   
    ansible-playbook --inventory hosts-aio  eg_all_aio_install.yml --tags=init  
    
   此步骤为ssh验证解压
   
   ## 5.2 执行安装K8S ##
  
    ansible-playbook --inventory hosts-aio eg_all_aio_install.yml --tags=K8S

   当安装到这两条指令时会报错

    dpkg -i "{{ K8S_OFFLINE_DIR }}/tools/conntrack_1.4.4+snapshot20161117-6ubuntu2_{{ ARCH }}.deb"

    dpkg -i "{{ K8S_OFFLINE_DIR }}/tools/socat_1.7.3.2-2ubuntu2_{{ ARCH }}.deb"

   在k8s_install_offline.yml文件中注释掉这两部分
   
    vim roles/k8s/tasks/k8s_install_offline.yml

   然后手动安装conntrack和socat

    yum install   conntrack-tools      /在线安装conntrack-tools

    yum install   socat                /在线安装socat

   或者下载conntrack-tools-1.4.4-7.el7.x86_64.rpm和socat-1.7.3.2-2.el7.x86_64.rpm手动本地安装

   但是在其它地方下载的时候建议使用：

    yum install --downloadonly --downloaddir=/root/ conntrack-tools

    yum install --downloadonly --downloaddir=/root/ socat
   
   这样方式下载，防止依耐太多安装不成功。

   以上操作完成后继续执行：
  
    ansible-playbook --inventory hosts-aio eg_all_aio_install.yml --tags=K8S

   在继续安装中如果出现“/bin/bash：helm：command not found”错误

   可以执行：
     
    cp /usr/local/bin/helm /usr/bin/

  
   同时将macvlan copy到/opt/cni/bin防止后面mep安装出错

    cp /home/edgegallery-offline/kubernetes_offline_installer/cni/macvlan /opt/cni/bin

   继续执行ansible安装，后面NFS安装应该会失败，NFS安装失败后就跳过这个步骤，手动安装NFS
 
    ansible-playbook --inventory hosts-aio eg_all_aio_install.yml --tags=K8S
   
   失败后手动安装NFS跳过
    
   ## 5.3 执行安装NFS ##

    yum install --downloadonly --downloaddir=/root/ nfs-utils  /下载NFS服务端用于离线安装
  
   或者直接在线安装：
   
    yum install  nfs-utils   
  
   安装完成后创建配置文件：

    mkdir -p /edgegallery/data/          

    chmod -R 755 /edgegallery/data/

    vim /etc/exports

    /edgegallery/data/ 192.168.0.0/24(rw,no_root_squash,sync)    #设置挂载本机数据的机器ip或网段

    exportfs -r     #配置生效

    exportfs        #查看生效  
  
    systemctl restart rpcbind && systemctl enable rpcbind

    systemctl restart nfs && systemctl enable nfs      #启动rpcbind、nfs服务
   
    rpcinfo -p localhost    #查看 RPC 服务的注册状况

    NFS客户端安装：

    helm install nfs-client-provisioner --set nfs.server=<nfs_sever_ip> --set nfs.path=/edgegallery/data/  /home/edgegallery-offline/helm/helm-charts/stable/nfs-client-provisioner-1.2.8.tgz

   NFS pod正常后就可以继续安装了


   ## 5.4 执行安装eg_prepare ##

   安装这部分前ubuntu的系统设置需要提前注释掉
   
    vim  roles/eg_prepare/tasks/prepare_offline.yml

    #- name: add rc-local intall configure
    .
    .
    #- name: Restart rc.local.service
     # service:
     # name: rc.local.service
     # enabled: yes
     # state: restarted 
     # ignore_errors: yes 
 
  从- name: add rc-local intall configure一直注释到yaml文本最后。
 
    ansible-playbook --inventory hosts-aio eg_all_aio_install.yml  --tags=eg_prepare

  安装完这一步就可以一起安装EG模块了
  
   ## 5.5 执行安装eg模块 ##

  在eg_all_aio_install.yml注释掉前三步

    roles:
     # - { role: init, tags: ['init'] }
     # - { role: k8s, tags: ['k8s'] }
     # - { role: eg_prepare, tags: ['eg_prepare'] }
    - { role: mep, tags: ['mep'] }
    - { role: mecm-mepm, tags: ['mecm-mepm'] }
    - { role: healthcheck, tags: ['healthcheck'] }
    - { role: user-mgmt, tags: ['user-mgmt'] }
    - { role: mecm-meo, tags: ['mecm-meo'] }
    - { role: appstore, tags: ['appstore'] }
    - { role: developer, tags: ['developer'] }
    - { role: atp, tags: ['atp'] }
    - { role: healthcheck-m, tags: ['healthcheck-m'] }
    - { role: file-system, tags: ['file-system'] }
    - { role: eg_check, tags: ['eg_check'] }
  
注释掉保存就可以正常安装EG了，执行安装指令等待完成。

    ansible-playbook --inventory hosts-aio eg_all_aio_install.yml

等待安装完成就可以按照流程使用EG了