#!/bin/bash
######################################################################################
# Copyright (c) 2019 Huawei Tech and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
#######################################################################################

########################################################################################
#                                                                                      #
# The script is to setup the MEP using microk8s.                                       #
########################################################################################
########################################################################################
OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
K3SDIR=$PWD/../
OUTPUT=""
KERNEL_ARCH=`uname -m`
set -x
source $K3SDIR/utilities/env.sh
source common_utils.sh
source $K3SDIR/mep/deploy_mep.sh
source $K3SDIR/mepm/applcm/deploy_applcm.sh
source $K3SDIR/mecm/deploy_mecm.sh
source $K3SDIR/appstore/deploy_appstore.sh
source $K3SDIR/developer/deploy_developer.sh
source $K3SDIR/user_mgmt/deploy_user_mgmt.sh
source $K3SDIR/service_center/deploy_service_center.sh

function  show_help()
{
  echo " "
  echo " one_click.sh => This script helps setting up MEP using K3s."
  echo " SYNTAX   ./one_click.sh -{i|r} -{ all | mep | mecm } "
  echo " -h Help"
  echo " -i Install"
  echo " -r Remove"
  echo " "
  echo " Features: "
  echo " all  [MEP & MECM platform]"
  echo " mep  [Clean, uninstall, existing MEP and install again]"
  echo " mecm [Clean, uninstall, existing MECM and install again]"
  echo " "
}

if [ -z "$1" ] || [ $1 == "--help" ] || [ $1 == "-h" ]; then
  show_help
  exit 0
fi

if [ "$#" -ge 6 ]; then
    echo "Illegal number of parameters"
    exit 0
fi

DEVELOPER_PORT=30092
APPSTORE_PORT=30091
MECM_PORT=30093
USER_MGMT=30067

COMMAND=$1
FEATURE=$2
NODEIP=$3
echo $NODEIP
EdgeOrController=$4
#default deploy type - nodePort
if [ -z $5 ]; then
  DEPLOY_TYPE="nodePort"
else
  DEPLOY_TYPE=$5
fi

function install_prerequisite()
{
  log "Installing prerequisites ." $GREEN
  install_docker
  install_kubernetes_cluster
  install_helm
}

function uninstall_prerequisite()
{
  log "UnInstalling prerequisites ." $GREEN
  uninstall_helm
  uninstall_kubernetes
}

function install_EdgeGallery ()
{
   if [ $FEATURE == 'k8s_cluster' ]; then
     install_docker
     install_kubernetes_cluster
     exit 0
   fi
   install_prerequisite
   if [ $FEATURE == 'infra' ];then
     log "Infrastructure Installation Done on ""$EdgeOrController" $GREEN
     exit 0
   elif [ $FEATURE == 'applcm' ]; then
     install_applcm
   elif [ $FEATURE == 'mep' ]; then
     if kubectl_loc="$(type -p "$kubectl")" || [[ $kubectl_loc ]]; then
       log "MEP is Already UP" $GREEN
       exit 0
     fi
     install_mep
   elif [ $FEATURE == 'edge' ]; then
     install_mep
     install_applcm
   elif [[ $FEATURE == 'mecm' ]]; then
     install_mecm
   elif [[ $FEATURE == 'appstore' || $FEATURE == 'developer' || \
     $FEATURE == 'service-center' || $FEATURE == 'user-mgmt'  ]]; then
     install_$FEATURE
   elif [[ $FEATURE == 'controller' &&  $DEPLOY_TYPE == 'nodePort' ]]; then
     install_service-center
     install_user-mgmt
     install_mecm
     install_appstore
     install_developer
   elif [[ $FEATURE == 'controller' &&  $DEPLOY_TYPE == 'ingress' ]]; then
     install_controller_with_ingress
   else
     log "Unknown feature $FEATURE" $RED
     show_help
     exit 0
   fi
   show_k3s_status
}

function uninstall_EdgeGallery ()
{
   if [ $FEATURE == 'infra' ];then
     uninstall_prerequisite
     if [ $? -eq 0 ]; then
       log "Infrastructure UnInstallation Completed on ""$EdgeOrController" $GREEN
       exit 0
     else
       log "Infrastructure UnInstallation Failed on ""$EdgeOrController" $GREEN
       exit 1
     fi
   elif [ $FEATURE == 'applcm' ]; then
     uninstall_applcm
   elif [ $FEATURE == 'mep' ]; then
     if ! kubectl_loc=$(type -p kubectl) || [[ -z $kubectl_loc ]] ; then
       log "MEP is not running. Clean complete" $YELLOW
       exit 0
     fi
     uninstall_mep
   elif [ $FEATURE == 'edge' ]; then
     uninstall_mep
     uninstall_applcm
     uninstall_prerequisite
   elif [[  $FEATURE == 'mecm' ]]; then
     uninstall_mecm
   elif [[ $FEATURE == 'appstore' || $FEATURE == 'developer' || \
     $FEATURE == 'service-center' || $FEATURE == 'user-mgmt'  ]]; then
     uninstall_$FEATURE
   elif [[ $FEATURE == 'controller' &&  $DEPLOY_TYPE == 'nodePort' ]]; then
     uninstall_mecm
     uninstall_appstore
     uninstall_developer
     uninstall_user-mgmt
     uninstall_service-center
     uninstall_prerequisite
   elif [[ $FEATURE == 'controller' &&  $DEPLOY_TYPE == 'ingress' ]]; then
     uninstall_controller_with_ingress
     uninstall_prerequisite
   else
     log "Unknown feature $FEATURE" $RED
     show_help
     exit 0
   fi
}

function verify_and_run()
{
  if [ $COMMAND == "-i" ] || [ $COMMAND == "install" ]; then
    install_EdgeGallery
  elif [ $COMMAND == "-r" ] || [ $COMMAND == "remove" ]; then
    uninstall_EdgeGallery
  else
    log "Unknown command $COMMAND" $RED
    show_help
    exit 0
  fi
}

function show_k3s_status()
{
  kubectl get nodes
  kubectl get all --all-namespaces -o wide
}

#############################################################
log "Current Directory $K3SDIR" $GREEN
log "Env Directory $ENVDIR" $GREEN
verify_and_run
#############################################################
