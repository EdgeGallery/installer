#!/bin/bash
######################################################################################
# Copyright (c) 2019 Huawei Tech and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
#######################################################################################
function install_applcm ()
{
  log "Installing applcm module"
  if [ $KERNEL_ARCH == 'aarch64' ]; then
    log "applcm helm-chart for arm is getting ready"
    log "time being try to deploy applcm on arm manually :)"
  else
    ## Create a jwt public key secret for applcm
    kubectl create secret generic applcm-jwt-public-secret \
      --from-file=publicKey=$K3SDIR/rsa_public_key.pem
    helm install --name applcm-edgegallery edgegallery/applcm \
      --set jwt.publicKeySecretName=applcm-jwt-public-secret
    if [ $? -eq 0 ]; then
      wait "applcm" 1
      log "applcm module Installation Done"
    else
      fail "helm install --name applcm-edgegallery failed"
      exit 1
    fi
  fi
}

function uninstall_applcm ()
{
  if [ $KERNEL_ARCH == 'aarch64' ]; then
    log "applcm wan't installed on your arm host"
  else
    log "Uninstalling applcm module"
    helm uninstall applcm-edgegallery
    log "applcm module Uninstallation Done"
  fi
}
