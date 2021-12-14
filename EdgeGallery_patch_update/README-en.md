## Upgrade the Deployed Edgegallery v1.3

There is a CVE issue of Apache log4j been reported in the middle of December of 2021, and it has already been fixed in 2.15.0 verison.

There are some Docker images in EdgeGallery using this dependency, so we released a patch version v1.3.2 to fix it.

The related Docker images in EG are list below:

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

If you have already deployed EG v1.3.0, you can follow the next stpes to upgrade your local EG version to fix this issue.

### 1. Download Patch Package

Please Download the patch package according to your architecture.

- [x86 download](https://edgegallery-v1.3.2.obs.cn-north-4.myhuaweicloud.com/edgegallery_patch_update_amd64.tar.gz)
- [arm64 download](https://edgegallery-v1.3.2.obs.cn-north-4.myhuaweicloud.com/edgegallery_patch_update_arm64.tar.gz)

### 2. Config the Upgrade

Copy the patch package to the Ansible Controller node. Here take the x86 package as the example. Suppose it has been copied to `/home`.

#### 2.1 Decompress the Patch Package

```
cd /home
tar -xvf edgegallery_patch_update_amd64.tar.gz
cd EdgeGallery_patch_update/
```

#### 2.2 Config the Upgrade Info Needed

The configuration here needed are totally the same as deployment, so you can refer to the [guide of deployment](https://gitee.com/edgegallery/installer/blob/Release-v1.3/ansible_install/README-en.md),
or you can copy the related files you used before during the deployment to here directly.

 **Note: The password in `password-var.yml`should be exactly the same as before you used to deployment EG. Otherwise the upgrade would be failed.** 

### 3. Upgrade EG

The same as deploying EG, we use Ansible scripts here to do the upgrade.

Do the following command to upgrade the related helm releases which have already been deployed.

```
# AIO Mode
ansible-playbook -i hosts-aio eg_controller_aio_upgrade.yaml

# MUNO Mode
ansible-playbook -i hosts-aio eg_controller_muno_upgrade.yaml
```

### 4. Double Check the Upgrade

If there is no errors are reported in the upgrade step, and you got a success at the end of the upgrade script,
that means all helm releases have been upgraded successfully.

Also you can use the following command to check the info of all helm releases, and make sure that all related helm releases related have been updated.

```
helm list
```

The `REVISION` of the following helm releases shoube be 2 and the `UPDATED` should be current time.

```
NAME                        NAMESPACE      REVISION    UPDATED                                  STATUS        CHART                APP VERSION
appstore-edgegallery        default        2           2021-12-14 17:49:13.481415511 +0800 CST  deployed      appstore-1.3.0       0.9
atp-edgegallery             default        2           2021-12-14 17:52:17.681571737 +0800 CST  deployed      atp-1.3.0            0.9
developer-edgegallery       default        2           2021-12-14 17:50:14.523966825 +0800 CST  deployed      developer-1.3.0      0.9
mecm-meo-edgegallery        default        2           2021-12-14 17:51:14.185890447 +0800 CST  deployed      mecm-meo-1.3.0       0.9
user-mgmt-edgegallery       default        2           2021-12-14 17:48:49.66030383 +0800 CST   deployed      usermgmt-1.3.0       0.9
```

### 5. Rollback to Old Version

If there are some errors happened during the upgrade or in subsequent use, you can choose to rollback to old version of some helm releases.
Following take the `appstore-edgegallery` as the example.

```
helm rollback appstore-edgegallery 1
helm list
```

Now you can find that the `REVISION` of it has been changed from 2 to 3, and this means it uses the old image v1.3.0 now.

```
NAME                      NAMESPACE    REVISION     UPDATED                                  STATUS       CHART                 APP VERSION
appstore-edgegallery      default      3            2021-12-14 18:12:22.469699907 +0800 CST  deployed     appstore-1.3.0        0.9

```