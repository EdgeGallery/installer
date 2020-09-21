#!/bin/bash

##############################################################################
# Copyright (c) 2019 Huawei Tech and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
export RED='\033[0;31m'
export NC='\033[0m'
export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export YELLOW='\033[1;33m'
export CYAN='\033[0;36m'
export PURPLE='\033[0;35m'
export ORANGE='\033[0;33m'

#Timer
export POD_READY_WAIT_TIME=1200

#VOLUMES in hostpath
export VOLUMES="/volumes/so/config/api-handler-infra/onapheat " 
VOLUMES+="/volumes/so/config/bpmn-infra/onapheat "
VOLUMES+="/volumes/so/ca-certificates/onapheat "
VOLUMES+="/volumes/so/config/catalog-db-adapter/onapheat "
VOLUMES+="/volumes/mariadb/docker-entrypoint-initdb.d "
VOLUMES+="/volumes/mariadb/conf.d "
VOLUMES+="/volumes/so/config/request-db-adapter/onapheat "

#NodePort Configuration
#To be added in future

#Ingress configuration
#Get configuration details here https://github.com/EdgeGallery/helm-charts#ingress
export auth_domain=auth.org
export appstore_domain=appstore.org
export developer_domain=developer.org
export mecm_domain=mecm.org
#tls configuration optional
export tls_enabled=false
export tls_secretName=edgegallery-ingress-secret
