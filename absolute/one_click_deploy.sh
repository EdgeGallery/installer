#!/bin/bash
#
#   Copyright 2020 Huawei Technologies Co., Ltd.
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
#
# Read the topology from nodelist file and deploy EdgeGallery
#set -x
OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
if [  OS_ID == "centos" ]; then
  yum install net-tools
fi

mkdir -p $PWD/logs/
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
log_file="$PWD/logs/"$TIMESTAMP"_one_click_deploy.log"
exec 1> >(tee -a "$log_file")  2>&1

WHAT_TO_DO=$1
FEATURE=$2
DEPLOY_TYPE=$3
count=0
controller_count=0

function generate_rsa_keys()
{
  ## Generate a RSA keypair through openssl
  openssl genrsa -out rsa_private_key.pem 2048
  openssl rsa -in rsa_private_key.pem -pubout -out rsa_public_key.pem
  openssl pkcs8 -topk8 -inform PEM -in rsa_private_key.pem -outform PEM -passout pass:te9Fmv%qaq -out encrypted_rsa_private_key.pem
}

function  setup_controller_k8s_cluster()
{
  #get the controller nodes from nodelist.ini and make a k8s cluster with controller hosts
  while read line
   do
     nodeinfo="${line}"
     edgeOrController=$(echo ${nodeinfo} | cut -d"|" -f1)
     nodeuser=$(echo ${nodeinfo} | cut -d"|" -f2)
     nodeip=$(echo ${nodeinfo} | cut -d"|" -f3)
     nodeinterface=$(ifconfig | grep -B1 $nodeip | grep -o "^\w*")
     if [[ $edgeOrController == "controller" && ($WHAT_TO_DO == "-i"  || $WHAT_TO_DO == "install") ]]; then
       ((controller_count=controller_count+1))
       PASS_FEATURE="k8s_cluster"
       scp -r ../../platform-mgmt ${nodeuser}@${nodeip}:/tmp/
       sshpass ssh ${nodeuser}@${nodeip} \
       "export NODE_IP=$nodeip; cd /tmp/platform-mgmt/absolute/utilities ;
        bash -x /tmp/platform-mgmt/absolute/utilities/deploy.sh $WHAT_TO_DO $PASS_FEATURE \
       $nodeip $edgeOrController $DEPLOY_TYPE" < /dev/null
     fi
     if [[ $edgeOrController == "controller" && $controller_count == 1 ]]; then
       sshpass ssh ${nodeuser}@${nodeip} \
       "bash -x /tmp/platform-mgmt/absolute/utilities/init_k8s_cluster.sh" < /dev/null
       scp ${nodeuser}@${nodeip}:/tmp/kubeadm_join .
     elif [[ $edgeOrController == "controller" &&  $controller_count  -gt 1 ]]; then
       read join_command < kubeadm_join
       sshpass ssh ${nodeuser}@${nodeip} \
       "$join_command"  < /dev/null
       if [ $? != 0 ];then
         kubeadm "join failed on $nodeip"
       fi
     fi
   done < nodelist.ini
}

function deploy_edgegallery()
{
  while read line
   do
     nodeinfo="${line}"
     edgeOrController=$(echo ${nodeinfo} | cut -d"|" -f1)
     nodeuser=$(echo ${nodeinfo} | cut -d"|" -f2)
     nodeip=$(echo ${nodeinfo} | cut -d"|" -f3)
     nodeinterface=$(ifconfig | grep -B1 $nodeip | grep -o "^\w*")
     if [[ $edgeOrController == "edge"  && \
     ($FEATURE == "mep" || $FEATURE == "all" || $FEATURE == "edge" || \
     $FEATURE == "applcm" || $FEATURE == "infra") ]] || \
     [[ $edgeOrController == "controller"  && ($controller_count == 0 || ($controller_count != 0 && $WHAT_TO_DO == "-r" || \
     $WHAT_TO_DO == "remove" )) &&  $FEATURE != "mep"  \
     && $FEATURE != "edge" && $FEATURE != "applcm" ]]; then
       ((count=count+1))
       if [ $edgeOrController == "controller" ]; then
         controller_count=1
       fi
       PASS_FEATURE=$FEATURE
       #copy k3s scripts to edge/controller node
       scp -r ../../platform-mgmt ${nodeuser}@${nodeip}:/tmp/

       if [[ $FEATURE == "all"  &&  $edgeOrController == "edge" ]]; then
         PASS_FEATURE="edge"
       elif [[ $FEATURE == "all"  &&  $edgeOrController == "controller" ]]; then
         PASS_FEATURE="controller"
       fi
       #start deployment on edge/controller node
       sshpass ssh ${nodeuser}@${nodeip} \
       "export NODE_IP=$nodeip; cd /tmp/platform-mgmt/absolute/utilities ;
        bash -x /tmp/platform-mgmt/absolute/utilities/deploy.sh $WHAT_TO_DO $PASS_FEATURE \
       $nodeip $edgeOrController $DEPLOY_TYPE" < /dev/null
     fi
   done < nodelist.ini
  if [[ $FEATURE == "all"  && ($WHAT_TO_DO == "-r" || $WHAT_TO_DO == "remove") ]]; then
    rm kubeadm_join
  fi
}

if [[ ($WHAT_TO_DO == "-i"  || $WHAT_TO_DO == "install") &&
     !( -f encrypted_rsa_private_key.pem && -f rsa_private_key.pem && -f rsa_public_key.pem) ]]; then
  generate_rsa_keys
fi
setup_controller_k8s_cluster
controller_count=0
deploy_edgegallery
if [ $count -eq 0 ]; then
  echo "update nodelist.ini with valid entries."
fi