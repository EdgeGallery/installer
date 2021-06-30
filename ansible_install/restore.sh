#！/bin/sh
# resture NFS backup data

ls /home/

read -p "Please input a restorebackup name:" MY_FILE_NAME1
echo your input restorebackup name="$MY_FILE_NAME1"

tar -zxvf /home/"$MY_FILE_NAME1".tar.gz

systemctl  restart docker

cp -r /home/home/beifen/data/* /edgegallery/data/


rm -rf /home/home