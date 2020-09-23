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
OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OUTPUT=""
KERNEL_ARCH=`uname -m`
set -x
source /tmp/platform-mgmt/absolute/utilities/env.sh
source /tmp/platform-mgmt/absolute/utilities/common_utils.sh

function  show_help()
{
  echo " "
  echo " one_click.sh => This script helps setting up KubeEdge."
  echo " "
}
if [ -z "$1" ] || [ $1 == "--help" ] || [ $1 == "-h" ]; then
  show_help
  exit 0
fi

if [ "$#" -ge 6 ]; then
    echo "Illegal number of parameters"
    exit 0
fi

COMMAND=$1
FEATURE=$2
NODEIP=$3
echo $NODEIP
EdgeOrController=$4

function verify_and_run()
{
    if [ $COMMAND == "-r" ] || [ $COMMAND == "remove" ]; then
      keadm reset 
    fi
    if [ $COMMAND == "-i" ]; then
      cd /tmp/platform-mgmt/kubeEdge/pfm-kedge
      curl -LO https://github.com/kubeedge/kubeedge/releases/download/v1.4.0/keadm-v1.4.0-linux-amd64.tar.gz
      tar -xzvf keadm-v1.4.0-linux-amd64.tar.gz
      rm keadm-v1.4.0-linux-amd64.tar.gz
      cd keadm-v1.4.0-linux-amd64/keadm/
      cp keadm /usr/bin
      cd ../..
      rm -rf keadm-v1.4.0-linux-amd64/
    fi
    if [ $COMMAND == "-r" ]; then
      rm /usr/bin/keadm
      rm -r /var/lib/kubeedge/
      rm -r /etc/kubeedge/
    fi
    if [[ $COMMAND == "-i" &&  $EdgeOrController == "edge" ]]; then
      install_docker
    elif [[ $COMMAND == "-i" && $EdgeOrController == "controller" ]]; then
      install_ke_controller
    fi
}

function install_ke_controller()
{
  keadm init
  cd /tmp/platform-mgmt/kubeEdge/pfm-kedge
  rm tkn.txt
  echo "Wait for 5 seconds"
  sleep 5s 
  keadm gettoken >> tkn.txt
}

log "Current Directory $K3SDIR" $GREEN
log "Env Directory $ENVDIR" $GREEN
verify_and_run
