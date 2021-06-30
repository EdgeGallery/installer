#！/bin/sh
# NFS data backup

mkdir /home/backup
 

cp -r /edgegallery/data  /home/backup/
 
read -p "Please input a backupname:" MY_FILE_NAME1
echo your input backupname="$MY_FILE_NAME1"

tar -zcPvf /home/"$MY_FILE_NAME1".tar.gz /home/backup


 

rm -rf /home/backup/

