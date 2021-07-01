#!/bin/sh
#
#   Copyright 2021 Huawei Technologies Co., Ltd.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# Restore NFS backup data

if [ -z $1 ]; then
    echo "Error: Failed to restore nfs data"
    echo "Usage: bash restore_nfs_data.sh /home/eg-data-backup-xxx.tar.gz"
    exit 1
fi

# Restart docker service to make nfs stop temporarily before unarchive data
systemctl restart docker.service

DATA_FILE=$1
tar -zxf $DATA_FILE -C /
echo "NFS data have been restored to /edgegallery/data"
