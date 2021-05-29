#!/bin/bash

set -e

function wait_for_file() {
  loop=1
  while true
  do
    if [[ $loop -gt 5 ]]; then
      echo "Timeout of waiting for file $1 is ready"
      break
    else
      if [ ! -f $1 ]; then
        echo "loop $loop: waiting for $1 is ready"
        sleep 2
        loop=$((loop+1))
      else
        break
      fi
    fi
  done
}

function wait_for_service() {
  loop=1
  while true
  do
    if [[ $loop -gt 60 ]]; then
      echo "Timeout of waiting for service $1 is ready"
      break
    else
      if [[ "$(curl -sL -w '%{http_code}' $1)" = "200" ]]; then
        break
      else
        echo "loop $loop: waiting for service $1 is ready"
        sleep 5
        loop=$((loop+1))
      fi
    fi
  done
}

if [[ -z $1 ]]; then
  echo "Error: Require the IP of this machine as input"
  exit 1
fi

curPath=$(dirname $(readlink -f "$0"))

echo "==========Setup for the Install=========="
chmod 666 /var/run/docker.sock
cd $curPath/setup
docker-compose up -d

wait_for_file /tmp/keys/rsa_public_key.pem
wait_for_file /tmp/keys/encrypted_rsa_private_key.pem

export ENV_IP=$1
export JWT_PUBLIC_KEY=`cat /tmp/keys/rsa_public_key.pem`
export JWT_ENCRYPTED_PRIVATE_KEY=`cat /tmp/keys/encrypted_rsa_private_key.pem`

echo "==========Install UserMgmt=========="
cd $curPath/user-mgmt
docker-compose up -d

wait_for_service http://$ENV_IP:30067

echo "==========Install Appstore=========="
cd $curPath/appstore
docker-compose up -d

wait_for_service http://$ENV_IP:30091

echo "==========Install ATP=========="
cd $curPath/atp
docker-compose up -d

wait_for_service http://$ENV_IP:30094

echo "==========Install Developer=========="
cd $curPath/developer
docker-compose up -d

wait_for_service http://$ENV_IP:30092
