#!/bin/bash

set -e

curPath=$(dirname $(readlink -f "$0"))
harborKeyPath=/tmp/harbor-keys
harborRoot=/root/harbor
ENV_IP=$1
HARBOR_ADMIN_PASSWORD=Harbor@12345

# Config /etc/docker/daemon.json for harbor
cp $curPath/daemon.json /etc/docker
sed -i "s/PRIVATE_HARBOR_IP/$ENV_IP/g" /etc/docker/daemon.json
systemctl restart docker.service

# Write SLL Rand
cd /root
openssl rand -writerand .rnd

# Generate RSA Key Files for Harbor
rm -rf $harborKeyPath
mkdir -p $harborKeyPath
cd $harborKeyPath
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -sha512 -days 3650 -subj "/C=CN/ST=Guangzhou/L=Guangzhou/O=example/CN="$ENV_IP -key ca.key -out ca.crt
openssl x509 -inform PEM -in ca.crt -out ca.cert

# Copy Cert File to the New Directory Under /etc/docker/certs.d
harborCertPath=/etc/docker/certs.d/$ENV_IP:443
mkdir -p $harborCertPath
cp $harborKeyPath/ca.cert $harborCertPath

# Modify harbor.yaml
sed -i "s#hostname: .*#hostname: $ENV_IP#g" $curPath/harbor-files/harbor.yml
sed -i "s#certificate: .*#certificate: $harborKeyPath/ca.crt#g" $curPath/harbor-files/harbor.yml
sed -i "s#private_key: .*#private_key: $harborKeyPath/ca.key#g" $curPath/harbor-files/harbor.yml
sed -i "s#data_volume: .*#data_volume: $harborRoot/data_volume#g" $curPath/harbor-files/harbor.yml
sed -i "s#harbor_admin_password: .*#harbor_admin_password: $HARBOR_ADMIN_PASSWORD#g" $curPath/harbor-files/harbor.yml

# Install Harbor
mkdir -p $harborRoot
bash $curPath/harbor-files/install.sh

loop=1
while true
do
    if [ $loop -gt 60 ]; then
        echo "Timeout of waiting for service $1 is ready"
        break
    else
        set +e
        docker login -u admin -p $HARBOR_ADMIN_PASSWORD $ENV_IP > /dev/null 2>&1
        rc=$?
        set -e
        if [ $rc -eq 0 ]; then
            echo "Successfully login Harbor!"
            break
        else
            echo "Loop $loop: waiting for Harbor is ready"
            sleep 5
            loop=$((loop+1))
        fi
    fi
done

# Create appstore, developer and mecm projects
curl -i -k -X POST -H "accept: application/json" -H "Content-type:application/json" -u admin:$HARBOR_ADMIN_PASSWORD --data '{"project_name":"appstore","metadata":{"public":"true"}}' "https://$ENV_IP/api/v2.0/projects"
curl -i -k -X POST -H "accept: application/json" -H "Content-type:application/json" -u admin:$HARBOR_ADMIN_PASSWORD --data '{"project_name":"developer","metadata":{"public":"true"}}' "https://$ENV_IP/api/v2.0/projects"
curl -i -k -X POST -H "accept: application/json" -H "Content-type:application/json" -u admin:$HARBOR_ADMIN_PASSWORD --data '{"project_name":"mecm","metadata":{"public":"true"}}' "https://$ENV_IP/api/v2.0/projects"
