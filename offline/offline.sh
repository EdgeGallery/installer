#!/bin/bash
######################################################################################
# Copyright (c) 2019 Huawei Tech and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
#######################################################################################
LWD=`pwd`
CUR_DIR=$(dirname $(readlink -f "$0"))

KERNEL_ARCH=`uname -m`

if [[ -z "$EG_IMAGE_TAG" ]]; then
   EG_IMAGE_TAG=latest
fi

#CONTROLLER
if [[ -z "$EG_IMAGE_LIST_CONTROLLER_X86_DEFAULT" ]]; then
   EG_IMAGE_LIST_CONTROLLER_X86_DEFAULT="swr.ap-southeast-1.myhuaweicloud.com/edgegallery/appstore-fe:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/appstore-be:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/developer-fe:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/developer-be:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/tool-chain:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/porting-advisor:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/mecm-fe:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/mecm-inventory:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/mecm-appo:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/mecm-apm:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/service-center:latest \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/user-mgmt:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/curl:latest \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/redis:6.0.3 \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/postgres:12.2"
fi
EG_IMAGE_LIST_CONTROLLER_ARM64_DEFAULT=$EG_IMAGE_LIST_CONTROLLER_X86_DEFAULT
EG_HELM_LIST_CONTROLLER_X86_DEFAULT="servicecenter usermgmt developer appstore mecm-fe mecm-meo"
EG_HELM_LIST_CONTROLLER_ARM64_DEFAULT=$EG_HELM_LIST_CONTROLLER_X86_DEFAULT

#EDGE
if [[ -z "$EG_IMAGE_LIST_EDGE_X86_DEFAULT" ]]; then
   EG_IMAGE_LIST_EDGE_X86_DEFAULT="swr.ap-southeast-1.myhuaweicloud.com/edgegallery/mepauth:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/mep:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/mep-dns-server:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/edgegallery-secondary-ep-controller:latest \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/mecm-applcm:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/mecm-applcm-k8splugin:$EG_IMAGE_TAG \
   prom/alertmanager:v0.18.0 \
   prom/node-exporter:v0.18.0 \
   prom/prometheus:v2.13.1 \
   prom/pushgateway:v0.8.0 \
   quay.io/coreos/kube-state-metrics:v1.6.0 \
   jimmidyson/configmap-reload:v0.2.2 \
   curlimages/curl:latest \
   grafana/grafana:7.1.1 \
   bats/bats:v1.1.0 \
   busybox:1.31.1 \
   rabbitmq:3.7-management-alpine \
   nginx:stable \
   postgres:12.3 \
   kong:2.0.4-ubuntu \
   docker.io/nfvpe/multus:stable \
   docker.io/nfvpe/multus:stable-ppc64le"
fi 

if [[ -z "$EG_IMAGE_LIST_EDGE_ARM64_DEFAULT" ]]; then
   EG_IMAGE_LIST_EDGE_ARM64_DEFAULT="swr.ap-southeast-1.myhuaweicloud.com/edgegallery/mepauth:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/mep:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/mep-dns-server:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/edgegallery-secondary-ep-controller:latest \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/mecm-applcm:$EG_IMAGE_TAG \
   swr.ap-southeast-1.myhuaweicloud.com/edgegallery/mecm-applcm-k8splugin:$EG_IMAGE_TAG \
   prom/alertmanager:v0.18.0 \
   prom/node-exporter:v0.18.1 \
   prom/prometheus:v2.15.2 \
   prom/pushgateway:v1.0.1 \
   carlosedp/kube-state-metrics:v1.7.2 \
   jimmidyson/configmap-reload:latest-arm64 \
   kiwigrid/k8s-sidecar:0.1.151 \
   grafana/grafana-arm64v8-linux:6.5.2-ubuntu \
   lucashalbert/curl:arm64v8-7.66.0-r0 \
   arm64v8/rabbitmq:3.7-management-alpine \
   bats/bats:v1.1.0 \
   busybox:1.31.1 \
   rabbitmq:3.7-management-alpine \
   nginx:stable \
   postgres:12.3 \
   kong:2.0.4-ubuntu \
   docker.io/nfvpe/multus:stable \
   docker.io/nfvpe/multus:stable-ppc64le"
fi 
EG_HELM_LIST_EDGE_X86_DEFAULT="mecm-mepm mep"
EG_HELM_LIST_EDGE_ARM64_DEFAULT=$EG_HELM_LIST_EDGE_X86_DEFAULT

if [[ -z $EG_HELM_REPO ]]; then
  EG_HELM_REPO="http://119.8.55.191:30002/chartrepo/edgegallery_helm_chart"
fi

if [[ -z "$EG_IMAGE_LIST_CONTROLLER_X86" ]]; then
  EG_IMAGE_LIST_CONTROLLER_X86=$EG_IMAGE_LIST_CONTROLLER_X86_DEFAULT
fi 

if [[ -z "$EG_IMAGE_LIST_EDGE_X86" ]]; then
  EG_IMAGE_LIST_EDGE_X86=$EG_IMAGE_LIST_EDGE_X86_DEFAULT
fi

if [[ -z "$EG_IMAGE_LIST_CONTROLLER_ARM64" ]]; then
  EG_IMAGE_LIST_CONTROLLER_ARM64=$EG_IMAGE_LIST_CONTROLLER_ARM64_DEFAULT
fi

if [[ -z "$EG_IMAGE_LIST_EDGE_ARM64" ]]; then
  EG_IMAGE_LIST_EDGE_ARM64=$EG_IMAGE_LIST_EDGE_ARM64_DEFAULT
fi

if [[ -z "$EG_HELM_LIST_CONTROLLER_X86" ]]; then
  EG_HELM_LIST_CONTROLLER_X86=$EG_HELM_LIST_CONTROLLER_X86_DEFAULT
fi

if [[ -z "$EG_HELM_LIST_EDGE_X86" ]]; then
  EG_HELM_LIST_EDGE_X86=$EG_HELM_LIST_EDGE_X86_DEFAULT
fi

if [[ -z "$EG_HELM_LIST_CONTROLLER_ARM64" ]]; then
  EG_HELM_LIST_CONTROLLER_ARM64=$EG_HELM_LIST_CONTROLLER_ARM64_DEFAULT
fi

if [[ -z "$EG_HELM_LIST_EDGE_ARM64" ]]; then
  EG_HELM_LIST_EDGE_ARM64=$EG_HELM_LIST_EDGE_ARM64_DEFAULT
fi

export K8S_DOCKER_IMAGES="k8s.gcr.io/kube-proxy:v1.18.7 \
k8s.gcr.io/kube-controller-manager:v1.18.7 \
k8s.gcr.io/kube-apiserver:v1.18.7 \
k8s.gcr.io/kube-scheduler:v1.18.7 \
k8s.gcr.io/pause:3.2 \
k8s.gcr.io/coredns:1.6.7 \
k8s.gcr.io/etcd:3.4.3-0 \
calico/node:v3.15.1 \
calico/cni:v3.15.1 \
calico/kube-controllers:v3.15.1 \
calico/pod2daemon-flexvol:v3.15.1 \
nginx:stable"

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export NC='\033[0m'

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

function _download_sshpass()
{
  cd $TARBALL_PATH/
  if [ $KERNEL_ARCH == 'x86_64' ]; then
    wget -N http://archive.ubuntu.com/ubuntu/pool/universe/s/sshpass/sshpass_1.06-1_amd64.deb
  else
    wget -N http://ports.ubuntu.com/pool/universe/s/sshpass/sshpass_1.06-1_arm64.deb
  fi
  if [[ $? -ne 0 ]]; then
      info "wget sshpass .deb Failed" $RED
      exit 1
  fi
}

function _docker_images_download_eg() {
  #docker login -u $DOCKER_LOGIN_USERNAME  -p $DOCKER_LOGIN_PASSWORD swr.ap-southeast-1.myhuaweicloud.com
  mkdir -p $TARBALL_PATH/eg_swr_images
  EG_SWR_PATH=$TARBALL_PATH/eg_swr_images/  
  info "download the edgegallery images list is : $1" $RED
  for image in $1;
  do
    docker pull $image;
    if [[ $? -ne 0 ]]; then
      info "docker pull $image Failed" $RED
      if [[ $image != "kong:2.0.4-alpine" ]]; then
        exit 1
      fi
    fi
    repo=$(echo ${image} | cut -d"/" -f1);
    #for new repo need to update this check
    if [ $repo == "swr.ap-southeast-1.myhuaweicloud.com" ]; then
      organization=$(echo ${image} | cut -d"/" -f2)
      image_n_tag=$(echo ${image} | cut -d"/" -f3)
      docker image tag $image "$organization"/"$image_n_tag"
      image="$organization"/"$image_n_tag"
    fi
    IMAGE_NAME=`echo $image| sed -e "s/\:/#/g" | sed -e "s/\//@/g"`;
    docker save $image | gzip > $EG_SWR_PATH/$IMAGE_NAME.tar.gz
  done
}

function _download_helm_binary()
{
  mkdir -p $TARBALL_PATH/helm
  cd $TARBALL_PATH/helm/ || exit

  if [ $KERNEL_ARCH == 'x86_64' ]; then
    arch=amd64
    wget -N https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz
  else
    arch=arm64
    wget -N https://get.helm.sh/helm-v3.2.4-linux-arm64.tar.gz
  fi
  if [[ $? -ne 0 ]]; then
      info "wget https://get.helm.sh/helm-v3.2.4-linux-$arch.tar.gz Failed" $RED
      exit 1
  fi
}

function _help_install_helm_binary()
{
  helm version
  if [[ $? -eq 0 ]];then
    info "Helm is already installed" $BLUE
  else
    mkdir -p /tmp/helm-download
    cd "$TARBALL_PATH"/helm || exit
    if [ $KERNEL_ARCH == 'x86_64' ]; then
      tar -zxf helm-v3.2.4-linux-amd64.tar.gz -C /tmp/helm-download; mv /tmp/helm-download/linux-amd64/helm /usr/local/bin/;
    else
      tar -zxf helm-v3.2.4-linux-arm64.tar.gz -C /tmp/helm-download; mv /tmp/helm-download/linux-arm64/helm /usr/local/bin/;
    fi
  fi
}

function _download_helm_charts()
{
  mkdir -p $TARBALL_PATH/helm/helm-charts
  cd $TARBALL_PATH/helm/helm-charts || exit
  if [ -d helm-charts ]; then
    rm -rf helm-charts
  fi

  _help_install_helm_binary

  helm repo remove eg
  helm repo add eg $EG_HELM_REPO
  mkdir -p edgegallery/
  mkdir -p stable
  cd edgegallery || exit

  CHART_LIST=$1
  ENABLE_METRICS=$2

  for chart in $CHART_LIST;
    do
      helm pull eg/$chart
      if [[ $? -ne 0 ]]; then
        info "helm pull $EG_HELM_REPO/$chart Failed" $RED
        exit 1
      fi
    done
  cd ../stable

  if [[ $ENABLE_METRICS == "YES" ]]; then
    wget -N https://kubernetes-charts.storage.googleapis.com/grafana-5.5.5.tgz
    if [[ $? -ne 0 ]]; then
      info "grafana-5.5.5.tgz download got Failed" $RED
      exit 1
    fi
    wget -N https://kubernetes-charts.storage.googleapis.com/prometheus-9.3.1.tgz
    if [[ $? -ne 0 ]]; then
      info "prometheus-9.3.1.tgz download got Failed" $RED
      exit 1
    fi
  fi 

  wget -N https://kubernetes-charts.storage.googleapis.com/nginx-ingress-1.41.2.tgz
  if [[ $? -ne 0 ]]; then
    info "nginx-ingress-1.41.2.tgz download got Failed" $RED
    exit 1
  fi
  wget -N https://kubernetes-charts.storage.googleapis.com/nfs-client-provisioner-1.2.8.tgz
  if [[ $? -ne 0 ]]; then
    info "nfs-client-provisioner-1.2.8.tgz download got Failed" $RED
    exit 1
  fi
}

function _download_docker_registry()
{
  mkdir -p $TARBALL_PATH/registry
  docker pull registry:2
  if [[ $? -ne 0 ]]; then
    info "docker pull registry:2 Failed" $RED
    exit 1
  fi
  docker save registry:2 | gzip > $TARBALL_PATH/registry/registry-2.tar.gz
}


function _docker_download() {
  mkdir -p $K8S_OFFLINE_DIR/docker
  wget -N https://download.docker.com/linux/static/stable/`arch`/docker-18.09.0.tgz -O $K8S_OFFLINE_DIR/docker/docker.tgz
  if [[ $? -ne 0 ]]; then
    info "download docker-18.09.0.tgz Failed" $RED
    exit 1
  fi
}

function _docker_images_download() {
    for image in $*;
    do
      docker pull $image;
      if [[ $? -ne 0 ]]; then
        info "docker pull $image Failed" $RED
        exit 1
      fi
      IMAGE_NAME=`echo $image| sed -e "s/\//@/g"`;
      docker save --output $K8S_OFFLINE_DIR/docker/images/$IMAGE_NAME.tar $image;
      gzip -f $K8S_OFFLINE_DIR/docker/images/$IMAGE_NAME.tar;
    done
}

function _docker_deploy() {
    docker version
    if [[ $? != '0' ]]; then
      rm -rf /tmp/remote-platform/k8s/docker
      mkdir -p /tmp/remote-platform/k8s
      tar -xf $K8S_OFFLINE_DIR/docker/docker.tgz -C /tmp/remote-platform/k8s
      for cmd in containerd  containerd-shim  ctr  docker  dockerd  docker-init  docker-proxy  runc; do cp /tmp/remote-platform/k8s/docker/$cmd /usr/bin/$cmd; done

      cat <<EOF >docker.service
[Unit]
Description=Docker Daemon

[Service]
ExecStart=/usr/bin/dockerd

[Install]
WantedBy=multi-user.target
EOF

      mv docker.service /etc/systemd/system/

      systemctl daemon-reload
      systemctl enable docker.service
      systemctl start docker.service
      systemctl status docker.service --no-pager
    else
      info "docker already exists...." $BLUE
    fi
}

function _kubernetes_tool_download() {
    cp $CUR_DIR/conf/manifest/calico/calico.yaml $K8S_OFFLINE_DIR/k8s/

    curl -LO https://k8s.io/examples/application/nginx-app.yaml
    if [[ $? -ne 0 ]]; then
      info "curl -LO https://k8s.io/examples/application/nginx-app.yaml  Failed" $RED
      exit 1
    fi
    sed -i 's?nginx:.*?nginx:stable?g' nginx-app.yaml
    mv nginx-app.yaml $K8S_OFFLINE_DIR/k8s/

    if [ $KERNEL_ARCH == 'aarch64' ]; then
      arch="arm64"
      curl -LO https://mirrors.aliyun.com/ubuntu-ports/pool/main/s/socat/socat_1.7.3.2-2ubuntu2_arm64.deb
      if [[ $? -ne 0 ]]; then
        info "curl -LO https://mirrors.aliyun.com/ubuntu-ports/pool/main/s/socat/socat_1.7.3.2-2ubuntu2_arm64.deb Failed" $RED
        exit 1
      fi
      curl -LO http://ports.ubuntu.com/pool/main/c/conntrack-tools/conntrack_1.4.4+snapshot20161117-6ubuntu2_arm64.deb
      if [[ $? -ne 0 ]]; then
        info "curl -LO http://ports.ubuntu.com/pool/main/c/conntrack-tools/conntrack_1.4.4+snapshot20161117-6ubuntu2_arm64.deb Failed" $RED
        exit 1
      fi
    else
      arch="amd64"
      curl -LO http://archive.ubuntu.com/ubuntu/pool/main/s/socat/socat_1.7.3.2-2ubuntu2_amd64.deb
      if [[ $? -ne 0 ]]; then
        info "curl -LO http://archive.ubuntu.com/ubuntu/pool/main/s/socat/socat_1.7.3.2-2ubuntu2_amd64.deb Failed" $RED
        exit 1
      fi
      curl -LO http://archive.ubuntu.com/ubuntu/pool/main/c/conntrack-tools/conntrack_1.4.4+snapshot20161117-6ubuntu2_amd64.deb
      if [[ $? -ne 0 ]]; then
        info "curl -LO http://archive.ubuntu.com/ubuntu/pool/main/c/conntrack-tools/conntrack_1.4.4+snapshot20161117-6ubuntu2_amd64.deb Failed" $RED
        exit 1
      fi
    fi

    mv socat_1.7.3.2-2ubuntu2_$arch.deb $K8S_OFFLINE_DIR/tools/
    mv conntrack_1.4.4+snapshot20161117-6ubuntu2_$arch.deb $K8S_OFFLINE_DIR/tools/

    for cmd in kubectl kubeadm kubelet;
    do
      curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.18.7/bin/linux/$arch/$cmd";
      if [[ $? -ne 0 ]]; then
        info "curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.18.7/bin/linux/$arch/$cmd" Failed" $RED
        exit 1
      fi
      mv $cmd $K8S_OFFLINE_DIR/k8s/;
    done
}

function _cni_download() {
    if [ $KERNEL_ARCH == 'x86_64' ]; then
        curl -LO  https://github.com/containernetworking/plugins/releases/download/v0.8.7/cni-plugins-linux-amd64-v0.8.7.tgz
	tar -xvf cni-plugins-linux-amd64-v0.8.7.tgz -C $K8S_OFFLINE_DIR/cni/
        rm cni-plugins-linux-amd64-v0.8.7.tgz
    else
        curl -LO  https://github.com/containernetworking/plugins/releases/download/v0.8.7/cni-plugins-linux-arm64-v0.8.7.tgz
	tar -xvf cni-plugins-linux-arm64-v0.8.7.tgz -C $K8S_OFFLINE_DIR/cni/
        rm cni-plugins-linux-arm64-v0.8.7.tgz
    fi	
}

function kubernetes_offline_installer() {
	K8S_OFFLINE_DIR=$TARBALL_PATH/k8s-offline/
        rm -rf $K8S_OFFLINE_DIR
        mkdir -p $K8S_OFFLINE_DIR $K8S_OFFLINE_DIR/docker $K8S_OFFLINE_DIR/docker/images $K8S_OFFLINE_DIR/k8s $K8S_OFFLINE_DIR/tools $K8S_OFFLINE_DIR/cni

        _docker_download
        _docker_deploy
        _kubernetes_tool_download
        _cni_download
        _docker_images_download $K8S_DOCKER_IMAGES

        tar -vcf kubernetes_offline_installer.tar -C $K8S_OFFLINE_DIR .
        gzip kubernetes_offline_installer.tar
	rm -rf $K8S_OFFLINE_DIR
}

function ftp_setup() {
	cat << EOF > /root/eg-users.conf
EOF

	mkdir /root/eg 
	docker rm -f eg-ftp 

	docker run --name eg-ftp -v /root/eg:/home/eg/ftp  -v /root/eg-users.conf:/etc/sftp/users.conf:ro -p 30099:22 -d atmoz/sftp
}


# $1: EG_COMP = all OR controller OR edge, by default all
function eg_offline_installer()
{
  
  if [[ -z "$1"  || "$1" == "all" ]]; then
    EG_MODE=all
  elif [[ "$1" == "controller" ]]; then
    EG_MODE=controller
  elif [[ "$1" == "edge" ]]; then
    EG_MODE=edge
  else
    echo "Invalid Mode. Allowed modes are controller, edge, all. by default, its all"
    exit 1
  fi

  if [[ `arch` == "x86_64" ]]; then
    EG_NODE_ARCH=x86
    EG_IMAGE_LIST_CONTROLLER=$EG_IMAGE_LIST_CONTROLLER_X86
    EG_IMAGE_LIST_EDGE=$EG_IMAGE_LIST_EDGE_X86
    EG_HELM_LIST_CONTROLLER=$EG_HELM_LIST_CONTROLLER_X86
    EG_HELM_LIST_EDGE=$EG_HELM_LIST_EDGE_X86
  elif [[ `arch` == "aarch64" ]]; then
    EG_NODE_ARCH=arm64
    EG_IMAGE_LIST_CONTROLLER=$EG_IMAGE_LIST_CONTROLLER_ARM64
    EG_IMAGE_LIST_EDGE=$EG_IMAGE_LIST_EDGE_ARM64
    EG_HELM_LIST_CONTROLLER=$EG_HELM_LIST_CONTROLLER_ARM64
    EG_HELM_LIST_EDGE=$EG_HELM_LIST_EDGE_ARM64
  else
    echo "Unsupported architecture."
    exit 1
  fi

  if [[ "$EG_MODE" == "all" ]]; then
    EG_IMAGE_LIST="$EG_IMAGE_LIST_CONTROLLER $EG_IMAGE_LIST_EDGE"
    EG_HELM_LIST="$EG_HELM_LIST_CONTROLLER $EG_HELM_LIST_EDGE"
  elif [[ "$EG_MODE" == "controller" ]]; then
    EG_IMAGE_LIST="$EG_IMAGE_LIST_CONTROLLER"
    EG_HELM_LIST="$EG_HELM_LIST_CONTROLLER"
  elif [[ "$EG_MODE" == "edge" ]]; then
    EG_IMAGE_LIST="$EG_IMAGE_LIST_EDGE"
    EG_HELM_LIST="$EG_HELM_LIST_EDGE"
  fi

  EG_INSTALLER_NAME=eg-$EG_MODE-$EG_NODE_ARCH-$EG_IMAGE_TAG-$(date +%Y-%m-%d-%H-%M-%S)

  if [[ -z "$2" ]]; then
   TARBALL_PATH=$PWD/eg-offline
  else
   TARBALL_PATH=$2/eg-offline
  fi

  rm -rf $TARBALL_PATH
  mkdir -p $TARBALL_PATH

  echo ===============================
  echo Buiding Edge Gallery installer 
  echo ===============================
  echo "ARCH: " $EG_NODE_ARCH
  echo "MODE: " $EG_MODE
  echo EG_IMAGE_LIST: $EG_IMAGE_LIST
  echo EG_HELM_LIST: $EG_HELM_LIST
  echo INSTALLER PATH: $TARBALL_PATH/../$EG_INSTALLER_NAME.tar.gz
  echo ===============================

  _download_sshpass

  kubernetes_offline_installer

  _docker_images_download_eg "$EG_IMAGE_LIST"

  _download_helm_binary

  if [[ "$EG_MODE" == "all" || "$EG_MODE" == "edge" ]]; then
    _download_helm_charts "$EG_HELM_LIST" "YES"
  else
    _download_helm_charts "$EG_HELM_LIST"
  fi

  _download_docker_registry

  cp $CUR_DIR/LICENSE $TARBALL_PATH
  cp $CUR_DIR/README.md $TARBALL_PATH
  cp $CUR_DIR/env.sh $TARBALL_PATH

  echo "#####################################################" >>  $TARBALL_PATH/env.sh
  echo "#CAUTION:: PLEASE DONOT CHANGE BELOW ENV VARS ::" >>  $TARBALL_PATH/env.sh
  echo "export EG_IMAGE_TAG=$EG_IMAGE_TAG" >>  $TARBALL_PATH/env.sh
  echo "export EG_NODE_ARCH=$EG_NODE_ARCH" >>  $TARBALL_PATH/env.sh
  echo "export EG_MODE=$EG_MODE" >>  $TARBALL_PATH/env.sh
  echo "#####################################################" >>  $TARBALL_PATH/env.sh
  
  cp $CUR_DIR/eg.sh $TARBALL_PATH
  cp -r $CUR_DIR/conf/ $TARBALL_PATH

  cd $TARBALL_PATH/..
  tar -vcf $EG_INSTALLER_NAME.tar -C $TARBALL_PATH .
  gzip $EG_INSTALLER_NAME.tar

  echo "INSTALLER: "$TARBALL_PATH/../$EG_INSTALLER_NAME.tar.gz
  cd $LWD
  exit 0
}


########################################
script_name=$( basename ${0#-} )
this_script=$( basename ${BASH_SOURCE} )

#skip main in case of source
if [[ ${script_name} = ${this_script} ]] ; then
  eg_offline_installer $*
fi
########################################
