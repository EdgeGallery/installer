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
function install_user-mgmt ()
{
  log "Installing User Mgmt"

  ## Create a jwt secret for usermgmt
  kubectl create secret generic user-mgmt-jwt-secret \
    --from-file=publicKey=$K3SDIR/rsa_public_key.pem \
    --from-file=encryptedPrivateKey=$K3SDIR/encrypted_rsa_private_key.pem \
    --from-literal=encryptPassword=te9Fmv%qaq

  helm install user-mgmt-edgegallery edgegallery/usermgmt \
  --set global.oauth2.clients.appstore.clientUrl=http://$NODEIP:$APPSTORE_PORT,\
global.oauth2.clients.developer.clientUrl=http://$NODEIP:$DEVELOPER_PORT,\
global.oauth2.clients.mecm.clientUrl=http://$NODEIP:$MECM_PORT \
--set jwt.secretName=user-mgmt-jwt-secret
  if [ $? -eq 0 ]; then
    wait "user-mgmt-redis" 1
    wait "user-mgmt-postgres" 1
    wait "user-mgmt" 3
    log "User Mgmt Installation Done"
  else
    fail "helm install user-mgmt-edgegallery failed"
    exit 1
  fi
}

function uninstall_user-mgmt ()
{
  log "Uninstalling User Mgmt"
  helm uninstall user-mgmt-edgegallery
  log "User Mgmt Uninstallation Done"
}
