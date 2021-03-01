                       EdgeGallery_1.0版本升级安装流程

    升级新版本前需要备份虚机上相关重要文件，防止文件丢失。如果之前安装的env.sh配置文件还在，也可以保存。

1.在https://release.edgegallery.org/下载对应的安装包。
        (建议使用v1.0.1版本的包)
2.解压安装包。

3.配置env.sh.
        参考之前安装时的env.sh文件，修改env.sh文件并保存。
        source env.sh           /环境变量生效

4.卸载       
bash eg.sh -u all        /完全卸载，如果不卸载K8S的使用bash eg.sh -u
只卸载EdgeGallery，建议完成卸载
        helm list              /查看是否还有helm安装包，如果有helm delete *删掉

5.安装1.0.1版本
        bash eg.sh  -i

6.等待安装完成，按照EdgeGallery_v1.0安装文档进行测试验证。
