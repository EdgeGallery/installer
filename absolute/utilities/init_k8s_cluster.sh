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