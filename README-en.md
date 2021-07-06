EdgeGallery offline packages creation and offline/online installation, as well as installing EG with Docker Compose.

### Guide of Online Installation

There is no automatic scripts for online installation now. If you want to install EG online manually, please refer to [EdgeGallery_online_install](EdgeGallery_online_install/EdgeGallery_online_installation_guide.md).

### Ansible Scripts of Offline Installation

We provide Ansible scripts for EG offline installation, please refer to [ansible_install](ansible_install/README-en.md).

### Install with Docker Compose

Besides the method to install EG we mentioned above which are based on either k8s or k3s, we also provide another way to install EG.
You can directly install EG with Docker Compose without the dependency with k8s/k3s. Please refer to [EdgeGallery_docker_compose_install](EdgeGallery_docker_compose_install/README_en.md).

### Guide of Installation on Raspberry

You can refer to the [EdgeGallery_Raspberry_pi_instructions](EdgeGallery_Raspberry_pi_instructions.md) to install EG on Raspberry.

### Ansible Scripts of Offline Packages Creation

There is a bunch of scripts for offline packages creation which is used together with the Ansible offline install scripts.

Users do not need to know the details about this part. You can download the packages directly from [EdgeGallery Website](https://www.edgegallery.org/en/downloaden/).

For developers, when you want to modify the contents of the offline packages, you can refer to [ansible_package](ansible_package).