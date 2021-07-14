###    **部署完成实例化测试验证** 


**1.安装完成后的检查** 

使用ansible部署Edgegallery成功后会有部署提示，如果没有部署则表示部署过程中某个模块部署失败因而部署脚本退出

kubectl get pod --all-namespaces  			// 检查pod的运行状态，正常情况下pod的状态时running，

如果pod 的状态不是running 则需要进一步定位，例如：

kubectkl  delete pod podname –n namespaces   // 重启pod

kubectl describe pod podname –n namespaces   // 查看pod

最后一步则需要手动实例化测试

 **2.手动实例化测试** 

EdgeGallery web页面登陆需要用Chrome浏览器

 **2.1 设置沙箱环境** 

EdgeGallery新增了超级管理员权限，目前申请的用户都为租户，需要通过管理员权限设置修改权限

账号：admin  密码：Admin@321 建议登录后修改密码

登录网址: https://PORTAL_IP:30091   PORTAL_IP 是安装时配置的PORTAL_IP 的IP（未配置PORTAL IP默认为master IP）

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/093945_89cc6335_8040887.png "屏幕截图.png")

管理员账号可以对租户进行管理：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/094118_fb48b3ec_8040887.png "屏幕截图.png")

使用管理员权限账号添加沙箱环境：

登录网址: https://PORTAL_IP:30092  

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/093757_6f163777_8040887.png "屏幕截图.png")

添加K8S或者openstack沙箱环境（端口号为mecm注册mepm系统的端口）：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/093601_ab43bef8_8040887.png "屏幕截图.png")

 **2.2 登录MECM界面** 

a)登录网址: https://PORTAL_IP:30093   PORTAL_IP 是安装时在env.sh配置的PORTAL_IP 的IP

b)在登录网址后看到的是MECM的概览页面此时登录用的guest用户 ，只有浏览页面的权限，不能执行有效的操作，需要点击右上角的“登录”跳转到登录页面

输入账号、密码、确认密码、电话、勾选我已同意并阅读、点击同意协议：

输入账号密码，拖动滚动条完成验证并点击登录：


 **2.3 使用管理员账号进行外部系统注册** 

MEPM注册

登录MECM后，点击系统→MEPM注册系统

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/100320_87c7c1c1_8040887.png "屏幕截图.png")

点击‘新增注册’注册MEPM ,  IP地址为边缘节点IP,多节点安装只需输入master node IP即可，端口是31252

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/100436_50088394_8040887.png "屏幕截图.png")


应用市场注册：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/100759_2830971f_8040887.png "屏幕截图.png")

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/101011_b57c8240_8040887.png "屏幕截图.png")

边缘节点注册

点击边缘节点→新增注册

输入IP地址为边缘节点IP,多节点安装只需输入master节点IP即可,选择安装环境的架和硬件能力

（没有可以不选）硬件品牌和型号,地址经纬度，选择MEPM ,填写边缘IP，输入边缘仓库端口

点击确认

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/101148_75a5d56d_8040887.png "屏幕截图.png")

配置文件上传：

配置文件为要的边缘节点/root/.kube/ 下config文件，下载config文件，点击上传文件，看到提示‘你已成功上传配置文件’，则上传成功

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/101259_da7bdd8d_8040887.png "屏幕截图.png")

 **2.4 在Developer页面部署测试** 

网址:https://PORTAL_IP:30092   PORTAL_IP 是安装时在env.sh配置的PORTAL_IP 的IP

添加新项目：

登录后点击“工作空间”→ “应用集成” 

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/101746_ea985d82_8040887.png "屏幕截图.png")

按照上述选择完成项目创建。


上传镜像：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/102123_218ac801_8040887.png "屏幕截图.png")

上传yaml文件（支持模板下载）：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/102153_d9211e3e_8040887.png "屏幕截图.png")

开始部署:

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/105936_ac1fd161_8040887.png "屏幕截图.png")

部署完成：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/110014_0d4245b7_8040887.png "屏幕截图.png")


点击应用认证进行安全，遵从性以及沙箱测试：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/110223_61d0bdb4_8040887.png "屏幕截图.png")


等待前面测试完成后，点击发布即可发布到APP应用商店

 **3 虚机部署**

 下面部署虚机部署与容器部署不一样的地方（如需基于虚拟机开发可参考虚机开发docs仓库下/Projects/Developer/vm_app_guide.md文档）

创建项目是选择虚拟机：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/102721_c84ba490_8040887.png "屏幕截图.png")

配置资源：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/102840_caf60d65_8040887.png "屏幕截图.png")

规格选择：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/103036_40168748_8040887.png "屏幕截图.png")

网络配置：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/103150_b181e7d5_8040887.png "屏幕截图.png")

部署调测：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/103234_ab5c4ef6_8040887.png "屏幕截图.png")

应用代码上传：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/103317_d9326236_8040887.png "屏幕截图.png")

远程登录虚拟机：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/103607_422061fa_8040887.png "屏幕截图.png")

部署配置完成后可以生成镜像：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/103830_ec141a4e_8040887.png "屏幕截图.png")

发布沙箱其余操作与容器一样，在mecm上同样可以完成同步部署：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/104126_b01a2503_8040887.png "屏幕截图.png")

虚机部署需要在openstack上提前配置好网络：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/104328_650256cf_8040887.png "屏幕截图.png")

虚机机规格建议和EG中规格一致：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/104547_33ecf2a9_8040887.png "屏幕截图.png")

虚机系统镜像可以通过EG上传也可以在openstack上传：

![输入图片说明](https://images.gitee.com/uploads/images/2021/0708/104657_a21f8b47_8040887.png "屏幕截图.png")




