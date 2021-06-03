#!/bin/bash

set -e

curPath=$(dirname $(readlink -f "$0"))

echo "==========Uninstall MEPM=========="
cd $curPath/mepm
docker-compose down

echo "==========Uninstall Setup=========="
cd $curPath/setup
docker-compose down

echo "==========Uninstall MEP=========="
cd $curPath/mep
docker-compose down

rm -rf /tmp/.mep_tmp_cer
