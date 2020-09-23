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
function install_developer ()
{
  log "Installing Developer module"
  helm install developer-edgegallery edgegallery/developer \
  --set global.oauth2.authServerAddress=http://$NODEIP:$USER_MGMT
  if [ $? -eq 0 ]; then
    wait "developer-be" 2
    wait "developer-fe" 1
    log "Developer module Installation Done"
  else
    fail "helm install developer-edgegallery failed"
    exit 1
  fi
}

function uninstall_developer ()
{
  log "Uninstalling Developer module"
  helm uninstall developer-edgegallery
  log "Developer module Uninstallation Done"
}
