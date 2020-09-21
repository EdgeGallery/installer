#!/bin/bash
######################################################################################
# Copyright (c) 2019 Huawei Tech and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
#######################################################################################

function log() {
  setx=${-//[^x]/}
  set +x
  fname=$(caller 0 | awk '{print $2}')
  fline=$(caller 0 | awk '{print $1}')
  echo; echo -e "$2 $(basename $0) $fname:$fline ($(date)) $1 $NC"
  if [[ -n "$setx" ]]; then
    set -x;
  else
    set +x;
  fi
}

function info() {
  setx=${-//[^x]/}
  set +x
  echo -e "$2 $1 $NC"
  if [[ -n "$setx" ]]; then
    set -x;
  else
    set +x;
  fi
}

function fail() {
  set +x
  trap - ERR
  reason="$1"
  fname=$(caller 0 | awk '{print $2}')
  fline=$(caller 0 | awk '{print $1}')
  if [[ "$1" == "" ]]; then reason="$2 Failure at $fname $fline $NC"; fi
  log "$2 $reason $NC"
  exit 1
}

function wait() {
  #set -x
  val=0
  while [[ $(kubectl get pods --all-namespaces | grep "$1" | grep "Running" | wc -l ) -ne $2 ]]; do
    if [[ $t -eq $POD_READY_WAIT_TIME ]]; then
      fail "$1 Pods failed to start" $RED
    fi
    log "Waiting 5s for $1 pods to be in running state"  $YELLOW
    t=$((t+5))
    if [ $t == 300 ]; then
      log "$1 pod is not able to start"
      log "kindly find the issue by checking the pod's log"
      exit 1
    fi
    sleep 5
  done
  #set +x
}

function install_docker()
{
  install_docker_on_$OS_ID
}

function install_docker_on_ubuntu()
{
  which docker
  if [ $? -eq 0 ]; then
    log "Docker is already installed." $GREEN
  else
    log "Installing docker ." $GREEN
    apt-get update -y
    apt-get install -y apt-transport-https ca-certificates curl gnupg-agent \
     software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    if [ $KERNEL_ARCH == 'x86_64' ]; then
      sudo add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) \
       stable"
    elif [ $KERNEL_ARCH == 'aarch64' ]; then
      sudo add-apt-repository \
       "deb [arch=arm64] https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) \
       stable"
    fi
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io
  fi
}

function install_docker_on_centos()
{
  which docker
  if [ $? -eq 0 ]; then
    log "Docker is already installed." $GREEN
  else
    log "Installing docker ." $GREEN
    yum install -y yum-utils
    yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y docker-ce docker-ce-cli containerd.io
    yum -y install docker-ce-19.03.8 docker-ce-cli-19.03.8 containerd.io
    systemctl start docker
  fi
}

function install_docker_compose_on_ubuntu()
{
  which docker-compose
  if [ $? -eq 0 ]; then
    log "Docker-Compose is already installed." $GREEN
  else
    log "Installing Docker-Compose." $GREEN
    curl -L \
    "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose

    chmod +x /usr/local/bin/docker-compose
  fi
}

function install_kubernetes_cluster()
{
  if [ $EdgeOrController == 'edge' ]; then
    install_k3s
  elif [ $EdgeOrController == 'controller' ]; then
    install_k8s
  fi
}

function uninstall_kubernetes()
{
  if [ $EdgeOrController == 'edge' ]; then
    uninstall_k3s
  elif [ $EdgeOrController == 'controller' ]; then
    uninstall_k8s
  fi
}

function install_k8s()
{
  kubectl cluster-info
  if [ $? -eq 0 ]; then
    log "kubernetes cluster already exits !!!"
    log "Let us continue with the existing cluster."
  else
    systemctl stop firewalld
    swapoff -a
    modprobe br_netfilter
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
    sysctl --system
    if [ $OS_ID == "ubuntu" ]; then
      apt-get -y update && apt-get install -y apt-transport-https curl
      curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
      #update the version of kubeadm
      apt-get -y update && apt-get upgrade -y
      apt-get install -y kubelet kubeadm kubectl
      apt-mark hold kubelet kubeadm kubectl
    elif [ $OS_ID == "centos" ]; then
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
    # Set SELinux in permissive mode (effectively disabling it)
      setenforce 0
      sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
      yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
      systemctl enable --now kubelet
      #update the version of kubeadm
      yum update -y
    fi
  fi
}

function uninstall_k8s
{
  kubeadm reset -f
  if [ $OS_ID == "ubuntu" ]; then
    apt-get -y install iptables
    iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
    apt-get install ipvsadm
    fuser -k -n tcp 10250
    fuser -k -n tcp 6443
    apt-mark unhold kubelet kubeadm kubectl
    apt-get -y purge kubeadm kubectl kubelet kubernetes-cni kube*
    apt-get -y autoremove
  elif [ $OS_ID == "centos" ]; then
    yum install -y iptables
    iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
    yum install -y ipvsadm
    yum remove -y kubeadm kubectl kubelet kubernetes-cni kube*
    yum -y autoremove
  fi
  rm -rf ~/.kube
  rm -rf /var/lib/etcd
  rm -rf /etc/kubernetes/
  rm -rf /etc/cni/net.d
  swapon -a
}

function install_k3s()
{
  kubectl cluster-info
  if [ $? -eq 0 ]; then
    log "kubernetes cluster already exits !!!"
    log "Let us continue with the existing cluster."
  else
    log "Installing k3s ." $GREEN
    if [ $OS_ID == "centos" ]; then
      log "Disabling firewall for successfull k3s installation on CentOs"
      systemctl stop firewalld

      yum install -y container-selinux selinux-policy-base
      rpm -i https://rpm.rancher.io/k3s-selinux-0.1.1-rc1.el7.noarch.rpm
    fi
    #NODE_IP will be exported from nodelist.ini file
    IFACE=$(ip a |grep "$NODE_IP" |awk '{print $NF}')
    #curl -sfL https://get.k3s.io | sh -
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=$NODE_IP --node-external-ip=$NODE_IP --bind-address=$NODE_IP --flannel-iface=$IFACE --docker --no-deploy=servicelb --no-deploy=traefik --write-kubeconfig-mode 644 --kube-apiserver-arg="service-node-port-range=30000-36000"" sh -
    if [ $? -eq 0 ]; then
      log "K3s Installation success"
    else
      log "K3s Installation failed on $NODEIP"
      exit 1
    fi
    wait "coredns" 1
    wait "local-path-provisioner" 1
    wait "metrics-server" 1

    log "copying kubeconfig" $GREEN
    mkdir -p $HOME/.kube/
    cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
  fi
}

function uninstall_k3s()
{
  log "Removing k3s"
  k3s-killall.sh
  k3s-uninstall.sh
}

function install_helm()
{
  if [[ $EdgeOrController == 'edge' ]]; then
    HELM_VERSION="v2.16.1"
  elif [ $EdgeOrController == 'controller' ]; then
    HELM_VERSION="v3.0.2"
  fi
  helm_check=$(helm version | cut -d \" -f2)
  if [ $helm_check == $HELM_VERSION ];then
    log "helm $HELM_VERSION is already installed"
  else
    log "Installing helm." $GREEN
    cd $K3SDIR

    if [ $OS_ID == "centos" ]; then
      yum install -y wget
    fi
    kubectl create -f $K3SDIR/mep/common_svc/prometheus/rbac-config.yaml
    if [ $KERNEL_ARCH == 'aarch64' ]; then
      wget -N https://get.helm.sh/helm-"$HELM_VERSION"-linux-arm64.tar.gz
      tar -zxf helm-"$HELM_VERSION"-linux-arm64.tar.gz
      mv linux-arm64/helm /usr/local/bin/
      if [ "$HELM_VERSION" == "v2.16.1" ]; then
        helm init --service-account tiller --history-max 200 --upgrade --tiller-image=jessestuart/tiller
      fi
    elif [ $KERNEL_ARCH == 'x86_64' ]; then
      wget -N https://get.helm.sh/helm-"$HELM_VERSION"-linux-amd64.tar.gz
      tar -zxf helm-"$HELM_VERSION"-linux-amd64.tar.gz
      mv linux-amd64/helm /usr/local/bin/
      if [ "$HELM_VERSION" == "v2.16.1" ]; then
        helm init --service-account tiller --history-max 200 --upgrade
      fi
    fi

    if [ "$HELM_VERSION" == "v2.16.1" ]; then
      wait "tiller" 1
    fi
    log "Adding Helm stable & Edgegallery repo." $GREEN
    helm repo add stable https://kubernetes-charts.storage.googleapis.com/
    helm repo add edgegallery https://edgegallery.github.io/helm-charts
    helm repo update
  fi
}

function uninstall_helm ()
{
  if [[ $EdgeOrController == 'edge' ]]; then
    HELM_VERSION="v2.16.1"
  elif [ $EdgeOrController == 'controller' ]; then
    HELM_VERSION="v3.0.2"
  fi
  log "removing helm"  $GREEN
  if [ $KERNEL_ARCH == 'aarch64' ]; then
    rm -rf $K3SDIR/linux-arm64
    rm $K3SDIR/helm-"$HELM_VERSION"-linux-arm64.tar.gz
    rm /usr/local/bin/helm
  else
    rm -rf $K3SDIR/linux-amd64/
    rm $K3SDIR/helm-"$HELM_VERSION"-linux-amd64.tar.gz
    rm /usr/local/bin/helm
  fi
}

function append_deploy_n_arch_type_to_helm_command()
{
  #maintain space before --set
  if [ $KERNEL_ARCH == 'aarch64' ]; then
    HELM_COMMAND+=" --set arch=arm64 "
  fi
  if [  $DEPLOY_TYPE  ==  "nodePort" ]; then
    HELM_COMMAND+="--set expose.type=nodePort,expose.nodePort.ip=$NODEIP "
  fi
}

function install_controller_with_ingress()
{
  HELM_COMMAND+="helm install ingress-edgegallery edgegallery/edgegallery "
  HELM_COMMAND+="--set expose.type=ingress "
  HELM_COMMAND+="--set expose.ingress.hosts.auth=$auth_domain "
  HELM_COMMAND+="--set expose.ingress.hosts.appstore=$appstore_domain "
  HELM_COMMAND+="--set expose.ingress.hosts.developer=$developer_domain "
  HELM_COMMAND+="--set expose.ingress.hosts.mecm=$mecm_domain "
  HELM_COMMAND+="--set expose.ingress.tls.enabled=$tls_enabled "
  if [ $tls_enabled == true ];then
    HELM_COMMAND+="--set expose.ingress.tls.secretName=$tls_secretName "
  fi
  if [ $KERNEL_ARCH == 'aarch64' ]; then
    HELM_COMMAND+=" --set arch=arm64 "
  fi
  $HELM_COMMAND
}

function uninstall_controller_with_ingress()
{
  helm uninstall ingress-edgegallery
}