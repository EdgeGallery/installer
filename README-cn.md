EdgeGallery离线包制作以及离线安装、在线安装、docker compose方式安装脚本。

### 在线安装指导

暂无自动化安装脚本支持在线安装，如需在线安装，请参考手动在线安装指导[EdgeGallery_online_install](EdgeGallery_online_install/EdgeGallery_online_installation_guide.md)。

### 离线安装自动化脚本

提供基于Ansible的离线安装脚本，请参考[ansible_install](ansible_install/README-cn.md)。

### Docker Compose 方式安装脚本

提供基于直接基于Docker Compose方式（无k8s、k3s）的安装脚本，请参考[EdgeGallery_docker_compose_install](EdgeGallery_docker_compose_install/README.md)。

### 树莓派安装指导

提供基于Docker Compose方式在树莓派上安装EG的指导文档，请参考[EdgeGallery_Raspberry_pi_instructions](EdgeGallery_Raspberry_pi_instructions.md)。

### 离线安装包制作脚本

提供离线安装包制作的自动化脚本，与离线安装自动化脚本配套使用。

用户无需了解离线包制作详情，可直接从[EdgeGallery官网](https://www.edgegallery.org/download/)下载对应版本的离线包使用。

开发人员如需修改离线包内容，请参考[ansible_package](ansible_package)。