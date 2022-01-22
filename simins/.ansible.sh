#!/bin/bash
#
#   Copyright 2022 Huawei Technologies Co., Ltd.
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

WHAT_TO_DO=$1
if [[ $WHAT_TO_DO != "install" && $WHAT_TO_DO != "uninstall" ]];then
  echo "pass a valid parameter"
  echo "usage:"
  echo "  bash .ansible.sh install"
  echo "  bash .ansible.sh uninstall"
  exit 1
fi
MODE=$(cat config.yml | grep MODE: | grep -v -m1 '#' | cut -d ':' -f2 | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
if [[ $MODE != "aio" && $MODE != "edge" && $MODE != "controller" ]];then
  echo "Invalid MODE"
  echo "Valid MODEs are: AIO, EDGE, CONTROLLER"
  exit 1
fi
DEPLOY_YAML_FILE="eg_${MODE}_${WHAT_TO_DO}.yml"

function _create_inventory()
{
  rm .inventory -f

  LIST_OF_MASTERS=$(cat config.yml | grep MASTER_IP | grep -v -m1 '#' | cut -d ':' -f2 | sed -e "s/,/ /g")

  echo "[master]" > .inventory
  for node_ip in $LIST_OF_MASTERS;
  do
    echo $LIST_OF_MASTERS >> .inventory
  done
  echo "" >> .inventory

  SSH_PORT=$(cat config.yml | grep ANSIBLE_SSH_PORT_MASTER | grep -v -m1 '#' | cut -d ':' -f2 | sed -e "s/,/ /g")
  SSH_USER=$(cat config.yml | grep ANSIBLE_SSH_USER_MASTER | grep -v -m1 '#' | cut -d ':' -f2 | sed -e "s/,/ /g")

  echo "[master:vars]" >> .inventory
  echo "ansible_ssh_port="$SSH_PORT >> .inventory
  echo "ansible_ssh_user="$SSH_USER >> .inventory
  echo "" >> .inventory

  echo "[worker]" >> .inventory
  LIST_OF_WORKERS=$(cat config.yml | grep WORKER_IPS | grep -v -m1 '#' | cut -d ':' -f2 | sed -e "s/,/ /g")

  for node_ip in $LIST_OF_WORKERS;
  do
    echo $node_ip >> .inventory
  done

  # update deploy mode type
  if [[ -z $LIST_OF_WORKERS ]]; then
    sed -i 's/NODE_MODE:.*/NODE_MODE: 'aio'/' $DEPLOY_YAML_FILE
  else
    sed -i 's/NODE_MODE:.*/NODE_MODE: 'muno'/' $DEPLOY_YAML_FILE
  fi

  SSH_PORT=$(cat config.yml | grep ANSIBLE_SSH_PORT_WORKER | grep -v -m1 '#' | cut -d ':' -f2 | sed -e "s/,/ /g")
  SSH_USER=$(cat config.yml | grep ANSIBLE_SSH_USER_WORKER | grep -v -m1 '#' | cut -d ':' -f2 | sed -e "s/,/ /g")

  echo "" >> .inventory
  echo "[worker:vars]" >> .inventory
  echo "ansible_ssh_port="$SSH_PORT >> .inventory
  echo "ansible_ssh_user="$SSH_USER >> .inventory
}

_create_inventory
ansible-playbook --inventory .inventory $DEPLOY_YAML_FILE
