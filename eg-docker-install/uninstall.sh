#!/bin/bash

set -e

curPath=$(dirname $(readlink -f "$0"))

echo "==========Uninstall Developer=========="
cd $curPath/developer
docker-compose down

echo "==========Uninstall Usermgmt=========="
cd $curPath/user-mgmt
docker-compose down

echo "==========Uninstall Setup=========="
cd $curPath/setup
docker-compose down
