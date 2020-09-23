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
