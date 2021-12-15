## 更新已部署Edgegallery1.3版本

由于EdgeGallery中一些容器镜像使用Apache log4j三方依赖 2.13.3版本，该版本在2021年12月中旬被发现存在漏洞，并在2.15.0版本进行修复。

EG中涉及的镜像仅分布在中心侧，边缘侧不涉及。具体镜像列表如下：

- appstore-fe
- appstore-be
- appdtranstool
- developer-fe
- developer-be
- mecm-fe
- mecm-inventory
- mecm-appo
- mecm-apm
- user-mgmt
- atp-fe
- atp-be

EdgeGallery基于1.3版本，将该三方件依赖升级至最新的2.15.0版本，并发布1.3.2补丁版本。

已安装部署EG v1.3版本的用户可以根据以下指导，更新已部署环境相关模块，修复漏洞。

### 1. 获取补丁包

用户根据部署环境的架构选择相应的补丁包进行下载。

- [x86架构点击此处下载](https://edgegallery-v1.3.2.obs.cn-north-4.myhuaweicloud.com/edgegallery_patch_update_amd64.tar.gz)
- [arm64架构点击此处下载](https://edgegallery-v1.3.2.obs.cn-north-4.myhuaweicloud.com/edgegallery_patch_update_arm64.tar.gz)


### 2. 配置升级信息

将补丁包放置在Ansible控制节点某个路径上，此处假设是x86架构补丁包，放置在`/home`目录。

#### 2.1 解压补丁包

```
cd /home
tar -xvf edgegallery_patch_update_amd64.tar.gz
cd EdgeGallery_patch_update/
```

#### 2.2 配置升级所需要的的信息

此部分配置与安装部署时的配置基本相同，请参考[部署指导文档](https://gitee.com/edgegallery/installer/blob/Release-v1.3/ansible_install/README-cn.md)进行配置，
或者直接将之前部署时的配置文件拷贝替换此处的对应文件即可。

 **注意：`password-var.yml`文件中的所有密码配置，必须与之前部署环境时一致，不然可能会导致服务访问失败。** 

### 3. 升级本地部署

升级过程同样是通过Ansible脚本实现。

执行如下命令，完成相应模块的升级。

```
# AIO Mode
ansible-playbook -i hosts-aio eg_controller_aio_upgrade.yaml

# MUNO Mode
ansible-playbook -i hosts-muno eg_controller_muno_upgrade.yaml
```

### 4. 确认升级成功

以上命令执行过程中未报错，并且成功退出，即表示升级完成。

用户也可以通过查看helm releases的信息，确认涉及的模块已经成功进行版本更新。

```
helm list
```

如下helm releases的`REVISION`字段应该为2，并且`UPDATED`字段时间为当前时间：

```
NAME                        NAMESPACE      REVISION    UPDATED                                  STATUS        CHART                APP VERSION
appstore-edgegallery        default        2           2021-12-14 17:49:13.481415511 +0800 CST  deployed      appstore-1.3.0       0.9
atp-edgegallery             default        2           2021-12-14 17:52:17.681571737 +0800 CST  deployed      atp-1.3.0            0.9
developer-edgegallery       default        2           2021-12-14 17:50:14.523966825 +0800 CST  deployed      developer-1.3.0      0.9
mecm-meo-edgegallery        default        2           2021-12-14 17:51:14.185890447 +0800 CST  deployed      mecm-meo-1.3.0       0.9
user-mgmt-edgegallery       default        2           2021-12-14 17:48:49.66030383 +0800 CST   deployed      usermgmt-1.3.0       0.9
```

### 5. 回退到旧版本

如果升级过程失败，或者升级后的版本功能有问题，可以使用`helm rollback`命令将相应的helm releases回退之前版本。
以下以`appstore-edgegallery`为例：

```
helm rollback appstore-edgegallery 1
helm list
```

可以查看到该releases的`REVISION`已经从2到3，版本回退到之前1.3.0。

```
NAME                      NAMESPACE    REVISION     UPDATED                                  STATUS       CHART                 APP VERSION
appstore-edgegallery      default      3            2021-12-14 18:12:22.469699907 +0800 CST  deployed     appstore-1.3.0        0.9

```
