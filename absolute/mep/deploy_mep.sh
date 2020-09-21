#!/bin/bash
######################################################################################
# Copyright (c) 2019 Huawei Tech and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
#######################################################################################
function install_prometheus()
{
  log "Installing prometheus." $GREEN

  if [ $KERNEL_ARCH == 'aarch64' ]; then
    helm install --name mep-prometheus stable/prometheus \
    -f $K3SDIR/mep/common_svc/prometheus/values.yaml --version v9.3.1
  else
    helm install --name mep-prometheus stable/prometheus \
    -f $K3SDIR/mep/common_svc/prometheus/x86_values.yaml --version v9.3.1
  fi
  if [ $? -eq 0 ]; then
    wait "mep-prometheus-alertmanager" 1
    wait "mep-prometheus-kube-state-metrics" 1
    wait "mep-prometheus-node-exporter" 1
    wait "mep-prometheus-pushgateway" 1
    wait "mep-prometheus-server" 1
  else
    fail "helm install --name mep-prometheus failed"
    exit 1
  fi
}

function uninstall_prometheus()
{
  log "removing prometheus" $GREEN
  helm uninstall mep-prometheus
}

function install_grafana()
{
  log "Installing grafana." $GREEN

  if [ $KERNEL_ARCH == 'aarch64' ]; then
    helm install --name mep-grafana stable/grafana \
    -f $K3SDIR/mep/common_svc/grafana/values.yaml
  else
    helm install --name mep-grafana stable/grafana \
    -f $K3SDIR/mep/common_svc/grafana/x86_values.yaml
  fi
  if [ $? -eq 0 ]; then
    wait "mep-grafana" 1
  else
    fail "helm install --name mep-grafana failed"
    exit 1
  fi
}

function uninstall_grafana()
{
  log "removing grafana" $GREEN
  helm uninstall mep-grafana
}

function install_rabbitmq()
{
  log "Installing rabbitmq." $GREEN

  cd $K3SDIR/mep/common_svc/rabbitmq
  if [ $KERNEL_ARCH == 'aarch64' ]; then
    kubectl apply -f common
    kubectl apply -f statefulset_arm.yaml
  else
    kubectl apply -f common
    kubectl apply -f statefulset_x86.yaml
  fi
  if [ $? -eq 0 ]; then
    wait "rabbitmq" 3
  else
    fail "rabbitmq installtion failed"
    exit 1
  fi
}

function uninstall_rabbitmq()
{
  log "removing rabbitmq"  $GREEN

  cd $K3SDIR/mep/common_svc/rabbitmq
  if [ $KERNEL_ARCH == 'aarch64' ]; then
    kubectl delete -f common
    kubectl delete -f statefulset_arm.yaml
  else
    kubectl delete -f common
    kubectl delete -f statefulset_x86.yaml
  fi
}

function install_mep()
{
  log "Installing MEP." $GREEN

  install_prometheus
  install_grafana
  install_rabbitmq
  log "MEP started." $GREEN
}

function uninstall_mep()
{
  log "Uninstalling MEP"
  uninstall_prometheus
  uninstall_grafana
  uninstall_rabbitmq
  log "Clean complete." $GREEN
  log "MEP uninstalled." $GREEN
}
