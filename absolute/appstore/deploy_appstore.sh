#!/bin/bash
######################################################################################
# Copyright (c) 2019 Huawei Tech and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
#######################################################################################
function install_appstore ()
{
  log "Installing Appstore"
  helm install appstore-edgegallery edgegallery/appstore \
  --set global.oauth2.authServerAddress=http://$NODEIP:$USER_MGMT
  if [ $? -eq 0 ]; then
    wait "appstore-be" 2
    wait "appstore-fe" 1
    log "Appstore Installation Done"
  else
    fail "helm install appstore-edgegallery failed"
    exit 1
  fi
}

function uninstall_appstore ()
{
  log "Uninstalling Appstore"
  helm uninstall appstore-edgegallery
  log "Appstore Uninstallation Done"
}
