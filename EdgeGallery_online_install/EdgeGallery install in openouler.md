###  EdgeGallery在openeuler系统中安装

    在euler中安装EG类似于在centos中安装，也可参考centos的安装指导。 
    (http://gitee.com/edgegallery/installer/blob/master/EdgeGallery_online_install/EdgeGallery_centos_absible_install%20instructions.md）


**1. 检查openssl版本** 
  
    openssl version      /版本在1.1.1版本及以上版本就无需升级

**2. openEuler系统配置yum镜像源** 

编辑配置文件：

    vim /etc/yum.repos.d/openEuler_x86_64.repo

添加以下内容（其中IP为yum源镜像地址）：

    [20.03-SP1]
    name=20.03-SP1 
    baseurl=http://{IP}/openEuler:/20.03:/LTS:/SP1/standard_x86_64/ 
    enabled=1 
    gpgcheck=0 
    priority=1 

清除缓存中的软件包及旧的headers：

    yum clean all

重新建立缓存：

    yum makecache

后面安装步骤可以参考centos安装指导

 **3. 安装过程可能会出现的问题** 

 **3.1 net.ipv4.ip_forward导致K8S安装失败** 
  
  使用ansible安装过程中出现如下错误
   
    /proc/sys/net/ipv4/net.ipv4.ip_forward conttents are not set 1
 
  可将其set 1 后手动安装K8S

    cd  /proc/sys/net/
    sysctl -w net.ipv4.ip_forward=1
  
   手动安装K8S（替换master ip）

    kubeadm init --kubernetes-version=v1.18.7 --apiserver-advertise-address={master ip} --pod-network-cidr=10.244.0.0/16 -v=5

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    kubectl apply -f /home/edgegallery-offline/kubernetes_offline_installer/k8s/calico.yaml

    kubectl taint nodes --all node-role.kubernetes.io/master-  //删除污点

 安装完K8S继续使用centos指导安装EG

**3.2 helm command not found**

  使用ansible安装时如果安装中报helm:command not found或者docker-compose:command not found类似错误，可以进行一下操作
  
    cp /home/edgegallery-offline/helm/linux-amd64/helm  /usr/bin/
    
   或者 
   
    cp /home/edgegallery-offline/harbor/docker-compose /usr/bin/
 
安装完K8S继续使用centos指导安装EG
 