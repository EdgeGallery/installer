#!/bin/bash
######################################################################################
# Copyright (c) 2019 Huawei Tech and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
#######################################################################################
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
