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
set -x
WHAT_TO_DO=$1
FEATURE=$2
count=0
controller_count=0

tkn=''
KADM_PORT=10000
CONTROLLERIP=0



function deploy_kedge()
{
  while read line
   do
     nodeinfo="${line}"
     edgeOrController=$(echo ${nodeinfo} | cut -d"|" -f1)
     nodeuser=$(echo ${nodeinfo} | cut -d"|" -f2)
     nodeip=$(echo ${nodeinfo} | cut -d"|" -f3)
     nodeinterface=$(ifconfig | grep -B1 $nodeip | grep -o "^\w*")
     if [ $edgeOrController == "controller" ]; then
       controller_count=1
     fi
     PASS_FEATURE=$FEATURE
     
     #Testing
     #sshpass ssh ${nodeuser}@${nodeip} \
     #"mkdir -p /tmp/platform-mgmt/kubeEdge/pfm-kedge;
     #mkdir -p /tmp/platform-mgmt/utilities" < /dev/null
     #scp -r ../../../platform-mgmt/kubeEdge/pfm-kedge ${nodeuser}@${nodeip}:/tmp/platform-mgmt/kubeEdge
     #scp ../../../platform-mgmt/utilities/env.sh ${nodeuser}@${nodeip}:/tmp/platform-mgmt/utilities
     #scp ../../../platform-mgmt/utilities/common_utils.sh ${nodeuser}@${nodeip}:/tmp//platform-mgmt/utilities

     scp -r ../../../platform-mgmt ${nodeuser}@${nodeip}:/tmp/

     if [[ $edgeOrController == "controller" ]]; then
           CONTROLLERIP=${nodeip}
     fi

     if [[ $FEATURE == "all"  &&  $edgeOrController == "edge" ]]; then
       PASS_FEATURE="edge"
     elif [[ $FEATURE == "all"  &&  $edgeOrController == "controller" ]]; then
       PASS_FEATURE="controller"
     fi
     #start deployment on edge/controller node
     sshpass ssh ${nodeuser}@${nodeip} \
     "export NODE_IP=$nodeip;
      bash -x /tmp/platform-mgmt/kubeEdge/pfm-kedge/core.sh $WHAT_TO_DO $PASS_FEATURE \
     $nodeip $edgeOrController" < /dev/null
     if [[ $edgeOrController == "controller" && ($WHAT_TO_DO == "-i"  || $WHAT_TO_DO == "install") ]]; then
       scp root@${nodeip}:/tmp/platform-mgmt/kubeEdge/pfm-kedge/tkn.txt tkn.txt
       while IFS= read -r line; do
         tkn=$line
       done < tkn.txt
       rm tkn.txt
     fi
     if [[ $edgeOrController == "edge" && ($WHAT_TO_DO == "-i"  || $WHAT_TO_DO == "install") ]]; then
       sshpass ssh ${nodeuser}@${nodeip} \
       "keadm join --cloudcore-ipport=$CONTROLLERIP:$KADM_PORT --token=$tkn" < /dev/null
     fi
     #sshpass ssh ${nodeuser}@${nodeip} \
     #"rm -rf /tmp/platform-mgmt/"
   done < nodelist.ini
}

controller_count=0
deploy_kedge
if [ $count -eq 0 ]; then
  echo "update nodelist.ini with valid entries."
fi
set +x
