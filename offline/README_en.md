Edge gallery offline installer provides deployer for kubernetes based edge gallery deployment based on ubuntu x86_64 or arm64 architecture.

Deployment Architecture
-------------------------

![输入图片说明](https://images.gitee.com/uploads/images/2020/0908/175117_9de15f97_7639331.png "屏幕截图.png")

Scenarios
----------
![输入图片说明](https://images.gitee.com/uploads/images/2020/0908/175411_496a87ef_7639331.png "屏幕截图.png")

Supported tool Versions
-----------------------
![输入图片说明](https://images.gitee.com/uploads/images/2020/0908/175524_dc986df0_7639331.png "屏幕截图.png")


How to Deploy
=============

Pre-requsities
---------------

* Install Ubuntu 18.04 operating system on all those nodes and set same root password and connect them into network as planned.
* Download offline installer from FTP server **http://159.138.137.155**. And installers are available for edge, controller and full stack separately for x86 and arm64 architectures.
* Extract to a folder
* Prepare all the node as below

 _./eg.sh –prepare IP1, IP2, IP3 PASSWORD_ 

Deploy Modes
----------------

Installer supports to deploy in following modes for edge gallery controller, edge or complete stack. 

All-in-one (aio) Mode
---------------------

**Deploy controller and edge together**

Set following values in env.sh and run **source env.sh**

OFFLINE_MODE = aio

EG_NODE_MASTER_IPS = 192.168.99.100

*To Configure MEP MP1 & MM5 Interfaces, By default, these interfaces are set to eth0*

EG_NODE_EDGE_MP1=eth1

EG_NODE_EDGE_MM5=eth2

./eg.sh -i


**Deploy controller**

Set following values in env.sh and run **source env.sh**

OFFLINE_MODE = aio

EG_NODE_CONTROLLER_MASTER_IPS = 192.168.99.101

./eg.sh -i


**Deploy edge**

Set following values in env.sh and run **source env.sh**

OFFLINE_MODE = aio

EG_NODE_EDGE_MASTER_IPS = 192.168.99.104

*To Configure MEP MP1 & MM5 Interfaces, By default, these interfaces are set to eth0*

EG_NODE_EDGE_MP1=eth1

EG_NODE_EDGE_MM5=eth2

./eg.sh -i


Multi-node (muno) Mode
----------------------

**Deploy controller and edge together** 

Set following values in env.sh and run **source env.sh**

OFFLINE_MODE = muno

EG_NODE_DEPLOY_IP=192.168.99.100

EG_NODE_MASTER_IPS = 192.168.99.101

EG_NODE_WORKER_IPS= 192.168.99.102, 192.168.99.103

*To Configure MEP MP1 & MM5 Interfaces, By default, these interfaces are set to eth0*

EG_NODE_EDGE_MP1=eth1

EG_NODE_EDGE_MM5=eth2

./eg.sh -i

*NOTE* : Edge gallery does not support MEP in this mode. Please deploy in aio mode for using MEP.



**Deploy controller** 

Set following values in env.sh and run **source env.sh**

OFFLINE_MODE = muno

EG_NODE_DEPLOY_IP=192.168.99.100

EG_NODE_CONTROLLER_MASTER_IPS = 192.168.99.101

EG_NODE_CONTROLLER_WORKER_IPS= 192.168.99.102, 192.168.99.103

./eg.sh -i


**Deploy edge**

Set following values in env.sh and run **source env.sh**

OFFLINE_MODE = muno

EG_NODE_DEPLOY_IP=192.168.99.100

EG_NODE_EDGE_MASTER_IPS = 192.168.99.104

EG_NODE_EDGE_WORKER_IPS= 192.168.99.105, 192.168.99.106

*To Configure MEP MP1 & MM5 Interfaces, By default, these interfaces are set to eth0*

EG_NODE_EDGE_MP1=eth1

EG_NODE_EDGE_MM5=eth2

./eg.sh -i

*NOTE* : Edge gallery does not support MEP in this mode. Please deploy in aio mode for using MEP.


To Uninstall
------------

With same env.sh used during the installation, run *source env.sh*. Then following below steps for uninstalling

./eg.sh -u OPTION

Following options are available:

all - uninstall complete eg stack

controller - uninstall only controller 

edge - uninstall only edge


Kubernetes Deployment
====================

This installer also provides option to deploy only kubernetes by setting following env variables in env.sh and run **source env.sh**:

#aio mode

OFFLINE_MODE=aio

K8S_NODE_MASTER_IPS=192.168.100.120


#muno mode

OFFLINE_MODE=muno

K8S_NODE_MASTER_IPS=192.168.100.120

K8S_NODE_WORKER_IPS=192.168.100.120

K8S_NODE_DEPLOY_IP=192.168.100.120


Daily Build
======================

Edge gallery CICD daily builds and upload the installer into above mentioned http server. The same installer could be build 
on your system where you have internet connectivity by running offline.sh.

Following additional options are available for setting

* EG_IMAGE_TAG - Set this to edge gallery image tag to use in installer, by default its set to latest.

* EG_IMAGE_LIST_CONTROLLER_X86, EG_IMAGE_LIST_CONTROLLER_ARM64, EG_IMAGE_LIST_EDGE_X86, EG_IMAGE_LIST_EDGE_ARM64 - Set to required images for deploying the components of edge gallery.


