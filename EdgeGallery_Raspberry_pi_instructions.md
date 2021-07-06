# install EdgeGallery on raspberrypi

### 介绍
在树莓派上安装EdgeGallery。

### 安装前准备
| 资源  | 版本  | 规格  |
|---|---|---|
| 树莓派  | 4B  |  >8G |
| SD卡/读卡器  |  NA |  >16G |
| 电脑/显示器  |  Win10 | 显示器支持HDMI  |



### 安装步骤

#### 准备系统
- 格式化SD卡，建议使用SD Card Formatter
- 下载[树莓派Imager](https://downloads.raspberrypi.org/imager/imager_1.6.exe)

#### 下载操作系统镜像
以OpenEuler为例
- 登录[openEuler](https://openeuler.org/zh/download/)社区网站。
- 单击卡片 openEuler 20.09 上的“下载”按钮。
- 单击“raspi_img”，进入树莓派镜像的下载列表。
  - aarch64：AArch64 架构的镜像。
- 单击“aarch64”，进入树莓派 AArch64 架构镜像的下载列表。
- 单击`openEuler-20.09-raspi-aarch64.img.xz`，将 openEuler 发布的树莓派镜像下载到本地。
- 单击`openEuler-20.09-raspi-aarch64.img.xz.sha256sum`，将 openEuler 发布的树莓派镜像的校验文件下载到本地。
- 解压`openEuler-20.09-raspi-aarch64.img.xz` 为 `openEuler-20.09-raspi-aarch64.img`


#### 格式化SD卡
- 使用SD Card Formatter，选择要格式化的盘符。
  - 如果未安装过镜像，只会有一个盘符，选择此盘符即可。
  - 如果安装过镜像，会有3个盘符（如：E，F，G），选择boot分区的盘符。
- 在 `Formatting Options`中选择`Quick format`
- 格式化完成。

#### 烧录/刷新镜像
镜像估计市面上的比较多，这里选择树莓派官方工具 Imager。
树莓派Imager原生提供多种Raspbian镜像。同时也可以选择本地镜像。
- 准备一个笔记本，插入格式化完成的SD卡
- 下载安装Raspberry Pi Imager
- 选择`CHOOSE OS`,选择`Use Custom`
  - 选择刚才已经下载好的`openEuler-20.09-raspi-aarch64.img`文件
- 选择`CHOOSE STORAGE`,选择刚才插入电脑的SD卡。
- 选择`WRITE`.
- 烧录完成。

#### 登陆树莓派
一般树莓派有多种输出接口，可以选择接入如HDMI Mini接口，并连接键盘。
- 连接显示器
- 插入键盘
- 登陆系统。`openEuler-20.09-raspi-aarch64.img`默认密码root/openeuler
- 连接网络
  - 连接有线网络：网口直接插入网线。
  - 连接Wifi：Raspberry Pi 4B有Wifi模块，可以连接wifi。OpenEuler连接wifi
    - 检查wifi 模块是否启用：`nmcli radio wifi`.如果是disable，启用：`nmcli radio wifi on`
    - 获取wifi list。`nmcli dev wifi list`
    - 连接wifi。`nmcli dev wifi connect wifi_name password wifi-password`

#### 修改Root空间
由于默认根目录分区空间很小，需要修改扩容root分区。参考OpenEuler官方指导：

1. 在 root 权限下执行 fdisk -l 命令查看磁盘分区信息。命令和回显如下：

    ```
    # fdisk -l
    Disk /dev/mmcblk0: 14.86 GiB, 15931539456 bytes, 31116288 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: dos
    Disk identifier: 0xf2dc3842
    Device         Boot   Start     End Sectors  Size Id Type
    /dev/mmcblk0p1 *       8192  593919  585728  286M  c W95 FAT32 (LBA)
    /dev/mmcblk0p2       593920 1593343  999424  488M 82 Linux swap / Solaris
    /dev/mmcblk0p3      1593344 5044223 3450880  1.7G 83 Linux
    ```

SD 卡对应盘符为 /dev/mmcblk0，包括 3 个分区，分别为

- /dev/mmcblk0p1：引导分区
- /dev/mmcblk0p2：交换分区
- /dev/mmcblk0p3：根目录分区

这里我们需要将根目录分区 `/dev/mmcblk0p3` 进行扩容。

2. 在 root 权限下执行 `fdisk /dev/mmcblk0` 命令进入到交互式命令行界面，按照以下步骤扩展分区。


- 输入 `p`，查看分区信息。
- 记录分区 `/dev/mmcblk0p3` 的起始扇区号，即 `/dev/mmcblk0p3` 分区信息中 Start 列的值，示例中为 `1593344`。
- 输入 `d`，删除分区。
- 输入 `3` 或直接按 Enter，删除序号为 3 的分区，即 `/dev/mmcblk0p3` 分区。
- 输入 `n`，创建新的分区。
- 输入 `p` 或直接按 Enter，创建 Primary 类型的分区。
- 输入 `3` 或直接按 Enter，创建序号为 3 的分区，即 `/dev/mmcblk0p3` 分区。
- 输入新分区的起始扇区号，即第 1 步中记录的起始扇区号，示例中为 1593344。
- 按 Enter，使用默认的最后一个扇区号作为新分区的终止扇区号。
- 输入 `N`，不修改扇区标记。
- 输入 `w`，保存分区设置并退出交互式命令行界面。


3. 在 root 权限下执行 `fdisk -l` 命令查看磁盘分区信息，以确保磁盘分区正确。命令和回显如下：

    ```
    # fdisk -l
    Disk /dev/mmcblk0: 14.86 GiB, 15931539456 bytes, 31116288 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: dos
    Disk identifier: 0xf2dc3842
    Device         Boot   Start      End  Sectors  Size Id Type
    /dev/mmcblk0p1 *       8192   593919   585728  286M  c W95 FAT32 (LBA)
    /dev/mmcblk0p2       593920  1593343   999424  488M 82 Linux swap / Solaris
    /dev/mmcblk0p3      1593344 31116287 29522944 14.1G 83 Linux
    ```

4. 在 root 权限下执行 `resize2fs /dev/mmcblk0p3`，增大未加载的文件系统大小。

5. 执行 `df -lh` 命令查看磁盘空间信息，以确保根目录分区已扩展。

#### 安装Docker/Docker-Compose
OpenEuler可以使用`yum`安装Docker，也可以使用官方包安装，此处以官方包为例：
- 获取Docker安装包
`cd ~  && wget https://download.docker.com/linux/static/stable/aarch64/docker-19.03.5.tgz`
- 安装
 
    ```
    tar xvpf docker-19.03.5.tgz
        cp -p docker/* /usr/bin
             
    systemctl daemon-reload
    systemctl restart docker
    ```
- 验证
    ```
    docker version
    docker run helloworld
    ```
由于Docker Compose官方不提供arm版本docker compose镜像，有两种方式可以安装docker composearm版本。
- 自行编译，可参考[链接](https://www.toutiao.com/i6804465376827539971/)
- 获取已经编译好的dockerfile，可参考：https://gitee.com/Gao_Victor/raspberrypi/tree/master/docker-compose-aarch64

#### 安装EdgeGallery
- 参考 https://gitee.com/edgegallery/installer/tree/master/EdgeGallery_docker_compose_install
- Notice: 不能直接下载已经打包好的镜像，此出镜像是x86，最好是直接运行install脚本
- 参考安装方式：可以只安装Edge侧。

### 参考链接
https://www.bookstack.cn/read/openeuler-20.09-zh/Installation-%E5%AE%89%E8%A3%85%E6%8C%87%E5%AF%BC-1.md
