      EdgeGallery安装FAQ
1．pod装置pending处理方法
问题描述：
安装完成后pod状态正常为running状态，kubectl get pos --all-namespaces
       如果status为pending状态：
        
                        图1 pod状态
处理建议：
A.检查虚机CPU，内存使用情况，确认资源是否够用。
B.检查node或者pod有没有污点
kubectl describe node | grep taint
如果存在污点删除污点后删除污点，
kubectl taint nodes node1 key:NoSchedule-   //node1为node name

2.  MEP安装DNS问题
问题描述：
边缘环境测试，多网卡mp1和mm5网卡隔离，从mp1接口获取mep给的token失败
该原因为DNS有问题导致。 

图2端口
处理建议：
DNS的53端口，由于环境安全策略屏蔽了该端口，在华为云上打开此端口问题解决

3．安装过程中K8S的8080端口问题导致安装K8S安装失败
问题描述：
具体情况如下：

图3安装失败
处理建议：
该问题为K8S为安装未成功：
kubeadm reset -f                        
kubeadm init --kubernetes-version=1.18.7
根据上条指令提示执行下面的命令：
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
完成后重新执行bash eg.sh -i安装即可
这样安装过程中可能会使个别pod存在污点导致pod状态一直为pending状态，可以直接使用
kubectl taint nodes --all node-role.kubernetes.io/master-  删除污点。
在继续安装bash eg.sh -i即可，或者安装过程中重新打开一个窗口您使用kebuctl get pod --all-spaces中有pod状态为pending状态，且安装进程一直在等待该pod running 也可以直接使用上述删除污点的指令，安装流程也会直接向下执行。

4．网卡名配置错误导致安装失败
问题描述：
env.sh网卡名配置导致安装失败


处理建议：
虚机可以会有多张网卡或者网桥，经常会填错网卡导致安装失败，这个地方IP与网卡名必须配置一致。

5．用户权限导致安装失败
问题描述：  
Ubuntu安装完成后基本上都是自己创建的用户名，而EdgeGallery安装需要root权限。
处理建议： 
使用指令：
Sudo passwd root  修改root账号密码
 桌面环境登录root
     
 如果要ssh登录：
      使用指令sudo ps –e | grep ssh查看是否安装ssh服务 如果没有：
      Sudo apt-get install openssh-server 现在安装ssh服务
      修改/etc/ssh/sshd_config文件，将#permitrootlogin prohibit-password
改为 permitrootlpgin  yes
      使用指令 service ssh restart 重启ssh服务
这样操作完就可以直接使用root账号登录了，减少出问题的几率。

6．K8S集群间免密设置未生效导致安装失败
 问题描述：
    由于免密设置未生效导致安装失败
 处理建议：
免密设置流程如下：
a.在deploy节点上生成密钥：
ssh-keygen -t rsa           //生成密钥
b.在deploy节点上设置免密：
  scp -p /root/.ssh/id_rsa.pub  (master IP):/root/.ssh/authorized_keys      
scp -p /root/.ssh/id_rsa.pub  (worker IP):/root/.ssh/authorized_keys    
      分别SSH到master和worker节点确认免密设置是否成功。  
多节点安装，我们的安装包在deploy节点，安装过程中deploy节点作为仓库，需要给Master和worker节点传送文件
经常有设置完a和b两步，没有进行登录，导致传送文件不成功master节点安装失败。


7.  K8S重启后报6443端口问题
问题描述：    
目前个人虚机安装完成后有的虚机存在交换空间的问题，导致本身已经安装完成的EG，出现下图的问题：

处理建议：   
Swapoff  -a
     Systemctl  restart docker
     Systemctl  restart kubelet 
     Systemctl  daemon-reload
   从新执行完成swapof –a关闭交换空间，重启docker和kubelet，reload过程需要等待一会，该问题解决。

8.  config文件上传失败
问题描述：
边缘侧下载完kube下的config文件在mecm侧注册边缘节点时上传配置文件失败。
   
处理建议： 
在这步骤上传时出现错误，config文件始终上传失败
最后检查发现config文件缺少读写权限导致上传配置文件失败
更改文件权限后，上传成功。

9.  APP部署失败
问题描述:  
安装完成后部署测试的到这一步，分配测试节点失败。

处理建议：
分配测试节点失败，该问题可能原因为：
MECM侧未配置未注册边缘节点。
中心节点数据库未添加边缘节点信息。
注册边缘节点时未上传配置文件。


10.  APP实例话失败
问题描述:  
部署调测完成，沙箱验证失败：

处理建议：
可以检查该应用是否已经在改边缘节点已经部署
Helm list查看结果如果已经存在删除即可。



11.  pod安装失败
  问题描述:
安装过程中可以能会存在某些pod安装失败，可以使用：
   Kubectl describe pod  对应有问题的pod名字
  
   
处理建议：
根据event事件分析改pod安装失败的原因，例如镜像拉取失败，
镜像拉去失败，可以手动上传镜像包 ，使用docker命令指令在本地拉去
或者docker pull 在远端公共仓库拉去镜像包，修改镜像名字和yaml一致
删除pod即可 

12.  部署失败pod的事件分析
 问题描述:  
实例app时有时会出现部署失败情况：
处理建议：
Kubectl logs ***    查看相关pod事件

  
也可以查看容器中部署日志分析部署失败的原因：


结合前台信息分析错误原因：

可三者结合分析查找部署失败原因