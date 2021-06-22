本地集群存储服务的Velero安装

1. 安装Velero客户端

   官网下载velero安装包 velero-v1.6.0-linux-amd64.tar.gz
   tar -xvf  velero-v1.6.0-linux-amd64.tar.gz

   解压后把velero二进制文件移入PATH中（/usr/local/bin)

    mv  velero /usr/local/bin

2. 安装Velero服务端

   安装目录下创建credentials-velero文件

   vi credentials-velero
   [default]
   aws_access_key_id = minio
   aws_secret_access_key = minio123 

3. 安装服务端
   
   kubectl apply -f examples/minio/00-minio-deployment.yaml //00-minio-deployment.yaml文件是velero安装文件里自带的

   创建minio和restic服务:

    velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.1.0 \
    --bucket velero \
    --secret-file ./credentials-velero \
    --use-volume-snapshots=false \
    --use-restic \
    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://{node ip}:9000

4. 配置minio服务外部访问端口

   将ClusterIP设置为NodePort
     
   kubectl edit svc minio -n velero
   
   查看暴露的端口并IP+端口进行访问

   kubectl get svc -n velero


Velero备份操作 
 
  velero backup create --help    //备份帮助操作

1. 备份示例并查看描述   
   
   velero backup create backup1 --include-namespaces myproject       //Velero备份

   velero backup describe backup1                                    //备份结果查看
 
   当备份结果中Phase状态为complete时为备份完成

 2. 将备份存储位置更新为只读模式（这可以防止在恢复过程中在备份存储位置创建或删除备份对象

    kubectl patch backupstoragelocation <STORAGE LOCATION NAME> \
    --namespace velero \
    --type merge \
    --patch '{"spec":{"accessMode":"ReadOnly"}}'
   
     可通过Velero CLI查看<STORAGE LOCATION NAME>

     velero backup-location get

     默认名称为default，也可以通过velero backup-location create创建
 
 3. 修改备份过期时间
 
    默认的备份保留时间为30days（720hours），可以在备份操作后添加--ttl <DURATION>标志去更改。

 4. 备份完成后删除该namespace

   注意：先删除namespace中的所有资源后再删除namespace，删除pod前先删除deployment。


Velero恢复操作

 velero restore create --help  //恢复帮助操作

1. 使用helm delete删除developer 恢复（示例）
  
   velero restore create --from-backup backup1 --include-namespaces myproject   //恢复

   velero restore describe backup1-20210613221147           // 查看恢复状态

   当恢复结果中Phase状态为complete时为恢复完成

2. 还原完成后，将备份存储位置恢复为读写模式

    kubectl patch backupstoragelocation <STORAGE LOCATION NAME> \
    --namespace velero \
    --type merge \
    --patch '{"spec":{"accessMode":"ReadWrite"}}'

3.  目前恢复完成，但是developer页面是无法访问的。
   
4.  根据developer部署模块暴露端口，修改回之前的正常端口数据恢复。
   
    kubectl edit svc developer-be-svc       //30098
    
    kubectl edit svc developer-fe-svc       //30092

   如果其他模块需要恢复也一样。


Velero定期备份操作

velero schedule create --help      //查看定时备份指令


