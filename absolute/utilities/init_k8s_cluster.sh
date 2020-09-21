#!/bin/bash
######################################################################################
# Copyright (c) 2019 Huawei Tech and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
#######################################################################################
kubectl cluster-info
if [ $? -eq 0 ]; then
  echo "kubernetes cluster already exits !!!"
  echo "Let us continue with the existing cluster."
else
  kubeadm init --apiserver-advertise-address=$nodeip --pod-network-cidr=10.244.0.0/16
  if [ $? -eq 0 ]; then
    echo "kubeadm init success"
    mkdir -p $HOME/.kube
    cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
    kubectl taint nodes --all node-role.kubernetes.io/master-
    kubeadm token create --print-join-command > /tmp/kubeadm_join
  else
    echo "kubeadm init has failed"
    exit 1
  fi
fi