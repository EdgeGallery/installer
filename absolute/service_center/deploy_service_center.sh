#!/bin/bash
######################################################################################
# Copyright (c) 2019 Huawei Tech and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
#######################################################################################
function install_service-center ()
{
  log "Installing Service-Center"
  helm install service-center-edgegallery edgegallery/servicecenter
  if [ $? -eq 0 ]; then
    wait "service-center" 1
    log "Service-Center Installation Done"
  else
    fail "helm install service-center-edgegallery failed"
    exit 1
  fi
}

function uninstall_service-center ()
{
  log "Uninstalling Service-Center"
  helm uninstall service-center-edgegallery
  log "Service-Center Uninstallation Done"
}
