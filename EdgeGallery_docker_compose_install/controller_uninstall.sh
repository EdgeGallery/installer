#!/bin/bash

set -e

curPath=$(dirname $(readlink -f "$0"))

echo "==========Uninstall MECM-MEO=========="
cd $curPath/mecm-meo
docker-compose down

echo "==========Uninstall Developer=========="
cd $curPath/developer
docker-compose down

echo "==========Uninstall Appstore and ATP=========="
cd $curPath/appstore-atp
docker-compose down

echo "==========Uninstall Usermgmt=========="
cd $curPath/user-mgmt
docker-compose down

echo "==========Uninstall Setup=========="
cd $curPath/setup
docker-compose down

echo "==========Uninstall Harbor=========="
cd $curPath/harbor/harbor-files
docker-compose down
rm -rf /root/harbor
