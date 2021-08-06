                                                       EdgeGallery V1.2版本升级



- 1 版本升级介绍
  
    升级版本可以使用在线或离线升级方式，可以完成1.2升级更高版本，通过升级使持久化继续存在。

- 2 升级步骤
  

- 2.1 升级前准备

    修改EdgeGallery-upgrade-value.yaml文件，将文件中的ip替换成自己安装时设置的IP（EG访问IP）
   
    sed -i 's/192.168.100.100/安装时设置IP/g' EdgeGallery-upgrade-value.yaml

    下载或者使用latest包中的helm安装包：
    
    离线helm位置：EdgeGallery-latest-all-x86/ansible-latest.tar.gz/helm/helm-charts/edgegallery
    
    在线下载： https://gitee.com/edgegallery/helm-charts.git

- 2.2 升级指令

    本地升级解压安装包下的ansible-latest.tar.gz
 
    tar -xvf ansible-latest.tar.gz       /解压
 
    cd eg_swr_images
 
    docker load -i  eg_images.tar.gz       /加载本地镜像包

    cd ..                                 /返回上一级目录

    cd helm/helm-charts/edgegallery       /到helm包跟目录下

- 2.2 开始升级    

 
    查看之前安装是设置的password，在安装设置密码的password-var.yml文件中能看见HARBOR_ADMIN_PASSWORD，postgresPassword
    ，oauth2ClientPassword，userMgmtRedisPassword的具体密码将,下面指令中对应的值替换成对应安装时的密码即可，其中的IP更换
    为harbor IP
  
     user-mgmt：

         helm upgrade user-mgmt-edgegallery usermgmt-1.3.0.tgz -f /root/edgegallery-values.yaml \
         --set postgres.password=postgresPassword \ 
         --set redis.password=userMgmtRedisPassword \
         --set global.oauth2.clients.appstore.clientSecret=oauth2ClientPassword \
         --set global.oauth2.clients.developer.clientSecret=oauth2ClientPassword \
         --set global.oauth2.clients.mecm.clientSecret=oauth2ClientPassword \
         --set global.oauth2.clients.atp.clientSecret=oauth2ClientPassword \
         --set global.oauth2.clients.lab.clientSecret=oauth2ClientPassword 

    developer：
   

         helm upgrade developer-edgegallery developer-1.3.0.tgz -f /root/edgegallery-values.yaml  \
         --set global.oauth2.clients.developer.clientSecret=oauth2ClientPassword \
         --set developer.dockerRepo.endpoint=192.168.100.100 \
         --set developer.dockerRepo.password=HARBOR_ADMIN_PASSWORD \
         --set developer.dockerRepo.username=admin \
         --set postgres.password=postgresPassword \
         --set developer.vmImage.password=123456

    appstore：
    

        helm upgrade appstore-edgegallery appstore-1.3.0.tgz -f edgegallery-values.yaml \
        --set global.oauth2.clients.appstore.clientSecret=oauth2ClientPassword \
        --set appstoreBe.dockerRepo.endpoint=192.168.100.100 \
        --set appstoreBe.dockerRepo.appstore.password=HARBOR_ADMIN_PASSWORD \
        --set appstoreBe.dockerRepo.appstore.username=admin \
        --set appstoreBe.dockerRepo.developer.password=HARBOR_ADMIN_PASSWORD \
        --set appstoreBe.dockerRepo.developer.username=admin \
        --set postgres.password=postgresPassword

    mecm： 

        helm upgrade mecm-meo-edgegallery mecm-meo-1.3.0.tgz -f /root/edgegallery-values.yaml  \
        --set mecm.docker.fsgroup=$(getent group docker | cut -d: -f3) \
        --set mecm.repository.dockerRepoEndpoint=192.168.100.100 \
        --set mecm.repository.sourceRepos="repo=192.168.100.100  userName=admin password=HARBOR_ADMIN_PASSWORD"  \
        --set global.oauth2.clients.mecm.clientSecret=oauth2ClientPassword \
        --set mecm.postgres.postgresPass=postgresPassword \
        --set mecm.postgres.inventoryDbPass=postgresPassword \
        --set mecm.postgres.appoDbPass=postgresPassword \
        --set mecm.postgres.apmDbPass=postgresPassword

    ATP:
          
         helm upgrade atp-edgegallery atp-1.3.0.tgz -f /root/edgegallery-values.yaml \ 
         --set postgres.password=postgresPassword \  
         --set global.oauth2.clients.atp.clientSecret=oauth2ClientPassword
 
    mecm-mepm:
   
        helm upgrade mecm-mepm-edgegallery mecm-mepm-1.3.0.tgz -f /root/edgegallery-values.yaml \
        --set jwt.publicKeySecretName=mecm-mepm-jwt-public-secret \
        --set ssl.secretName=mecm-mepm-ssl-secret \
        --set mepm.postgres.postgresPass=postgresPassword \
        --set mepm.postgres.lcmcontrollerDbPass=oauth2ClientPassword \
        --set mepm.postgres.k8spluginDbPass=postgresPassword \
        --set mepm.postgres.ospluginDbPass=postgresPassword \
        --set mepm.postgres.apprulemgrDbPass=postgresPassword
   
    mep(eth0替换成自己的网卡）:  
    
        helm upgrade  --install  mep-edgegallery mep-1.3.0.tgz -f /root/edgegallery-values.yaml \ 
        --set networkIsolation.ipamType=host-local \
        --set networkIsolation.phyInterface.mp1=eth0 \
        --set networkIsolation.phyInterface.mm5=eth0 
        --set ssl.secretName=mep-ssl  
        --set postgres.kongPass=postgresPassword
    
    等升级完成后如果mep pod状态未running 可手动删除pod

     kubectl delete pod --all -n mep
 