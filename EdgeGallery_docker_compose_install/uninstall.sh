#!/bin/bash

set -e

curPath=$(dirname $(readlink -f "$0"))

echo "==========Uninstall Developer=========="
cd $curPath/developer
docker-compose down

echo "==========Uninstall ATP=========="
cd $curPath/atp
docker-compose down

echo "==========Uninstall Appstore=========="
cd $curPath/appstore
docker-compose down

echo "==========Uninstall Usermgmt=========="
cd $curPath/user-mgmt
docker-compose down

echo "==========Uninstall Setup=========="
cd $curPath/setup
docker-compose down
rm -rf /tmp/keys
