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
function create_host_volume()
{
  log "Creating host path voulmes ." $GREEN
  mkdir -p $VOLUMES
  ls -l /volumes/
}

function remove_host_volume()
{
  log "Removing host path voulmes ." $GREEN
  sudo rm -rf $VOLUMES
}

function install_mecm()
{
  log "Installing MECM." $GREEN
  install_mecm_prerequisite
  create_host_volume
  helm install mecm-edgegallery edgegallery/mecm \
  --set global.oauth2.authServerAddress=http://$NODEIP:$USER_MGMT
  if [ $? -eq 0 ]; then
    wait "api-handler-infra" 1
    wait "bpmn-infra" 1
    wait "catalog-db-adapter" 1
    wait "request-db-adapter" 1
    wait "vfc-catalog" 1
    wait "mecesr" 1
    wait "mariadb" 1
    wait "mecm-fe" 1
    log "MECM Installation Done." $GREEN
  else
    fail "helm install mecm-edgegaller failed"
    exit 1
  fi
}

function uninstall_mecm()
{
  log "Uninstalling MECM." $GREEN
  helm uninstall mecm-edgegallery
  remove_host_volume
  log "MECM Uninstallation Done." $GREEN
}
