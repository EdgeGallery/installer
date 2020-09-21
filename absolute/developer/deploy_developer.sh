#!/bin/bash
######################################################################################
# Copyright (c) 2019 Huawei Tech and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
#######################################################################################
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
