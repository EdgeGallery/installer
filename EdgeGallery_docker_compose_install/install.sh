#!/bin/bash

set -e

if [[ -z $1 ]]; then
  echo "Error: Require the IP of this machine as input"
  exit 1
fi

curPath=$(dirname $(readlink -f "$0"))

echo "==========Setup for the Install=========="
cd $curPath/setup
docker-compose up -d

export ENV_IP=$1
export JWT_PUBLIC_KEY=`cat /tmp/keys/rsa_public_key.pem`
export JWT_ENCRYPTED_PRIVATE_KEY=`cat /tmp/keys/encrypted_rsa_private_key.pem`

echo "==========Install UserMgmt=========="
cd $curPath/user-mgmt
docker-compose up -d

loop=1
until curl -k -f http://$ENV_IP:30067
do
  if [[ $loop -gt 30 ]]; then
    echo "Timeout of waiting for auth server ready"
    exit 1
  fi
  echo "loop $loop: waiting for auth server ready"
  sleep 2
  loop=$((loop+1))
done

echo "==========Install Developer=========="
cd $curPath/developer
docker-compose up -d
