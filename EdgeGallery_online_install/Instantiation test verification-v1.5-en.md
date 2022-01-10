### Instantiate operation instructions after deployment（V1.5.0)


##### 1.Health check after installation

Deployment prompt will appear after successful deployment of edgegallery using ansible

kubectl get pod --all-namespaces //Check the running status of the pod. Under normal conditions, the status of the pod is running

If the status of the pod is not running, further positioning is required

The last step is to manually instantiate the test

##### 2.Manual instantiation test

Edgegallery web page login requires Chrome browser，which is currently set as a unified portal，https://master_IP:30095 （or https://PORTAL_IP:30095）

![输入图片说明](images/2021-v1.5.0/image-en-1.png)

Default administrator user：admin Passwd：Admin@321

###### 2.1 Create sandbox environment

developer-->System-->Host Management

add host

![输入图片说明](images/2021-v1.5.0/image-en-2.png)

The config configuration file uploaded by k8s is: root/.Kube/Config

Openstack sandbox environment is the relevant configuration file information of openstack. Edit the following files into config files and upload them:

export OS_USERNAME=admin

export OS_PASSWORD=******

export OS_PROJECT_NAME=admin

export OS_AUTH_URL=http://192.168.*.*/identity

export OS_IDENTITY_API_VERSION=3

export OS_PROJECT_DOMAIN_NAME=default

export OS_USER_DOMAIN_NAME=default

###### 2.2 Upload image

developer-->System-->System Image Management

![输入图片说明](images/2021-v1.5.0/image-en-4.png)

##### 3.3 App incubation

Enter from the menu bar or home page:

![输入图片说明](images/2021-v1.5.0/image-en-5.png)

Create a new application, VM or container:

![输入图片说明](images/2021-v1.5.0/image-en-6.png)


Select sandbox (you can select it in the capability center when you need to deploy relevant capabilities):

![输入图片说明](images/2021-v1.5.0/image-en-7.png)

Select the corresponding sandbox:

![输入图片说明](images/2021-v1.5.0/image-en-8.png)

###### 3.3.1 Container application

Upload yaml and start the test：

![输入图片说明](images/2021-v1.5.0/image-en-9.png)

###### 3.3.2 VM application

Configure virtual machine network and create virtual machine:

![输入图片说明](images/2021-v1.5.0/image-en-11.png)

Create VM configuration:

![输入图片说明](images/2021-v1.5.0/image-en-12.png)

  
![输入图片说明](images/2021-v1.5.0/image-en=23.png)      

##### 3.4 Make image

step 3

![输入图片说明](images/2021-v1.5.0/image-en-14.png)

##### 3.5 Create edge node

Create MECPM

![输入图片说明](images/2021-v1.5.0/image-en-15.png)

Create edge node

![输入图片说明](images/2021-v1.5.0/image-en-16.png)

##### 3.6 Test certification

elect the corresponding test scenario to test:

![输入图片说明](images/2021-v1.5.0/image-en-17.png)

Select release after the test is completed

##### 3.7 Mecm application package deployment

Apply to the edge through mecm deployment

App store registration:

![输入图片说明](images/2021-v1.5.0/image-en-19.png)

New registration:

![输入图片说明](images/2021-v1.5.0/image-en-20.png)

MECM->APP management->Package management

Sychronize From App Store

Select the synchronized package for distributed deployment:

![输入图片说明](images/2021-v1.5.0/image-en-21.png)
