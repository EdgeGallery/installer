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

OFFLINE_MODE=$OFFLINE_MODE
K8S_NODE_MASTER_IPS=$K8S_NODE_MASTER_IPS
K8S_NODE_WORKER_IPS=$K8S_NODE_WORKER_IPS
EG_NODE_DEPLOY_IP=$EG_NODE_DEPLOY_IP
EG_NODE_MASTER_IPS=$EG_NODE_MASTER_IPS
EG_NODE_WORKER_IPS=$EG_NODE_WORKER_IPS
EG_NODE_CONTROLLER_MASTER_IPS=$EG_NODE_CONTROLLER_MASTER_IPS
EG_NODE_CONTROLLER_WORKER_IPS=$EG_NODE_CONTROLLER_WORKER_IPS
EG_NODE_EDGE_MASTER_IPS=$EG_NODE_EDGE_MASTER_IPS
EG_NODE_EDGE_WORKER_IPS=$EG_NODE_EDGE_WORKER_IPS
SKIP_K8S=$SKIP_K8S
TARBALL_PATH=$PWD
PLATFORM_DIR=$PWD
KERNEL_ARCH=`uname -m`
INSTALLER_INDEX=""
if [ $KERNEL_ARCH == 'aarch64' ]; then
  arch="arm64"
else
  arch="amd64"
fi
K8S_OFFLINE_DIR=/tmp/remote-platform
mkdir -p $K8S_OFFLINE_DIR

DEVELOPER_PORT=30092
APPSTORE_PORT=30091
MECM_PORT=30093
ATP_PORT=30094
USER_MGMT=30067
LAB_PORT=30096

#===========================k8s-offline=========================================
export K8S_DOCKER_IMAGES="k8s.gcr.io/kube-proxy:v1.18.7 \
k8s.gcr.io/kube-controller-manager:v1.18.7 \
k8s.gcr.io/kube-apiserver:v1.18.7 \
k8s.gcr.io/kube-scheduler:v1.18.7 \
k8s.gcr.io/pause:3.2 \
k8s.gcr.io/coredns:1.6.7 \
k8s.gcr.io/etcd:3.4.3-0 \
k8s.gcr.io/metrics-server/metrics-server:v0.3.7 \
calico/node:v3.15.1 \
calico/cni:v3.15.1 \
calico/kube-controllers:v3.15.1 \
calico/pod2daemon-flexvol:v3.15.1 \
nginx:stable"

function _docker_deploy() {
    docker version >/dev/null 2>&1
    if [[ $? != '0' ]]; then
      rm -rf /tmp/remote-platform/k8s/docker
      mkdir -p /tmp/remote-platform/k8s
      tar -xf $K8S_OFFLINE_DIR/docker/docker.tgz -C /tmp/remote-platform/k8s
      for cmd in containerd  containerd-shim  ctr  docker  dockerd  docker-init  docker-proxy  runc; do cp /tmp/remote-platform/k8s/docker/$cmd /usr/bin/$cmd; done

      cat <<EOF >docker.service
[Unit]
Description=Docker Daemon

[Service]
ExecStart=/usr/bin/dockerd --bip "192.168.251.1/24"

[Install]
WantedBy=multi-user.target
EOF

      mv docker.service /etc/systemd/system/

      systemctl daemon-reload
      systemctl enable docker.service
      systemctl start docker.service
      systemctl status docker.service --no-pager
      sleep 3
    else
      info "docker already exists...." $BLUE
    fi
}

function _docker_undeploy() {
    systemctl stop docker.service
    systemctl disable docker.service

    rm /etc/systemd/system/docker.service
    systemctl daemon-reload

    for cmd in containerd  containerd-shim  ctr  docker  dockerd  docker-init  docker-proxy  runc; do rm /usr/bin/$cmd; done

    systemctl status docker.service --no-pager
    rm -rf /var/lib/docker/
}

function _docker_compose_deploy() {
    docker-compose version
    if [[ $? != '0' ]]; then
      cp $K8S_OFFLINE_DIR/harbor/docker-compose /usr/local/bin/docker-compose
      chmod +x /usr/local/bin/docker-compose
    else
      info "docker compose already exists...." $BLUE
    fi
}

function _docker_compose_undeploy() {
  rm /usr/local/bin/docker-compose
}

function _setup_harbor() {
  _docker_compose_deploy
  cd /root
  mkdir -p /root/harbor
  tar -zxf $K8S_OFFLINE_DIR/harbor/harbor.tar.gz -C harbor
  cd harbor
 
  sed -i  "s/hostname: .*/hostname: $HARBOR_REPO_IP/" harbor.yml
  sed -i 8's/^/#/' harbor.yml
  sed -i 10's/^/#/' harbor.yml

  sed -i  "s/certificate: .*/certificate: \/root\/harbor\/cert\/ca.crt/" harbor.yml
  sed -i  "s/private_key: .*/private_key: \/root\/harbor\/cert\/ca.key/" harbor.yml
  sed -i  "s/data_volume: .*/data_volume: \/root\/harbor\/data_volume/" harbor.yml

  cd /root/
  openssl rand -writerand .rnd
  cd harbor/cert/
  openssl genrsa -out ca.key 4096
  openssl req -x509 -new -nodes -sha512 -days 3650 -subj "/C=CN/ST=Guangzhou/L=Guangzhou/O=example/CN="$HARBOR_REPO_IP \
  -key ca.key -out ca.crt
  mkdir -p /etc/docker/certs.d/$HARBOR_REPO_IP:443/
  cp /root/harbor/cert/ca.crt /root/harbor/cert/ca.key /etc/docker/certs.d/$HARBOR_REPO_IP:443/
  cd /etc/docker/certs.d/$HARBOR_REPO_IP:443/
  openssl x509 -inform PEM -in ca.crt -out ca.cert
  mv ca.key $HARBOR_REPO_IP.key
  mv ca.cert $HARBOR_REPO_IP.cert

if [ "$OFFLINE_MODE" == "aio" ]; then
cat <<EOF | tee /etc/docker/daemon.json
{
    "insecure-registries" : ["$HARBOR_REPO_IP"]
}
EOF
fi
  service docker restart
  systemctl daemon-reload
  systemctl restart docker
  cd /root/harbor/
  ./install.sh
  docker login -u$HARBOR_USER -p$HARBOR_PASSWORD $HARBOR_REPO_IP
  kubectl create secret docker-registry  harbor  --docker-server=https://$HARBOR_REPO_IP --docker-username=$HARBOR_USER --docker-password=$HARBOR_PASSWORD  
  kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "harbor"}]}'
}

function _docker_images_load() {
    for image in $*; do IMAGE_NAME=`echo $image| sed -e "s/\//@/g"`; docker load --input $K8S_OFFLINE_DIR/docker/images/$IMAGE_NAME.tar.gz; done
}

function _docker_images_remove() {
    for image in $*; do docker rmi $image; done
}

function _kubernetes_tool_deploy () {
    for cmd in kubectl kubeadm kubelet; do cp $K8S_OFFLINE_DIR/k8s/$cmd /usr/bin/; chmod +x /usr/bin/$cmd; done

    cat <<EOF >kubelet.service
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=https://kubernetes.io/docs/home/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/bin/kubelet
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    mv kubelet.service /etc/systemd/system/

    mkdir /etc/systemd/system/kubelet.service.d
    cat <<EOF >10-kubeadm.conf
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
# This is a file that "kubeadm init" and "kubeadm join" generates at runtime, populating the KUBELET_KUBEADM_ARGS variable dynamically
EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
# This is a file that the user can use for overrides of the kubelet args as a last resort. Preferably, the user should use
# the .NodeRegistration.KubeletExtraArgs object in the configuration files instead. KUBELET_EXTRA_ARGS should be sourced from this file.
EnvironmentFile=-/etc/default/kubelet
ExecStart=
ExecStart=/usr/bin/kubelet \$KUBELET_KUBECONFIG_ARGS \$KUBELET_CONFIG_ARGS \$KUBELET_KUBEADM_ARGS \$KUBELET_EXTRA_ARGS
EOF
    mv 10-kubeadm.conf /etc/systemd/system/kubelet.service.d/

    systemctl daemon-reload
    systemctl enable kubelet.service
    systemctl status kubelet.service --no-pager

    systemctl stop ufw
    systemctl disable ufw

    swapoff -a
    sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    #remove multiple hashes added by the above command
    sed -i "s?\#\#\#?\#?g" /tmp/test.sh
    modprobe br_netfilter
    cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
    sysctl --system

    dpkg -i $K8S_OFFLINE_DIR/tools/conntrack_1.4.4+snapshot20161117-6ubuntu2_$arch.deb
    dpkg -i $K8S_OFFLINE_DIR/tools/socat_1.7.3.2-2ubuntu2_$arch.deb
}

function _kubernetes_tool_undeploy () {
    kubeadm reset -f

    for cmd in kubectl kubeadm kubelet; do rm  /usr/bin/$cmd; done

    systemctl stop kubelet.service
    systemctl disable kubelet.service
    rm -rf /etc/systemd/system/kubelet.service /etc/systemd/system/kubelet.service.d/
    systemctl status kubelet.service --no-pager
    systemctl daemon-reload

    rm -rf ~/.kube
    rm -rf /var/lib/etcd
    rm -rf /etc/kubernetes/
    rm -rf /etc/cni/net.d
    rm -rf /opt/cni
    rm -rf /var/lib/kubelet

    iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X

    dpkg -r socat conntrack
}

function kubernetes_deploy() {
  kubectl cluster-info >/dev/null 2>&1
  if [[ $? != 0 ]]; then
    export K8S_OFFLINE_DIR=${K8S_OFFLINE_DIR:-.}
    _docker_deploy
    _docker_images_load $K8S_DOCKER_IMAGES
    _kubernetes_tool_deploy

    if [ "$K8S_NODE_TYPE" == "MASTER" ]
    then
      if [ -z "$K8S_MASTER_IP" ]
      then
        info "K8S_MASTER_IP is not set." $RED
      else
        kubeadm config images list
        kubeadm init --kubernetes-version=v1.18.7 --apiserver-advertise-address=$K8S_MASTER_IP --pod-network-cidr=10.244.0.0/16 -v=5

        mkdir -p ~/.kube
        cp -i /etc/kubernetes/admin.conf ~/.kube/config

        kubectl apply -f $K8S_OFFLINE_DIR/k8s/calico.yaml

        kubectl taint nodes --all node-role.kubernetes.io/master-

        kubectl get all --all-namespaces
        #kubectl apply -f $K8S_OFFLINE_DIR/k8s/nginx-app.yaml
        #kubectl get pods

        kubeadm token create --print-join-command > $K8S_OFFLINE_DIR/k8s-worker.sh
      fi
    fi
  else
    info "kubernetes cluster already exists....." $BLUE
    info "Lets Continue with it......" $BLUE
  fi
}

function kubernetes_undeploy() {
    _kubernetes_tool_undeploy
    _docker_images_remove $K8S_DOCKER_IMAGES
    _docker_undeploy
}
#================================================================================

#===========================EG-eco-system=========================================

function _install_sshpass ()
{
  sshpass -V >/dev/null
  if [ $? -eq 0 ]; then
    info "sshpass already exists" $BLUE
  else
    cd "$TARBALL_PATH"/
    dpkg -i sshpass_1.06-1_$arch.deb
  fi
}

function _help_insecure_registry()
{
  grep  -i "insecure-registries" /etc/docker/daemon.json | grep "$PRIVATE_REGISTRY_IP:5000" >/dev/null 2>&1
  if [  $? != 0 ]; then
    mkdir -p /etc/docker

    if [[ $1 == "deployNode" ]]; then
cat <<EOF | tee /etc/docker/daemon.json
{
    "insecure-registries" : ["$PRIVATE_REGISTRY_IP:5000"]
}
EOF
    else
cat <<EOF | tee /etc/docker/daemon.json
{
    "insecure-registries" : ["$PRIVATE_REGISTRY_IP:5000", "$HARBOR_REPO_IP"]
}
EOF
    fi
    service docker restart
  fi
}

function _setup_insecure_registry ()
{
  MASTER_IP=$1
  WORKER_LIST=`echo $2 | sed -e "s/,/ /g"`
  if [[ "$OFFLINE_MODE" == "muno" && -n $MASTER_IP ]]; then
    #setup insecure registry on all EG Nodes
    for node_ip in $MASTER_IP;
    do
      scp $TARBALL_PATH/eg.sh root@$node_ip:/tmp/remote-platform
      sshpass ssh root@$node_ip \
      "source /tmp/remote-platform/eg.sh; export PRIVATE_REGISTRY_IP=$PRIVATE_REGISTRY_IP;
       export HARBOR_REPO_IP=$HARBOR_REPO_IP;
       _help_insecure_registry;" < /dev/null
    done
    if [[ -n $WORKER_LIST ]]; then
    for node_ip in $WORKER_LIST;
    do
      scp $TARBALL_PATH/eg.sh root@$node_ip:/tmp/remote-platform
      sshpass ssh root@$node_ip \
      "source /tmp/remote-platform/eg.sh; export PRIVATE_REGISTRY_IP=$PRIVATE_REGISTRY_IP;
       export HARBOR_REPO_IP=$HARBOR_REPO_IP;
       _help_insecure_registry;" < /dev/null
    done
    fi
  fi
}

function _load_and_run_docker_registry()
{
  if [ "$OFFLINE_MODE" == "muno" ]; then
    docker ps | grep registry >/dev/null
    if [ $? != 0 ]; then
      cd "$TARBALL_PATH"/registry
      docker load --input registry-2.tar.gz
      docker run -d -p 5000:5000 --restart=always --name registry registry:2
    fi
  fi
}

function _load_swr_images_and_push_to_private_registry()
{
  IP=$PRIVATE_REGISTRY_IP
  PORT="5000"
  cd "$TARBALL_PATH"/eg_swr_images
  if ! resilient_utility "read" ":DEPLOYED"; then
  for f in *.tar.gz;
  do
    cat $f | docker load
    if [ "$OFFLINE_MODE" == "muno" ]; then
      if [ "$f" = "eg_images.tar.gz" ]; then
        if [ ! -f "eg_images_list.txt" ]; then
          info "[Can not find file eg_images_list.txt]" $RED
          exit 1
        fi
        images=`cat eg_images_list.txt`
        for IMAGE_NAME in $images
        do
          docker image tag $IMAGE_NAME $IP:$PORT/$IMAGE_NAME
          docker push $IP:$PORT/$IMAGE_NAME
        done
      else
        IMAGE_NAME=`echo $f|rev|cut -c8-|rev|sed -e "s/\#/:/g" | sed -e "s/\@/\//g"`;
        docker image tag $IMAGE_NAME $IP:$PORT/$IMAGE_NAME
        docker push $IP:$PORT/$IMAGE_NAME
      fi
    fi
  done
  fi
}

function _help_install_helm_binary()
{
  HELM_VERSION="v3.2.4"
  helm_check=$(helm version | cut -d \" -f2)
  if [[ $helm_check == $HELM_VERSION ]];then
    info "Helm $HELM_VERSION is already installed" $BLUE
  else
    cd "$TARBALL_PATH"/helm || exit
    #install helm on deploy node for setting up helm index
    tar -zxf helm-v3.2.4-linux-$arch.tar.gz; mv linux-$arch/helm /usr/local/bin/;
  fi
}

function _install_helm_binary()
{
  #install helm on all the nodelist
  if [ "$OFFLINE_MODE" == "muno" ]; then
    MASTER_IP=$1
    for node_ip in $MASTER_IP;
    do
      scp $TARBALL_PATH/eg.sh root@$node_ip:/tmp/remote-platform
      scp $TARBALL_PATH/helm/helm-v3.2.4-linux-$arch.tar.gz root@$node_ip:/tmp/remote-platform/helm/;
      sshpass ssh root@$node_ip \
      "source /tmp/remote-platform/eg.sh;export TARBALL_PATH=/tmp/remote-platform;_help_install_helm_binary" < /dev/null
    done
  fi
}

function _setup_helm_repo()
{
  cd "$TARBALL_PATH"/helm/helm-charts/ || exit
  helm repo index edgegallery/
  helm repo index stable/
  return_value=$(docker ps | grep helm-repo)
  return_value=$?
  if [[ $return_value -ne 0 ]]; then
    docker run --name helm-repo -v "$TARBALL_PATH"/helm/helm-charts/:/usr/share/nginx/html:ro  -d -p 8080:80  nginx:stable
  fi
  helm repo remove edgegallery stable >/dev/null 2>&1;
  sleep 3
  helm repo add edgegallery http://${PRIVATE_REGISTRY_IP}:8080/edgegallery;
  helm repo add stable http://${PRIVATE_REGISTRY_IP}:8080/stable
}

function cleanup_eg_ecosystem()
{
  helm repo remove edgegallery stable >/dev/null 2>&1
  docker stop helm-repo; docker rm -v helm-repo
  docker stop registry; docker rm -v registry
  docker image prune -a -f
  rm /root/.kube/config
  rm /etc/docker/daemon.json
  rm -rf /etc/docker/certs.d
  _docker_compose_undeploy
  rm -rf /root/harbor
  service docker restart
}

function setup_eg_ecosystem()
{
  if resilient_utility "read" ":DEPLOYED"; then
    return 0
  fi
  tar -xf $TARBALL_PATH/kubernetes_offline_installer.tar.gz -C $K8S_OFFLINE_DIR;
  export K8S_NODE_TYPE=WORKER; kubernetes_deploy;
  if [ "$OFFLINE_MODE" == "muno" ]; then
    _help_insecure_registry deployNode
    _load_and_run_docker_registry
  fi
  _load_swr_images_and_push_to_private_registry
  _help_install_helm_binary
  if [ "$OFFLINE_MODE" == "muno" ]; then
    _setup_helm_repo
  fi
  if [ "$OFFLINE_MODE" == "aio" ]; then
info "[harbor just support x86]"  $YELLOW
    if [`arch` == "x86_64"];then
       _setup_harbor
    fi
  fi
}

function configure_eg_ecosystem_on_remote()
{
  MASTER_IP=$1
  WORKER_LIST=$2
  _setup_insecure_registry $MASTER_IP $WORKER_LIST
  for node_ip in $MASTER_IP;
  do
      sshpass ssh root@$node_ip \
      "helm repo remove edgegallery stable; helm repo add edgegallery http://${PRIVATE_REGISTRY_IP}:8080/edgegallery;
       helm repo add stable http://${PRIVATE_REGISTRY_IP}:8080/stable" < /dev/null
      sshpass ssh root@$node_ip "export HARBOR_REPO_IP=$HARBOR_REPO_IP;
              export K8S_OFFLINE_DIR=$K8S_OFFLINE_DIR;source /tmp/remote-platform/eg.sh"
      if [`arch` == "x86_64"];then
      sshpass ssh root@$node_ip "_setup_harbor"
      fi 
  done
  for node_ip in $WORKER_LIST;
  do
    sshpass ssh root@$node_ip "docker login -u$HARBOR_USER -p$HARBOR_PASSWORD $HARBOR_REPO_IP;"
  done
}

#=========================eg deploy==================================
export RED='\033[0;31m'
export NC='\033[0m'
export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export YELLOW='\033[1;33m'
export CYAN='\033[0;36m'
export PURPLE='\033[0;35m'
export ORANGE='\033[0;33m'

function print_eg_logo()
{
  echo ""
  echo -e "$PURPLE                              *"
  echo -e "$PURPLE                            *   *"
  echo -e "$PURPLE                          *       *"
  echo -e "$PURPLE                        *$GREEN           *"
  echo -e "$PURPLE                        * *$GREEN       *"
  echo -e "$PURPLE                        *    *$GREEN  *     *$PURPLE      EDGE"
  echo -e "$PURPLE                        *$GREEN     *    *  *     GALLERY"
  echo -e "$PURPLE                        *$GREEN     *     *"
  echo -e "$PURPLE                          *$GREEN   *   *"
  echo -e "$PURPLE                            *$GREEN * *"
  echo -e "$GREEN                              *$NC"
}

function print_portal_urls()
{
  echo ""
  echo -e "$GREEN APPSTORE PORTAL   : $BLUE https://$PORTAL_IP:$APPSTORE_PORT"
  echo -e "$GREEN DEVELOPER PORTAL  : $BLUE https://$PORTAL_IP:$DEVELOPER_PORT"
  echo -e "$GREEN MECM PORTAL       : $BLUE https://$PORTAL_IP:$MECM_PORT"
  echo -e "$GREEN ATP PORTAL        : $BLUE https://$PORTAL_IP:$ATP_PORT"
  echo ""
}

function log() {
  setx=${-//[^x]/}
  set +x
  fname=$(caller 0 | awk '{print $2}')
  fline=$(caller 0 | awk '{print $1}')
  echo; echo -e "$CYAN $INSTALLER_INDEX $2 $(basename $0) $fname:$fline ($(date)) $1 $NC"
  if [[ -n "$setx" ]]; then
    set -x;
  else
    set +x;
  fi
}

function info() {
  setx=${-//[^x]/}
  set +x
  echo -e "$CYAN $INSTALLER_INDEX $2 $1 $NC"
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
  t=0
  if [[ $3 == "yes" ]]; then
    return=$3
  else
    return="no"
  fi

  while true
  do
    if [[ $2 -gt 1 ]]; then
      verb="pods are"
    else
      verb="pod is"
    fi
    if [[ $1 == "-n mep" ]]; then
      namespace="-n mep"
    else
      namespace="--all-namespaces"
    fi
    if [[ $(kubectl get pods $namespace | grep "$1" | grep "Running" | wc -l ) -eq $2 ]]; then
      info "[$1 $verb in RUNNING state ]" $GREEN
      break
    fi
    info "[Lets wait for $1 pod's RUNNING state]"  $YELLOW
    t=$((t+5))
    if [ $t == 150 ]; then
      info "[ISSUE: $1 $verb not in RUNNING state ]" $RED
      info "[Suggestion: check $1 pod's log  ......]" $RED
      if [[ $return == "yes" ]]; then
        return 1
      else
        exit 1
      fi
    fi
    sleep 5
  done
}

function wait_for_ready_state() {
  t=0
  while true
  do
    kubectl -n kube-system get pods -o custom-columns=NAMESPACE:metadata.namespace,POD:metadata.name,PodIP:status.podIP,READY-true:status.containerStatuses[*].ready | grep false >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      info "[k8s pods are in READY state ]" $GREEN
      break
    fi
    info "[Lets wait for k8s pod's READY state]"  $YELLOW
    t=$((t+5))
    if [ $t == 150 ]; then
      info "[ISSUE: k8s pods are not in READY state ]" $RED
      info "[k8s deployment FAILED  ................]" $RED
      info "[SUGGESTION: check logs of the below pods ..........]" $RED
      kubectl -n kube-system get pods -o custom-columns=NAMESPACE:metadata.namespace,POD:metadata.name,PodIP:status.podIP,READY-true:status.containerStatuses[*].ready | grep false
      exit 1
    fi
    sleep 5
  done
}

function _eg_deploy()
{
  FEATURE=$1
  DEPLOY_NODE_IP=$2
  MASTER_IP=$3
  if [[ -z $PORTAL_IP ]]; then
    if [[ $OFFLINE_MODE == "aio" ]]; then
      PORTAL_IP=$DEPLOY_NODE_IP
    else
      PORTAL_IP=$MASTER_IP
    fi
  fi
  if [[ $FEATURE == 'edge' || $FEATURE == 'all' ]]; then
    if [[ $OFFLINE_MODE == "aio" ]]; then
      rm -rf /mnt/grafana; mkdir -p /mnt/grafana
      cp $PLATFORM_DIR/conf/keys/tls.key /mnt/grafana/
      cp $PLATFORM_DIR/conf/keys/tls.crt /mnt/grafana/
      if [[ ! -d /opt/cni/bin ]]; then
        mkdir -p /opt/cni/bin
      fi
      cp $K8S_OFFLINE_DIR/cni/macvlan /opt/cni/bin/
      cp $K8S_OFFLINE_DIR/cni/host-local /opt/cni/bin/
    else
      sshpass ssh root@$MASTER_IP "rm -rf /mnt/grafana; mkdir -p /mnt/grafana"
      scp $PLATFORM_DIR/conf/keys/tls.key root@$MASTER_IP:/mnt/grafana/
      scp $PLATFORM_DIR/conf/keys/tls.crt root@$MASTER_IP:/mnt/grafana/

      sshpass ssh root@$MASTER_IP "mkdir -p /opt/cni/bin"
      scp $K8S_OFFLINE_DIR/cni/macvlan root@$MASTER_IP:/opt/cni/bin/
      scp $K8S_OFFLINE_DIR/cni/host-local root@$MASTER_IP:/opt/cni/bin/
    fi
  fi
  install_EdgeGallery $FEATURE $PORTAL_IP
}

function _eg_undeploy()
{
  FEATURE=$1
  MASTER_IP=$2
  WORKER_IPS=$3
  WORKER_IPS=`echo $WORKER_IPS | sed -e "s/,/ /g"`
  uninstall_EdgeGallery $FEATURE
  kubectl delete -f $K8S_OFFLINE_DIR/k8s/metric-server.yaml
  if [[ $SKIP_ECO_SYSTEM_UN_INSTALLATION != "true" ]]; then
    cleanup_eg_ecosystem
  fi
  if [ $OFFLINE_MODE == "muno" ]; then
    for node_ip in $MASTER_IP;
    do
      if [[ $SKIP_ECO_SYSTEM_UN_INSTALLATION != "true" ]]; then
        sshpass ssh root@$node_ip \
        "docker image prune -a -f; rm /etc/docker/daemon.json;
         rm -rf /etc/docker/certs.d; rm -rf /root/harbor;
         service docker restart; rm /usr/local/bin/docker-compose;"
      fi
    done
    for node_ip in $WORKER_IPS;
    do
      if [[ $SKIP_ECO_SYSTEM_UN_INSTALLATION != "true" ]]; then
        sshpass ssh root@$node_ip \
        "docker image prune -a -f; rm /etc/docker/daemon.json;
         service docker restart"
      fi
    done
  fi
  rm -rf ~/.eg/
}

function install_prometheus()
{
  if resilient_utility "read" "PROMETHEUS:FAILED";then
    uninstall_prometheus
  fi

  if resilient_utility "read" "PROMETHEUS:UN_DEPLOYED";then
    info "[Deploying Prometheus  ......]" $BLUE
    info "[it would take maximum of 5mins .......]" $BLUE
    if [ $KERNEL_ARCH == 'aarch64' ]; then
      helm install --wait mep-prometheus "$CHART_PREFIX"stable/prometheus"$PROM_CHART_SUFFIX" \
      -f $PLATFORM_DIR/conf/override/prometheus_arm_values.yaml --version v9.3.1 \
      --set alertmanager.image.repository="$REGISTRY_URL"prom/alertmanager \
      --set configmapReload.image.repository="$REGISTRY_URL"jimmidyson/configmap-reload \
      --set nodeExporter.image.repository="$REGISTRY_URL"prom/node-exporter \
      --set server.image.repository="$REGISTRY_URL"prom/prometheus \
      --set pushgateway.image.repository="$REGISTRY_URL"prom/pushgateway \
      --set kubeStateMetrics.image.repository="$REGISTRY_URL"carlosedp/kube-state-metrics \
      --set alertmanager.image.pullPolicy=IfNotPresent \
      --set configmapReload.image.pullPolicy=IfNotPresent \
      --set nodeExporter.image.pullPolicy=IfNotPresent \
      --set server.image.pullPolicy=IfNotPresent \
      --set pushgateway.image.pullPolicy=IfNotPresent \
      --set kubeStateMetrics.image.pullPolicy=IfNotPresent
    else
      helm install --wait mep-prometheus "$CHART_PREFIX"stable/prometheus"$PROM_CHART_SUFFIX" \
      -f $PLATFORM_DIR/conf/override/prometheus_x86_values.yaml --version v9.3.1 \
      --set alertmanager.image.repository="$REGISTRY_URL"prom/alertmanager \
      --set configmapReload.image.repository="$REGISTRY_URL"jimmidyson/configmap-reload \
      --set nodeExporter.image.repository="$REGISTRY_URL"prom/node-exporter \
      --set server.image.repository="$REGISTRY_URL"prom/prometheus \
      --set pushgateway.image.repository="$REGISTRY_URL"prom/pushgateway \
      --set kubeStateMetrics.image.repository="$REGISTRY_URL"quay.io/coreos/kube-state-metrics \
      --set alertmanager.image.pullPolicy=IfNotPresent \
      --set configmapReload.image.pullPolicy=IfNotPresent \
      --set nodeExporter.image.pullPolicy=IfNotPresent \
      --set server.image.pullPolicy=IfNotPresent \
      --set pushgateway.image.pullPolicy=IfNotPresent \
      --set kubeStateMetrics.image.pullPolicy=IfNotPresent
    fi
    if [ $? -eq 0 ]; then
      info "[Deployed Prometheus  .......]" $GREEN
      resilient_utility "write" "PROMETHEUS:DEPLOYED"
    else
      info "[Prometheus Deployment Failed]" $RED
      resilient_utility "write" "PROMETHEUS:FAILED"
      exit 1
    fi
  fi
}

function uninstall_prometheus()
{
  info "[UnDeploying Prometheus  ....]" $BLUE
  helm uninstall mep-prometheus
  resilient_utility "write" "PROMETHEUS:UN_DEPLOYED"
  info "[UnDeploying Prometheus  ....]" $GREEN
}

function install_grafana()
{
  if resilient_utility "read" "GRAFANA:FAILED";then
    uninstall_grafana
  fi

  if resilient_utility "read" "GRAFANA:UN_DEPLOYED";then
    info "[Deploying Grafana  .........]" $BLUE
    info "[it would take maximum of 5mins .......]" $BLUE

    kubectl apply -f $PLATFORM_DIR/conf/manifest/pv_pvc/pv-volume.yaml
    kubectl apply -f $PLATFORM_DIR/conf/manifest/pv_pvc/pv-claim.yaml

    if [ $KERNEL_ARCH == 'aarch64' ]; then
      helm install --wait mep-grafana "$CHART_PREFIX"stable/grafana"$GRAFANA_CHART_SUFFIX" \
      -f $PLATFORM_DIR/conf/override/grafana_arm_values.yaml \
      --set image.repository="$REGISTRY_URL"grafana/grafana-arm64v8-linux \
      --set testFramework.image="$REGISTRY_URL"bats/bats \
      --set downloadDashboardsImage.repository="$REGISTRY_URL"lucashalbert/curl \
      --set initChownData.image.repository="$REGISTRY_URL"busybox \
      --set sidecar.image.repository="$REGISTRY_URL"kiwigrid/k8s-sidecar \
      --set image.pullPolicy=IfNotPresent \
      --set testFramework.pullPolicy=IfNotPresent \
      --set downloadDashboardsImage.pullPolicy=IfNotPresent \
      --set initChownData.image.pullPolicy=IfNotPresent \
      --set sidecar.image.pullPolicy=IfNotPresent
    else
      helm install --wait mep-grafana "$CHART_PREFIX"stable/grafana"$GRAFANA_CHART_SUFFIX" \
      -f $PLATFORM_DIR/conf/override/grafana_x86_values.yaml \
      --set image.repository="$REGISTRY_URL"grafana/grafana \
      --set testFramework.image="$REGISTRY_URL"bats/bats \
      --set downloadDashboardsImage.repository="$REGISTRY_URL"curlimages/curl \
      --set initChownData.image.repository="$REGISTRY_URL"busybox \
      --set sidecar.image.repository="$REGISTRY_URL"kiwigrid/k8s-sidecar \
      --set image.pullPolicy=IfNotPresent \
      --set testFramework.imagePullPolicy=IfNotPresent \
      --set downloadDashboardsImage.pullPolicy=IfNotPresent \
      --set initChownData.image.pullPolicy=IfNotPresent \
      --set sidecar.image.pullPolicy=IfNotPresent
    fi
    if [ $? -eq 0 ]; then
      info "[Deployed Grafana  ..........]" $GREEN
      resilient_utility "write" "GRAFANA:DEPLOYED"
    else
      info "[Grafana Deployment Failed  .]" $RED
      resilient_utility "write" "GRAFANA:FAILED"
      exit 1
    fi
  fi
}

function uninstall_grafana()
{
  info "[UnDeploying Grafana  .......]" $BLUE
  helm uninstall mep-grafana
  kubectl delete pvc grafana-pv-claim
  kubectl delete pv grafana-pv-volume
  rm /mnt/grafana/tls.key
  rm /mnt/grafana/tls.crt
  rmdir /mnt/grafana
  resilient_utility "write" "GRAFANA:UN_DEPLOYED"
  info "[UnDeployed Grafana  ........]" $GREEN
}

function _prepare_mep_ssl()
{
  set +o history
  # initial variables
  set +x

  if [[ -z $PG_ADMIN_PWD ]]; then
    PG_ADMIN_PWD=admin-Pass123
  fi
  if [[ -z $KONG_PG_PWD ]]; then
    KONG_PG_PWD=kong-Pass123
  fi
  if [[ -z $CERT_PWD ]]; then
    CERT_PWD=te9Fmv%qaq
  fi

  MEP_CERTS_DIR=/tmp/.mep_tmp_cer
  CERT_NAME=${CERT_NAME:-mepserver}
  DOMAIN_NAME=edgegallery

  rm -rf ${MEP_CERTS_DIR}
  mkdir -p ${MEP_CERTS_DIR}
  cd ${MEP_CERTS_DIR} || exit

  # generate ca certificate
  openssl genrsa -out ca.key 2048 2>&1 >/dev/null
  openssl req -new -key ca.key -subj /C=CN/ST=Peking/L=Beijing/O=edgegallery/CN=${DOMAIN_NAME} -out ca.csr 2>&1 >/dev/null
  openssl x509 -req -days 365 -in ca.csr -extensions v3_ca -signkey ca.key -out ca.crt 2>&1 >/dev/null
  # openssl ca -days 365 -in ca.csr -extensions v3_ca -keyfile ca.key -out ca.crt

  # generate tls certificate
  openssl genrsa -out ${CERT_NAME}_tls.key 2048 2>&1 >/dev/null
  openssl rsa -in ${CERT_NAME}_tls.key -aes256 -passout pass:${CERT_PWD} -out ${CERT_NAME}_encryptedtls.key 2>&1 >/dev/null

  echo -n ${CERT_PWD} > ${CERT_NAME}_cert_pwd 2>&1 >/dev/null

  openssl req -new -key ${CERT_NAME}_tls.key -subj /C=CN/ST=Beijing/L=Beijing/O=edgegallery/CN=${DOMAIN_NAME} -out ${CERT_NAME}_tls.csr 2>&1 >/dev/null
  openssl x509 -req -days 365 -in ${CERT_NAME}_tls.csr -extensions v3_req -CA ca.crt -CAkey ca.key -CAcreateserial -out ${CERT_NAME}_tls.crt 2>&1 >/dev/null

  # generate jwt public private key
  openssl genrsa -out jwt_privatekey 2048 2>&1 >/dev/null
  openssl rsa -in jwt_privatekey -pubout -out jwt_publickey 2>&1 >/dev/null
  openssl rsa -in jwt_privatekey -aes256 -passout pass:${CERT_PWD} -out jwt_encrypted_privatekey 2>&1 >/dev/null

  # remove unnecessary key file
  rm ca.key 2>&1 >/dev/null
  rm ca.csr 2>&1 >/dev/null
  rm ca.crl 2>&1 >/dev/null
  rm ${CERT_NAME}_tls.csr 2>&1 >/dev/null
  rm jwt_privatekey 2>&1 >/dev/null

  # setup read permission
  cd ..
  chmod 600 ${MEP_CERTS_DIR}/*

  kubectl create ns mep

  kubectl -n mep create secret generic pg-secret \
    --from-literal=pg_admin_pwd=$PG_ADMIN_PWD \
    --from-literal=kong_pg_pwd=$KONG_PG_PWD \
    --from-file=server.key=${MEP_CERTS_DIR}/${CERT_NAME}_tls.key \
    --from-file=server.crt=${MEP_CERTS_DIR}/${CERT_NAME}_tls.crt

  kubectl -n mep create secret generic mep-ssl \
    --from-literal=root_key="$(openssl rand -base64 256 | tr -d '\n' | tr -dc '[[:alnum:]]' | cut -c -256)" \
    --from-literal=cert_pwd=$CERT_PWD \
    --from-file=server.cer=${MEP_CERTS_DIR}/${CERT_NAME}_tls.crt \
    --from-file=server_key.pem=${MEP_CERTS_DIR}/${CERT_NAME}_encryptedtls.key \
    --from-file=trust.cer=${MEP_CERTS_DIR}/ca.crt

  kubectl -n mep create secret generic mepauth-secret \
    --from-file=server.crt=${MEP_CERTS_DIR}/${CERT_NAME}_tls.crt \
    --from-file=server.key=${MEP_CERTS_DIR}/${CERT_NAME}_tls.key \
    --from-file=ca.crt=${MEP_CERTS_DIR}/ca.crt \
    --from-file=jwt_publickey=${MEP_CERTS_DIR}/jwt_publickey \
    --from-file=jwt_encrypted_privatekey=${MEP_CERTS_DIR}/jwt_encrypted_privatekey

  rm -rf ${MEP_CERTS_DIR} 2>&1 >/dev/null
  set -o history
}

function install_mep()
{
  if resilient_utility "read" "MEP:FAILED";then
    uninstall_mep
  fi

  if resilient_utility "read" "MEP:UN_DEPLOYED";then
    number_of_nodes=$(kubectl get nodes |wc -l)
    if [[ $number_of_nodes -ge 3 ]]; then
      ((number_of_nodes=number_of_nodes-1))
    else
      number_of_nodes=1
    fi
    INSTALLER_INDEX="E.1.1:"
    _prepare_mep_ssl
    INSTALLER_INDEX="E.1.2:"
    _deploy_dns_metallb
    INSTALLER_INDEX="E.1.3:"
    info "[Setting up Network Isolation]" $BLUE
    _deploy_network_isolation_multus
    INSTALLER_INDEX="E.1.4:"

    info "[Deploying MEP  .............]" $BLUE
    if [[ $OFFLINE_MODE == 'muno' ]] ; then
      ipam_type=whereabouts
      phyif_mp1=vxlan-mp1
      phyif_mm5=vxlan-mm5
    else
      ipam_type=host-local
      phyif_mp1=$EG_NODE_EDGE_MP1
      phyif_mm5=$EG_NODE_EDGE_MM5
    fi
    info "[it would take maximum of 5mins .......]" $BLUE
    helm install --wait mep-edgegallery "$CHART_PREFIX"edgegallery/mep"$CHART_SUFFIX" \
    --set networkIsolation.ipamType=$ipam_type \
    --set networkIsolation.phyInterface.mp1=$phyif_mp1 \
    --set networkIsolation.phyInterface.mm5=$phyif_mm5 \
    --set images.mep.repository=$mep_images_mep_repository \
    --set images.mepFe.repository=$mep_images_mep_fe_repository \
    --set images.mepauth.repository=$mep_images_mepauth_repository \
    --set images.dns.repository=$mep_images_dns_repository \
    --set images.kong.repository=$mep_images_kong_repository \
    --set images.postgres.repository=$mep_images_postgres_repository \
    --set images.elasticsearch.repository=$mep_images_elasticsearch_repository \
    --set images.mep.tag=$mep_images_mep_tag \
    --set images.mepFe.tag=$mep_images_mep_fe_tag \
    --set images.mepauth.tag=$mep_images_mepauth_tag \
    --set images.dns.tag=$mep_images_dns_tag \
    --set images.kong.tag=$mep_images_kong_tag \
    --set images.postgres.tag=$mep_images_postgres_tag \
    --set images.elasticsearch.tag=$mep_images_elasticsearch_tag \
    --set images.mep.pullPolicy=$mep_images_mep_pullPolicy \
    --set images.mep-fe.pullPolicy=$mep_images_mep_pullPolicy \
    --set images.mepauth.pullPolicy=$mep_images_mepauth_pullPolicy \
    --set images.dns.pullPolicy=$mep_images_dns_pullPolicy \
    --set images.kong.pullPolicy=$mep_images_kong_pullPolicy \
    --set images.postgres.pullPolicy=$mep_images_postgres_pullPolicy \
    --set images.elasticsearch.pullPolicy=$mep_images_elasticsearch_pullPolicy \
    --set ssl.secretName=$mep_ssl_secretName \
    --set global.persistence.enabled=$ENABLE_PERSISTENCE

    if [ $? -eq 0 ]; then
      info "[Deployed MEP  .........]" $GREEN
      resilient_utility "write" "MEP:DEPLOYED"
    else
      info "[MEP Deployment Failed  ]" $RED
      resilient_utility "write" "MEP:FAILED"
      exit 1
    fi
    info "[Deployed MEP  ..............]" $GREEN
  fi
}

function _remove_mep_ssl_config()
{
  kubectl delete secret pg-secret -n mep
  kubectl delete secret mep-ssl -n mep
  kubectl delete secret mepauth-secret -n mep
  #kubectl delete ns mep
}

function uninstall_mep()
{
  info "[UnDeploying MEP  ...........]" $BLUE
  helm uninstall mep-edgegallery
  _remove_mep_ssl_config
  _undeploy_network_isolation_multus
  _undeploy_dns_metallb
  resilient_utility "write" "MEP:UN_DEPLOYED"
  info "[UnDeployed MEP  ............]" $GREEN
}

function install_common-svc()
{
  INSTALLER_INDEX="E.3.1:"
  install_prometheus
  INSTALLER_INDEX="E.3.2:"
  install_grafana
}

function uninstall_common-svc()
{
  uninstall_prometheus
  uninstall_grafana
}

function install_mecm-mepm ()
{
  if resilient_utility "read" "MECM_MEPM:FAILED";then
    uninstall_mecm-mepm
  fi

  if resilient_utility "read" "MECM_MEPM:UN_DEPLOYED";then
    info "[Deploying MECM-MEPM  .......]" $BLUE
    info "[it would take maximum of 5mins .......]" $BLUE

    ## Create a jwt public key secret for applcm
    kubectl create secret generic mecm-mepm-jwt-public-secret \
      --from-file=publicKey=$PLATFORM_DIR/conf/keys/rsa_public_key.pem

    ## Create a ssl secret
    kubectl create secret generic mecm-mepm-ssl-secret \
      --from-file=server_tls.key=$PLATFORM_DIR/conf/keys/tls.key \
      --from-file=server_tls.crt=$PLATFORM_DIR/conf/keys/tls.crt \
      --from-file=ca.crt=$PLATFORM_DIR/conf/keys/ca.crt

    ## Create a mecm-mepm secret with postgres_init.sql file to create necessary db's
    kubectl create secret generic edgegallery-mepm-secret \
      --from-file=postgres_init.sql=$PLATFORM_DIR/conf/keys/postgres_init.sql \
      --from-literal=postgresPassword=te9Fmv%qaq \
      --from-literal=postgresLcmCntlrPassword=te9Fmv%qaq \
      --from-literal=postgresk8sPluginPassword=te9Fmv%qaq \
      --from-literal=postgresosPluginPassword=te9Fmv%qaq   \
      --from-literal=postgresRuleMgrPassword=te9Fmv%qaq  

    kubectl apply -f $PLATFORM_DIR/conf/manifest/mepm/mepm-service-account.yaml

    helm install --wait mecm-mepm-edgegallery "$CHART_PREFIX"edgegallery/mecm-mepm"$CHART_SUFFIX" \
    --set jwt.publicKeySecretName=$mepm_jwt_publicKeySecretName \
    --set mepm.secretName=$mepm_mepm_secretName \
    --set ssl.secretName=$mepm_ssl_secretName \
    --set images.lcmcontroller.repository=$mepm_images_lcmcontroller_repository \
    --set images.k8splugin.repository=$mepm_images_k8splugin_repository \
    --set images.osplugin.repository=$mepm_images_osplugin_repository \
    --set images.apprulemgr.repository=$mepm_images_apprulemgr_repository \
    --set images.mepmFe.repository=$mepm_images_fe_repository \
    --set images.postgres.repository=$mepm_images_postgres_repository \
    --set images.lcmcontroller.tag=$mepm_images_lcmcontroller_tag \
    --set images.k8splugin.tag=$mepm_images_k8splugin_tag \
    --set images.osplugin.tag=$mepm_images_osplugin_tag \
    --set images.apprulemgr.tag=$mepm_images_apprulemgr_tag \
    --set images.mepmFe.tag=$mepm_images_fe_tag \
    --set images.postgres.tag=$mepm_images_postgres_tag \
    --set images.lcmcontroller.pullPolicy=$mepm_images_lcmcontroller_pullPolicy \
    --set images.k8splugin.pullPolicy=$mepm_images_k8splugin_pullPolicy \
    --set images.osplugin.pullPolicy=$mepm_images_osplugin_pullPolicy \
    --set images.apprulemgr.pullPolicy=$mepm_images_apprulemgr_pullPolicy \
    --set images.mepmFe.pullPolicy=$mepm_images_fe_pullPolicy \
    --set images.postgres.pullPolicy=$mepm_images_postgres_pullPolicy \
    --set global.persistence.enabled=$ENABLE_PERSISTENCE
    if [ $? -eq 0 ]; then
      info "[Deployed MECM-MEPM  ........]" $GREEN
      resilient_utility "write" "MECM_MEPM:DEPLOYED"
    else
      info "[MECM-MEPM Deployment Failed ]" $RED
      resilient_utility "write" "MECM_MEPM:FAILED"
      exit 1
    fi
  fi
}

function uninstall_mecm-mepm ()
{
    info "[UnDeploying MECM-MEPM  .....]" $BLUE
    helm uninstall mecm-mepm-edgegallery
    kubectl delete secret mecm-mepm-jwt-public-secret mecm-mepm-ssl-secret edgegallery-mepm-secret
    kubectl delete -f $PLATFORM_DIR/conf/manifest/mepm/mepm-service-account.yaml
    resilient_utility "write" "MECM_MEPM:UN_DEPLOYED"
    info "[UnDeployed MECM-MEPM  ......]" $GREEN
}

function install_mecm-meo ()
{
  if resilient_utility "read" "MECM_MEO:FAILED";then
    uninstall_mecm-meo
  fi

  if resilient_utility "read" "MECM_MEO:UN_DEPLOYED";then
    info "[Deploying MECM-MEO  ........]" $BLUE
    info "[it would take maximum of 5mins .......]" $BLUE
    ## Create a keystore secret
    kubectl create secret generic mecm-ssl-secret \
    --from-file=keystore.p12=$PLATFORM_DIR/conf/keys/keystore.p12 \
    --from-file=keystore.jks=$PLATFORM_DIR/conf/keys/keystore.jks \
    --from-literal=keystorePassword=te9Fmv%qaq \
    --from-literal=keystoreType=PKCS12 \
    --from-literal=keyAlias=edgegallery \
    --from-literal=truststorePassword=te9Fmv%qaq

    ## Create a mecm-meo secret with postgres_init.sql file to create necessary db's
    kubectl create secret generic edgegallery-mecm-secret \
      --from-file=postgres_init.sql=$PLATFORM_DIR/conf/keys/postgres_init.sql \
      --from-literal=postgresPassword=te9Fmv%qaq \
      --from-literal=postgresApmPassword=te9Fmv%qaq \
      --from-literal=postgresAppoPassword=te9Fmv%qaq \
      --from-literal=postgresInventoryPassword=te9Fmv%qaq \
      --from-literal=dockerRepoUserName=$HARBOR_USER	 \
      --from-literal=dockerRepoPassword=$HARBOR_PASSWORD

    if [[ $OFFLINE_MODE == "muno" ]]; then
      sshpass ssh root@$MASTER_IP "rm -rf /tmp/remote-platform/remote_fsgroup;
                                 mkdir -p /tmp/remote-platform/;
                                 getent group docker | cut -d: -f3 > /tmp/remote-platform/remote_fsgroup"
      scp root@$MASTER_IP:/tmp/remote-platform/remote_fsgroup $K8S_OFFLINE_DIR
      fs_group=$(cat $K8S_OFFLINE_DIR/remote_fsgroup)
    else
      fs_group=$(getent group docker | cut -d: -f3)
    fi

    helm install --wait mecm-meo-edgegallery "$CHART_PREFIX"edgegallery/mecm-meo"$CHART_SUFFIX" \
    --set ssl.secretName=$meo_ssl_secretName \
    --set mecm.secretName=$meo_mecm_secretName \
    --set images.inventory.repository=$meo_images_inventory_repository \
    --set images.appo.repository=$meo_images_appo_repository \
    --set images.apm.repository=$meo_images_apm_repository \
    --set images.postgres.repository=$meo_images_postgres_repository \
    --set images.inventory.tag=$meo_images_inventory_tag \
    --set images.appo.tag=$meo_images_appo_tag \
    --set images.apm.tag=$meo_images_apm_tag \
    --set images.postgres.tag=$meo_images_postgres_tag \
    --set images.inventory.pullPolicy=$meo_images_inventory_pullPolicy \
    --set images.appo.pullPolicy=$meo_images_appo_pullPolicy \
    --set images.apm.pullPolicy=$meo_images_apm_pullPolicy \
    --set images.postgres.pullPolicy=$meo_images_postgres_pullPolicy \
    --set mecm.docker.fsgroup=$fs_group \
    --set global.persistence.enabled=$ENABLE_PERSISTENCE \
    --set mecm.repository.dockerRepoEndpoint=$HARBOR_REPO_IP \
    --set mecm.repository.sourceRepos="repo=$HARBOR_REPO_IP userName=$HARBOR_USER password=$HARBOR_PASSWORD"
    if [ $? -eq 0 ]; then
      info "[Deployed MECM-MEO  .........]" $GREEN
      resilient_utility "write" "MECM_MEO:DEPLOYED"
    else
      info "[MECM-MEO Deployment Failed  ]" $RED
      resilient_utility "write" "MECM_MEO:FAILED"
      exit 1
    fi
  fi
}

function uninstall_mecm-meo ()
{
    info "[UnDeploying MECM-MEO  ........]" $BLUE
    helm uninstall mecm-meo-edgegallery
    kubectl delete secret mecm-ssl-secret edgegallery-mecm-secret
    resilient_utility "write" "MECM_MEO:UN_DEPLOYED"
    info "[UnDeployed MECM-MEO  .......]" $GREEN
}

function install_mecm-fe ()
{
  if resilient_utility "read" "MECM_FE:FAILED";then
    uninstall_mecm-fe
  fi

  if resilient_utility "read" "MECM_FE:UN_DEPLOYED";then
    info "[Deploying MECM-FE  ........]" $BLUE
    info "[it would take maximum of 5mins .......]" $BLUE
    helm install --wait mecm-fe-edgegallery "$CHART_PREFIX"edgegallery/mecm-fe"$CHART_SUFFIX" \
    --set global.oauth2.authServerAddress=https://$NODEIP:$USER_MGMT \
    --set images.mecmFe.repository=$mecm_fe_images_mecmFe_repository \
    --set images.initservicecenter.repository=$mecm_fe_images_initservicecenter_repository \
    --set images.mecmFe.tag=$mecm_fe_images_mecmFe_tag \
    --set images.initservicecenter.tag=$mecm_fe_images_initservicecenter_tag \
    --set images.mecmFe.pullPolicy=$mecm_fe_images_mecmFe_pullPolicy \
    --set images.initservicecenter.pullPolicy=$mecm_fe_images_initservicecenter_pullPolicy \
    --set global.ssl.enabled=$mecm_fe_global_ssl_enabled \
    --set global.ssl.secretName=$mecm_fe_global_ssl_secretName \
    --set global.persistence.enabled=$ENABLE_PERSISTENCE
    if [ $? -eq 0 ]; then
      info "[Deployed MECM-FE  ..........]" $GREEN
      resilient_utility "write" "MECM_FE:DEPLOYED"
    else
      info "[MECM-FE Deployment Failed  .]" $RED
      resilient_utility "write" "MECM_FE:FAILED"
      exit 1
    fi
  fi
}

function uninstall_mecm-fe ()
{
    info "[UnDeploying MECM-FE  .......]" $BLUE
    helm uninstall mecm-fe-edgegallery
    resilient_utility "write" "MECM_FE:UN_DEPLOYED"
    info "[UnDeployed MECM-FE  ........]" $GREEN
}

function install_appstore ()
{
  if resilient_utility "read" "APPSTORE:FAILED";then
    uninstall_appstore
  fi

  if resilient_utility "read" "APPSTORE:UN_DEPLOYED";then
    info "[Deploying AppStore  ........]" $BLUE
    info "[it would take maximum of 5mins .......]" $BLUE
    kubectl create secret generic edgegallery-appstore-docker-secret \
      --from-literal=devRepoUserName=$HARBOR_USER	 \
      --from-literal=devRepoPassword=$HARBOR_PASSWORD    \
      --from-literal=appstoreRepoUserName=$HARBOR_USER	 \
      --from-literal=appstoreRepoPassword=$HARBOR_PASSWORD
    helm install --wait appstore-edgegallery "$CHART_PREFIX"edgegallery/appstore"$CHART_SUFFIX" \
    --set global.oauth2.authServerAddress=https://$NODEIP:$USER_MGMT \
    --set images.appstoreFe.repository=$appstore_images_appstoreFe_repository \
    --set images.appstoreBe.repository=$appstore_images_appstoreBe_repository \
    --set images.postgres.repository=$appstore_images_postgres_repository \
    --set images.initservicecenter.repository=$appstore_images_initservicecenter_repository \
    --set images.appstoreFe.tag=$appstore_images_appstoreFe_tag \
    --set images.appstoreBe.tag=$appstore_images_appstoreBe_tag \
    --set images.postgres.tag=$appstore_images_postgres_tag \
    --set images.initservicecenter.tag=$appstore_images_initservicecenter_tag \
    --set images.appstoreFe.pullPolicy=$appstore_images_appstoreFe_pullPolicy \
    --set images.appstoreBe.pullPolicy=$appstore_images_appstoreBe_pullPolicy \
    --set images.postgres.pullPolicy=$appstore_images_postgres_pullPolicy \
    --set images.initservicecenter.pullPolicy=$appstore_images_initservicecenter_pullPolicy \
    --set global.ssl.enabled=$appstore_global_ssl_enabled \
    --set global.ssl.secretName=$appstore_global_ssl_secretName \
    --set global.persistence.enabled=$ENABLE_PERSISTENCE \
    --set poke.platformUrl=$appstore_poke_platformUrl \
    --set poke.atpReportUrl=$appstore_poke_atpReportUrl \
    --set appstoreBe.repository.dockerRepoEndpoint=$HARBOR_REPO_IP \
    --set appstoreBe.secretName=edgegallery-appstore-docker-secret
    if [ $? -eq 0 ]; then
      info "[Deployed AppStore  .........]" $GREEN
      resilient_utility "write" "APPSTORE:DEPLOYED"
    else
      info "[AppStore Deployment Failed  ]" $RED
      resilient_utility "write" "APPSTORE:FAILED"
      exit 1
    fi
  fi
}

function uninstall_appstore ()
{
  info "[UnDeploying AppStore  ......]" $BLUE
  helm uninstall appstore-edgegallery
  kubectl delete secret edgegallery-appstore-docker-secret
  resilient_utility "write" "APPSTORE:UN_DEPLOYED"
  info "[UnDeployed AppStore  .......]" $GREEN
}

function install_developer ()
{
  if resilient_utility "read" "DEVELOPER:FAILED";then
    uninstall_developer
  fi

  if resilient_utility "read" "DEVELOPER:UN_DEPLOYED";then
    info "[Deploying Developer  .......]"  $BLUE
    info "[it would take maximum of 5mins .......]" $BLUE
    helm install --wait developer-edgegallery "$CHART_PREFIX"edgegallery/developer"$CHART_SUFFIX" \
    --set global.oauth2.authServerAddress=https://$NODEIP:$USER_MGMT \
    --set images.developerFe.repository=$developer_images_developerFe_repository \
    --set images.developerBe.repository=$developer_images_developerBe_repository \
    --set images.postgres.repository=$developer_images_postgres_repository \
    --set images.initservicecenter.repository=$developer_images_initservicecenter_repository \
    --set images.toolChain.repository=$developer_images_toolChain_repository \
    --set images.portingAdvisor.repository=$developer_images_portingAdvisor_repository \
    --set images.developerFe.tag=$developer_images_developerFe_tag \
    --set images.developerBe.tag=$developer_images_developerBe_tag \
    --set images.toolChain.tag=$developer_images_toolChain_tag \
    --set images.postgres.tag=$developer_images_postgres_tag \
    --set images.initservicecenter.tag=$developer_images_initservicecenter_tag \
    --set images.portingAdvisor.tag=$developer_images_portingAdvisor_tag \
    --set images.developerFe.pullPolicy=$developer_images_developerFe_pullPolicy \
    --set images.developerBe.pullPolicy=$developer_images_developerBe_pullPolicy \
    --set images.postgres.pullPolicy=$developer_images_postgres_pullPolicy \
    --set images.initservicecenter.pullPolicy=$developer_images_initservicecenter_pullPolicy \
    --set images.toolChain.pullPolicy=$developer_images_toolChain_pullPolicy \
    --set images.portingAdvisor.pullPolicy=$developer_images_portingAdvisor_pullPolicy \
    --set global.ssl.enabled=$developer_global_ssl_enabled \
    --set global.ssl.secretName=$developer_global_ssl_secretName \
    --set global.persistence.enabled=$ENABLE_PERSISTENCE \
    --set developer.dockerRepo.endpoint=$HARBOR_REPO_IP \
    --set developer.dockerRepo.password=$HARBOR_PASSWORD \
    --set developer.dockerRepo.username=$HARBOR_USER
    if [ $? -eq 0 ]; then
      info "[Deployed Developer .........]" $GREEN
      resilient_utility "write" "DEVELOPER:DEPLOYED"
    else
      info "[Developer Deployment Failed ]" $RED
      resilient_utility "write" "DEVELOPER:FAILED"
      exit 1
    fi
  fi
}

function uninstall_developer ()
{
  info "[UnDeploying Developer  .....]" $BLUE
  helm uninstall developer-edgegallery
  resilient_utility "write" "DEVELOPER:UN_DEPLOYED"
  info "[UnDeployed Developer  ......]" $GREEN
}

function install_atp()
{
  if resilient_utility "read" "ATP:FAILED";then
    uninstall_atp
  fi

  if resilient_utility "read" "ATP:UN_DEPLOYED";then
    info "[Deploying ATP  ...........]"  $BLUE
    info "[it would take maximum of 5mins .......]" $BLUE
    helm install --wait atp-edgegallery "$CHART_PREFIX"edgegallery/atp"$CHART_SUFFIX" \
    --set global.oauth2.authServerAddress=https://$NODEIP:$USER_MGMT \
    --set images.atpFe.repository=$atp_images_atpFe_repository \
    --set images.atp.repository=$atp_images_atp_repository \
    --set images.postgres.repository=$atp_images_postgres_repository \
    --set images.initservicecenter.repository=$atp_images_initservicecenter_repository \
    --set images.atpFe.tag=$atp_images_atpFe_tag \
    --set images.atp.tag=$atp_images_atp_tag \
    --set images.postgres.tag=$atp_images_postgres_tag \
    --set images.initservicecenter.tag=$atp_images_initservicecenter_tag \
    --set images.atpFe.pullPolicy=$atp_images_atpFe_pullPolicy \
    --set images.atp.pullPolicy=$atp_images_atp_pullPolicy \
    --set images.postgres.pullPolicy=$atp_images_postgres_pullPolicy \
    --set images.initservicecenter.pullPolicy=$atp_images_initservicecenter_pullPolicy \
    --set global.ssl.enabled=$atp_global_ssl_enabled \
    --set global.ssl.secretName=$atp_global_ssl_secretName
    if [ $? -eq 0 ]; then
      info "[Deployed ATP ...........]" $GREEN
      resilient_utility "write" "ATP:DEPLOYED"
    else
      info "[ATP Deployment Failed ..]" $RED
      resilient_utility "write" "ATP:FAILED"
      exit 1
    fi
  fi
}

function uninstall_atp ()
{
  info "[UnDeploying ATP  ...........]" $BLUE
  helm uninstall atp-edgegallery
  resilient_utility "write" "ATP:UN_DEPLOYED"
  info "[UnDeployed ATP  ............]" $GREEN
}

function install_service-center ()
{
  if resilient_utility "read" "SERVICE_CENTER:FAILED";then
    uninstall_service-center
  fi

  if resilient_utility "read" "SERVICE_CENTER:UN_DEPLOYED";then
    info "[Deploying ServiceCenter  ...]" $BLUE
    info "[it would take maximum of 5mins .......]" $BLUE
    helm install --wait service-center-edgegallery "$CHART_PREFIX"edgegallery/servicecenter"$CHART_SUFFIX" \
    --set images.repository=$servicecenter_images_repository \
    --set images.tag=latest \
    --set images.pullPolicy=$servicecenter_images_pullPolicy \
    --set global.ssl.enabled=$servicecenter_global_ssl_enabled \
    --set global.ssl.secretName=$servicecenter_global_ssl_secretName
    if [ $? -eq 0 ]; then
      info "[Deployed ServiceCenter  ....]" $GREEN
      resilient_utility "write" "SERVICE_CENTER:DEPLOYED"
    else
      info "[ServiceCenter Deployment Failed]" $RED
      resilient_utility "write" "SERVICE_CENTER:FAILED"
      exit 1
    fi
  fi
}

function uninstall_service-center ()
{
  info "[UnDeploying ServiceCenter  .]" $BLUE
  helm uninstall service-center-edgegallery
  resilient_utility "write" "SERVICE_CENTER:UN_DEPLOYED"
  info "[UnDeployed ServiceCenter  ..]" $GREEN
}

function install_user-mgmt ()
{
  if resilient_utility "read" "USER_MGMT:FAILED";then
    uninstall_user-mgmt
  fi

  if resilient_utility "read" "USER_MGMT:UN_DEPLOYED";then
    info "[Deploying UserMgmt  ........]" $BLUE
    info "[it would take maximum of 5mins .......]" $BLUE
    ## Create a jwt secret for usermgmt
    kubectl create secret generic user-mgmt-jwt-secret \
      --from-file=publicKey=$PLATFORM_DIR/conf/keys/rsa_public_key.pem \
      --from-file=encryptedPrivateKey=$PLATFORM_DIR/conf/keys/encrypted_rsa_private_key.pem \
      --from-literal=encryptPassword=te9Fmv%qaq

    helm install --wait user-mgmt-edgegallery "$CHART_PREFIX"edgegallery/usermgmt"$CHART_SUFFIX" \
    --set global.oauth2.clients.appstore.clientUrl=https://$NODEIP:$APPSTORE_PORT,\
global.oauth2.clients.developer.clientUrl=https://$NODEIP:$DEVELOPER_PORT,\
global.oauth2.clients.mecm.clientUrl=https://$NODEIP:$MECM_PORT,\
global.oauth2.clients.atp.clientUrl=https://$NODEIP:$ATP_PORT,\
global.oauth2.clients.lab.clientUrl=https://$NODEIP:$LAB_PORT, \
    --set jwt.secretName=$usermgmt_jwt_secretName \
    --set images.usermgmt.repository=$usermgmt_images_usermgmt_repository \
    --set images.postgres.repository=$usermgmt_images_postgres_repository \
    --set images.redis.repository=$usermgmt_images_redis_repository \
    --set images.initservicecenter.repository=$usermgmt_images_initservicecenter_repository \
    --set images.usermgmt.tag=$usermgmt_images_usermgmt_tag \
    --set images.postgres.tag=$usermgmt_images_postgres_tag \
    --set images.redis.tag=$usermgmt_images_redis_tag \
    --set images.initservicecenter.tag=$usermgmt_images_initservicecenter_tag \
    --set images.usermgmt.pullPolicy=$usermgmt_images_usermgmt_pullPolicy \
    --set images.postgres.pullPolicy=$usermgmt_images_postgres_pullPolicy \
    --set images.redis.pullPolicy=$usermgmt_images_redis_pullPolicy \
    --set images.initservicecenter.pullPolicy=$usermgmt_images_initservicecenter_pullPolicy \
    --set global.ssl.enabled=$usermgmt_global_ssl_enabled \
    --set global.ssl.secretName=$usermgmt_global_ssl_secretName \
    --set global.persistence.enabled=$ENABLE_PERSISTENCE \
    --set mail.enabled=$usermgmt_mail_enabled \
    --set mail.host=$usermgmt_mail_host \
    --set mail.port=$usermgmt_mail_port \
    --set mail.sender=$usermgmt_mail_sender \
    --set mail.authCode=$usermgmt_mail_authcode

    if [ $? -eq 0 ]; then
      info "[Deployed UserMgmt  .........]" $GREEN
      resilient_utility "write" "USER_MGMT:DEPLOYED"
    else
      info "[UserMgmt Deployment Failed .]" $RED
      resilient_utility "write" "USER_MGMT:FAILED"
      exit 1
    fi
  fi
}

function uninstall_user-mgmt ()
{
  info "[UnDeploying UserMgmt  ......]" $BLUE
  helm uninstall user-mgmt-edgegallery
  kubectl delete secret user-mgmt-jwt-secret
  resilient_utility "write" "USER_MGMT:UN_DEPLOYED"
  info "[UnDeployed UserMgmt  .......]" $GREEN
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
  HELM_COMMAND+="helm install --wait ingress-edgegallery edgegallery/edgegallery "
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

function install_ingress()
{
  helm install --wait edgegallery-ingress "$CHART_PREFIX"edgegallery/edgegallery"$CHART_SUFFIX" \
  --set global.oauth2.authServerAddress=http://$AUTH_DOMAIN_NAME \
  --set global.oauth2.clients.appstore.clientUrl=http://$APPSTORE_DOMAIN_NAME \
  --set global.oauth2.clients.developer.clientUrl=http://$DEVELOPER_DOMAIN_NAME \
  --set global.oauth2.clients.mecm.clientUrl=http://$MECM_DOMAIN_NAME \
  --set usermgmt.jwt.secretName=user-mgmt-jwt-secret \
  --set global.ingress.enabled=true \
  --set global.ingress.hosts.auth=$AUTH_DOMAIN_NAME \
  --set global.ingress.hosts.appstore=$APPSTORE_DOMAIN_NAME \
  --set global.ingress.hosts.developer=$DEVELOPER_DOMAIN_NAME \
  --set global.ingress.hosts.mecm=$MECM_DOMAIN_NAME \
  --set usermgmt.images.usermgmt.repository="$REGISTRY_URL"edgegallery/user-mgmt \
  --set usermgmt.images.postgres.repository="$REGISTRY_URL"postgres \
  --set usermgmt.images.redis.repository="$REGISTRY_URL"redis \
  --set usermgmt.images.curl.repository="$REGISTRY_URL"curlimages/curl \
  --set mecm.images.mecmFe.repository="$REGISTRY_URL"edgegallery/mecm-fe \
  --set mecm.images.apiHandlerInfra.repository="$REGISTRY_URL"edgegallery/api-handler-infra \
  --set mecm.images.meoBpmnInfra.repository="$REGISTRY_URL"edgegallery/bpmn-infra \
  --set mecm.images.meoCatalogDbAdapter.repository="$REGISTRY_URL"edgegallery/catalog-db-adapter \
  --set mecm.images.mecmEsr.repository="$REGISTRY_URL"edgegallery/mecm-esr \
  --set mecm.images.meoRequestDbAdapter.repository="$REGISTRY_URL"edgegallery/request-db-adapter \
  --set mecm.images.mecmCatalog.repository="$REGISTRY_URL"edgegallery/mecm-catalog \
  --set mecm.images.mariadb.repository="$REGISTRY_URL"mariadb \
  --set mecm.images.curl.repository="$REGISTRY_URL"curlimages/curl \
  --set appstore.images.appstoreFe.repository="$REGISTRY_URL"edgegallery/appstore-fe \
  --set appstore.images.appstoreBe.repository="$REGISTRY_URL"edgegallery/appstore-be \
  --set appstore.images.postgres.repository="$REGISTRY_URL"postgres \
  --set appstore.images.curl.repository="$REGISTRY_URL"curlimages/curl \
  --set developer.images.developerFe.repository="$REGISTRY_URL"edgegallery/developer-fe \
  --set developer.images.developerBe.repository="$REGISTRY_URL"edgegallery/developer-be \
  --set developer.images.postgres.repository="$REGISTRY_URL"postgres \
  --set developer.images.curl.repository="$REGISTRY_URL"curlimages/curl
}

function uninstall_controller_with_ingress()
{
  helm uninstall ingress-edgegallery
}

function install_with_umbrella_chart()
{
  kubectl create secret generic user-mgmt-jwt-secret \
  --from-file=publicKey=$PLATFORM_DIR/conf/keys/rsa_public_key.pem \
  --from-file=encryptedPrivateKey=$PLATFORM_DIR/conf/keys/encrypted_rsa_private_key.pem \
  --from-literal=encryptPassword=te9Fmv%qaq

  helm install --wait offline-edgegallery "$CHART_PREFIX"edgegallery/edgegallery"$CHART_SUFFIX" \
--set global.oauth2.authServerAddress=http://$NODEIP:$USER_MGMT \
--set global.oauth2.clients.appstore.clientUrl=http://$NODEIP:$APPSTORE_PORT \
--set global.oauth2.clients.developer.clientUrl=http://$NODEIP:$DEVELOPER_PORT \
--set global.oauth2.clients.mecm.clientUrl=http://$NODEIP:$MECM_PORT \
--set usermgmt.jwt.secretName=user-mgmt-jwt-secret \
--set usermgmt.expose.nodePort=$USER_MGMT \
--set appstore.expose.appstoreFe.nodePort=$APPSTORE_PORT \
--set developer.expose.developerFe.nodePort=$DEVELOPER_PORT \
--set mecm.expose.mecmFe.nodePort=$MECM_PORT \
--set servicecenter.images.repository="$REGISTRY_URL"edgegallery/service-center \
--set servicecenter.images.pullPolicy=IfNotPresent \
--set usermgmt.images.usermgmt.repository="$REGISTRY_URL"edgegallery/user-mgmt \
--set usermgmt.images.postgres.repository="$REGISTRY_URL"postgres \
--set usermgmt.images.redis.repository="$REGISTRY_URL"redis \
--set usermgmt.images.curl.repository="$REGISTRY_URL"curlimages/curl \
--set usermgmt.images.usermgmt.pullPolicy=IfNotPresent \
--set usermgmt.images.postgres.pullPolicy=IfNotPresent \
--set usermgmt.images.redis.pullPolicy=IfNotPresent \
--set usermgmt.images.curl.pullPolicy=IfNotPresent \
--set mecm.images.mecmFe.repository="$REGISTRY_URL"edgegallery/mecm-fe \
--set mecm.images.apiHandlerInfra.repository="$REGISTRY_URL"edgegallery/api-handler-infra \
--set mecm.images.meoBpmnInfra.repository="$REGISTRY_URL"edgegallery/bpmn-infra \
--set mecm.images.meoCatalogDbAdapter.repository="$REGISTRY_URL"edgegallery/catalog-db-adapter \
--set mecm.images.mecmEsr.repository="$REGISTRY_URL"edgegallery/mecm-esr \
--set mecm.images.meoRequestDbAdapter.repository="$REGISTRY_URL"edgegallery/request-db-adapter \
--set mecm.images.mecmCatalog.repository="$REGISTRY_URL"edgegallery/mecm-catalog \
--set mecm.images.mariadb.repository="$REGISTRY_URL"mariadb \
--set mecm.images.curl.repository="$REGISTRY_URL"curlimages/curl \
--set mecm.images.mecmFe.pullPolicy=IfNotPresent \
--set mecm.images.apiHandlerInfra.pullPolicy=IfNotPresent \
--set mecm.images.meoBpmnInfra.pullPolicy=IfNotPresent \
--set mecm.images.meoCatalogDbAdapter.pullPolicy=IfNotPresent \
--set mecm.images.mecmEsr.pullPolicy=IfNotPresent \
--set mecm.images.meoRequestDbAdapter.pullPolicy=IfNotPresent \
--set mecm.images.mecmCatalog.pullPolicy=IfNotPresent \
--set mecm.images.mariadb.pullPolicy=IfNotPresent \
--set mecm.images.curl.pullPolicy=IfNotPresent \
--set appstore.images.appstoreFe.repository="$REGISTRY_URL"edgegallery/appstore-fe \
--set appstore.images.appstoreBe.repository="$REGISTRY_URL"edgegallery/appstore-be \
--set appstore.images.postgres.repository="$REGISTRY_URL"postgres \
--set appstore.images.curl.repository="$REGISTRY_URL"curlimages/curl \
--set appstore.images.appstoreFe.pullPolicy=IfNotPresent \
--set appstore.images.appstoreBe.pullPolicy=IfNotPresent \
--set appstore.images.postgres.pullPolicy=IfNotPresent \
--set appstore.images.curl.pullPolicy=IfNotPresent \
--set developer.images.developerFe.repository="$REGISTRY_URL"edgegallery/developer-fe \
--set developer.images.developerBe.repository="$REGISTRY_URL"edgegallery/developer-be \
--set developer.images.postgres.repository="$REGISTRY_URL"postgres \
--set developer.images.curl.repository="$REGISTRY_URL"curlimages/curl \
--set developer.images.developerFe.pullPolicy=IfNotPresent \
--set developer.images.developerBe.pullPolicy=IfNotPresent \
--set developer.images.postgres.pullPolicy=IfNotPresent \
--set developer.images.curl.pullPolicy=IfNotPresent
  if [ $? -eq 0 ]; then
    info "[Deployed Host components ...]" $GREEN
  else
    info "[Host components Deployment Failed]" $RED
    exit 1
  fi
}

function uninstall_umbrella_chart()
{
  info "[UnDeploying Host Components ]" $BLUE
  helm uninstall offline-edgegallery
  kubectl delete secret user-mgmt-jwt-secret
  info "[UnDeployed Host Components .]" $GREEN
}

function create_ssl_certs()
{
  if ! resilient_utility "read" ":DEPLOYED"; then
    if [[ -z $CERT_VALIDITY_IN_DAYS ]]; then
      env=""
    else
      env="-e CERT_VALIDITY_IN_DAYS=$CERT_VALIDITY_IN_DAYS"
    fi
    docker run $env -v $PLATFORM_DIR/conf/keys/:/certs edgegallery/deploy-tool:$EG_IMAGE_TAG
  fi
}

function install_nfs-client-provisioner()
{
  info "[Deploying nfs-client-provisioner]"
  if [ $KERNEL_ARCH == 'aarch64' ]; then
    set_image_value="--set image.repository=vbouchaud/nfs-client-provisioner --set image.tag=v3.1.1"
  else
    set_image_value=""
  fi

  helm install --wait  nfs-client-provisioner --set nfs.server=$NFS_SERVER_IP \
       --set nfs.path=$NFS_PATH  $set_image_value "$CHART_PREFIX"stable/nfs-client-provisioner"$NFS_CHART_SUFFIX"
  if [ $? -eq 0 ]; then
    info "[Deployed nfs-client-provisioner]" $GREEN
  else
    info "[nfs-client-provisioner Deployment Failed]" $RED
    exit 1
  fi
}

function uninstall_nfs-client-provisioner()
{
  info "[UnDeploying nfs-client-provisioner]"
  helm uninstall nfs-client-provisioner
  info "[UnDeployed nfs-client-provisioner]" $GREEN
}

function resilient_utility ()
{
  resilient_to_do=$1
  key=$2
  if [[ $resilient_to_do == "read" ]]; then
    value=$(cat $PLATFORM_DIR/conf/installer-footprint | grep "$key")
    value=$?
    if [[ $value -eq 0 ]]; then
      return 0
    else
      return 1
    fi
  elif [[ $resilient_to_do == "write" ]]; then
    module=$(echo "$key"| cut -d: -f1)
    sed -i "s?$module:.*?$key?g" $PLATFORM_DIR/conf/installer-footprint
  fi
}

function install_EdgeGallery ()
{
  FEATURE=$1
  NODEIP=$2
  if [ -z "$DEPLOY_TYPE" ]; then
    DEPLOY_TYPE="nodePort"
  fi

  if [[ $ENABLE_PERSISTENCE == "true" ]]; then
    if [[ -z $NFS_SERVER_IP || -z $NFS_PATH ]]; then
      info "[Both NFS_SERVER_IP and NFS_PATH values must be set for enabling persistence]" $RED
      exit 1
    fi
    install_nfs-client-provisioner
  fi

  if [[ $FEATURE == 'edge' || $FEATURE == 'all' ]]; then
    INSTALLER_INDEX="E.1:"
    install_mep
    INSTALLER_INDEX="E.2:"
    install_mecm-mepm
#    INSTALLER_INDEX="E.3:"
#    install_common-svc
    INSTALLER_INDEX=""
  fi
  if [[ ($FEATURE == 'controller' || $FEATURE == 'all') && ($DEPLOY_TYPE == 'nodePort') ]]; then
    if ! resilient_utility "read" "SERVICE_CENTER:DEPLOYED"; then
      kubectl create secret generic edgegallery-ssl-secret \
      --from-file=keystore.p12=$PLATFORM_DIR/conf/keys/keystore.p12 \
      --from-literal=keystorePassword=te9Fmv%qaq \
      --from-literal=keystoreType=PKCS12 \
      --from-literal=keyAlias=edgegallery \
      --from-file=trust.cer=$PLATFORM_DIR/conf/keys/ca.crt \
      --from-file=server.cer=$PLATFORM_DIR/conf/keys/tls.crt \
      --from-file=server_key.pem=$PLATFORM_DIR/conf/keys/encryptedtls.key \
      --from-literal=cert_pwd=te9Fmv%qaq
    fi
    INSTALLER_INDEX="C.1:"
    install_service-center
    INSTALLER_INDEX="C.2:"
    install_user-mgmt
    INSTALLER_INDEX="C.3:"
    install_mecm-meo
    INSTALLER_INDEX="C.4:"
    install_mecm-fe
    INSTALLER_INDEX="C.5:"
    install_appstore
    INSTALLER_INDEX="C.6:"
    install_developer
    INSTALLER_INDEX="C.7:"
    install_atp
    INSTALLER_INDEX=""
  elif [[ ($FEATURE == 'controller' || $FEATURE == 'all') && ($DEPLOY_TYPE == 'ingress') ]]; then
    install_controller_with_ingress
  fi
}

function uninstall_EdgeGallery ()
{
   FEATURE=$1
   if [ -z "$DEPLOY_TYPE" ]; then
     DEPLOY_TYPE="nodePort"
   fi
   if [[ $FEATURE == 'edge' || $FEATURE == 'all' ]]; then
     INSTALLER_INDEX="E.1:"
     uninstall_mep
     INSTALLER_INDEX="E.2:"
     uninstall_mecm-mepm
#     INSTALLER_INDEX="E.3:"
#     uninstall_common-svc
   fi
   if [[ ($FEATURE == 'controller' || $FEATURE == 'all') && ($DEPLOY_TYPE == 'nodePort') ]]; then
     INSTALLER_INDEX="C.1:"
     uninstall_mecm-fe
     INSTALLER_INDEX="C.2:"
     uninstall_mecm-meo
     INSTALLER_INDEX="C.3:"
     uninstall_appstore
     INSTALLER_INDEX="C.4:"
     uninstall_developer
     INSTALLER_INDEX="C.5:"
     uninstall_user-mgmt
     INSTALLER_INDEX="C.6:"
     uninstall_service-center
     INSTALLER_INDEX="C.7:"
     uninstall_atp
     INSTALLER_INDEX=""
     kubectl delete secret edgegallery-ssl-secret
   elif [[ ($FEATURE == 'controller' || $FEATURE == 'all') && ($DEPLOY_TYPE == 'ingress') ]]; then
     uninstall_controller_with_ingress
   fi
   uninstall_nfs-client-provisioner
}
#================================wrapper of k8s and eg===========================================
function _parse_arguments ()
{
 for ARGUMENT in "$@"
  do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)
    case "$KEY" in
            WHAT_TO_DO)      WHAT_TO_DO=${VALUE} ;;
            PRIVATE_REGISTRY_IP)      PRIVATE_REGISTRY_IP=${VALUE} ;;
            *)
    esac
  done
}

function _undeploy_k8s()
{
  if [[ $UNINSTALL_FEATURE == "all" ]]; then
    kubernetes_undeploy
  fi
  if [[ $OFFLINE_MODE == "muno" ]]; then
    #just taking the first master IP, multiple master IP's aren't supported yet
    MASTER_IP=$(echo $1|cut -d "," -f1)
    WORKER_LIST=`echo $2 | sed -e "s/,/ /g"`
    sshpass ssh root@$MASTER_IP "source /tmp/remote-platform/eg.sh; kubernetes_undeploy;
    rm -rf /tmp/remote-platform; rm -rf /tmp/remote-platform/k8s;rm /usr/local/bin/helm"
    for node_ip in $WORKER_LIST;
    do
      sshpass ssh root@$node_ip "source /tmp/remote-platform/eg.sh; kubernetes_undeploy;
      rm -rf /tmp/remote-platform; rm -rf /tmp/remote-platform/k8s;rm /usr/local/bin/helm"
    done
  fi
}

function _deploy_k8s()
{
  if resilient_utility "read" ":DEPLOYED"; then
    return 0
  fi

  #just taking the first master IP, multiple master IP's aren't supported yet
  MASTER_IP=$(echo $1|cut -d "," -f1)
  export K8S_MASTER_IP=$MASTER_IP; export K8S_NODE_TYPE=MASTER;
  tar -xf $TARBALL_PATH/kubernetes_offline_installer.tar.gz -C $K8S_OFFLINE_DIR;
  if [[ $OFFLINE_MODE == "aio" ]]; then
    kubernetes_deploy
    sleep 3
  else
    WORKER_LIST=`echo $2 | sed -e "s/,/ /g"`

    _docker_deploy
    for node_ip in $MASTER_IP;
    do
      scp $TARBALL_PATH/kubernetes_offline_installer.tar.gz root@$node_ip:/tmp/remote-platform
      scp $TARBALL_PATH/eg.sh root@$node_ip:/tmp/remote-platform
      sshpass ssh root@$node_ip \
      "tar -xf /tmp/remote-platform/kubernetes_offline_installer.tar.gz -C /tmp/remote-platform;" < /dev/null
    done

    sshpass ssh root@$MASTER_IP "export K8S_OFFLINE_DIR=$K8S_OFFLINE_DIR; export K8S_MASTER_IP=$node_ip;
    export K8S_NODE_TYPE=MASTER; source /tmp/remote-platform/eg.sh; kubernetes_deploy;" < /dev/null

    scp root@$MASTER_IP:$K8S_OFFLINE_DIR/k8s-worker.sh $K8S_OFFLINE_DIR

    for node_ip in $WORKER_LIST;
    do
      scp $TARBALL_PATH/kubernetes_offline_installer.tar.gz root@$node_ip:/tmp/remote-platform
      scp $TARBALL_PATH/eg.sh root@$node_ip:/tmp/remote-platform
      scp $K8S_OFFLINE_DIR/k8s-worker.sh root@$node_ip:/tmp/remote-platform;
      sshpass ssh root@$node_ip "
      tar -xf /tmp/remote-platform/kubernetes_offline_installer.tar.gz -C /tmp/remote-platform;" < /dev/null

      sshpass ssh root@$node_ip "export K8S_OFFLINE_DIR=$K8S_OFFLINE_DIR; export K8S_MASTER_IP=$MASTER_IP;
      export K8S_NODE_TYPE=WORKER; source /tmp/remote-platform/eg.sh; kubernetes_deploy; bash /tmp/remote-platform/k8s-worker.sh"
    done
  fi
}

function make_remote_dir() {
    MASTER_IP=$(echo $1|cut -d "," -f1)
    WORKER_LIST=`echo $2 | sed -e "s/,/ /g"`
    sshpass ssh root@$MASTER_IP "mkdir -p /tmp/remote-platform/helm"
    for node_ip in $WORKER_LIST;
    do
      sshpass ssh root@$node_ip "mkdir -p /tmp/remote-platform/helm"
    done
}

function setup_passwordless_ssh(){
  PASSWORD=$2
  NODELIST=`echo $1 | sed -e "s/,/ /g"`
  rm /root/.ssh/config
  ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y 2>&1 >/dev/null
  for node_ip in $NODELIST;
  do
    sshpass -p $PASSWORD ssh-copy-id -o StrictHostKeyChecking=no root@$node_ip
  done
}

function setup_passwordless_ssh_advanced(){
  ROOT_PASSWORD=$2
  NODELIST=`echo $1 | sed -e "s/,/ /g"`

  for node_ip in $NODELIST;
  do
    sshpass ssh -o PubkeyAuthentication=yes  -o PasswordAuthentication=no $node_ip "exit 0" >/dev/null
    if [[ $? != 0 ]]; then
      flags="-o StrictHostKeyChecking=no"
    else
      flags=""
    fi
    sshpass -p $ROOT_PASSWORD ssh $flags root@$node_ip "rm /tmp/remote-platform;"
    sshpass -p $ROOT_PASSWORD ssh $flags root@$node_ip "mkdir -p /tmp/remote-platform"
    sshpass -p $ROOT_PASSWORD scp $flags $TARBALL_PATH/eg.sh root@$node_ip:/tmp/remote-platform/
    sshpass -p $ROOT_PASSWORD scp $flags $TARBALL_PATH/sshpass_1.06-1_$arch.deb root@$node_ip:/tmp/remote-platform/
    sshpass -p $ROOT_PASSWORD ssh $flags root@$node_ip "cd /tmp/remote-platform; source eg.sh; setup_passwordless_ssh $1 $ROOT_PASSWORD"
  done
}

function password_less_ssh_check() {
  if [[ $OFFLINE_MODE == "muno" ]]; then
    MASTER_IP=$(echo $1 |cut -d "," -f1)
    WORKER_LIST=`echo $2 | sed -e "s/,/ /g"`
    for node_ip in $MASTER_IP;
    do
      sshpass ssh -o PubkeyAuthentication=yes  -o PasswordAuthentication=no $node_ip "exit 0" >/dev/null
      if [[ $? != 0 ]]; then
        info "Error: PasswordLess SSH is not setup among hosts" $RED
        info "Set PasswordLess SSH by running: bash eg.sh -p master-ip,worker-ip1,..worker-ipn ROOT_PASSWORD" $RED
        exit 1
      fi
    done
    for node_ip in $WORKER_LIST;
    do
      sshpass ssh -o PubkeyAuthentication=yes  -o PasswordAuthentication=no $node_ip "exit 0" >/dev/null
      if [[ $? != 0 ]]; then
        info "Error: PasswordLess SSH is not setup among hosts" $RED
        info "Set PasswordLess SSH by running: bash eg.sh -p master-ip,worker-ip1,..worker-ipn ROOT_PASSWORD" $RED
        exit 1
      fi
    done
  fi
}

function _deploy_eg()
{
  password_less_ssh_check $EG_NODE_MASTER_IPS $EG_NODE_WORKER_IPS
  WORKER_IPS=`echo $EG_NODE_WORKER_IPS | sed -e "s/,/ /g"`
  MASTER_IP=$(echo $EG_NODE_MASTER_IPS|cut -d "," -f1)
  setup_eg_ecosystem
  if [[ $OFFLINE_MODE == "muno" ]]; then
    make_remote_dir $MASTER_IP $EG_NODE_WORKER_IPS
  fi
  if [[ $SKIP_K8S != "true" ]]; then
     _deploy_k8s $EG_NODE_MASTER_IPS $EG_NODE_WORKER_IPS
  fi
  if [[ $OFFLINE_MODE == "muno" ]]; then
    mkdir -p $HOME/.kube
    scp root@$MASTER_IP:/root/.kube/config $HOME/.kube/
  fi
  number_of_nodes=$(kubectl get nodes |wc -l)
  if [[ $number_of_nodes -ge 3 ]]; then
    ((number_of_nodes=number_of_nodes-1))
  else
    number_of_nodes=1
  fi
  wait "calico-node" $number_of_nodes
  wait "kube-proxy" $number_of_nodes
  wait_for_ready_state "calico-node" $number_of_nodes
  configure_eg_ecosystem_on_remote $MASTER_IP $EG_NODE_WORKER_IPS
  if ! resilient_utility "read" ":DEPLOYED"; then
    kubectl apply -f $K8S_OFFLINE_DIR/k8s/metric-server.yaml
  fi
  create_ssl_certs
  for node_ip in $WORKER_IPS;
  do
    sshpass ssh root@$node_ip "rm -rf /mnt/grafana; mkdir -p /mnt/grafana"
    scp $PLATFORM_DIR/conf/keys/tls.key root@$node_ip:/mnt/grafana/
    scp $PLATFORM_DIR/conf/keys/tls.crt root@$node_ip:/mnt/grafana/

    sshpass ssh root@$node_ip "mkdir -p /opt/cni/bin"
    scp $K8S_OFFLINE_DIR/cni/macvlan root@$node_ip:/opt/cni/bin/
    scp $K8S_OFFLINE_DIR/cni/host-local root@$node_ip:/opt/cni/bin/
  done
  _eg_deploy all $EG_NODE_DEPLOY_IP $MASTER_IP
}

function _deploy_controller()
{
  password_less_ssh_check $EG_NODE_CONTROLLER_MASTER_IPS $EG_NODE_CONTROLLER_WORKER_IPS
  WORKER_IPS=`echo $EG_NODE_CONTROLLER_WORKER_IPS | sed -e "s/,/ /g"`
  MASTER_IP=$(echo $EG_NODE_CONTROLLER_MASTER_IPS|cut -d "," -f1)
  setup_eg_ecosystem
  if [[ $OFFLINE_MODE == "muno" ]]; then
    make_remote_dir $MASTER_IP $EG_NODE_CONTROLLER_WORKER_IPS
  fi
  if [[ $SKIP_K8S != "true" ]]; then
     _deploy_k8s $EG_NODE_CONTROLLER_MASTER_IPS $EG_NODE_CONTROLLER_WORKER_IPS
  fi
  if [[ $OFFLINE_MODE == "muno" ]]; then
    mkdir -p $HOME/.kube
    scp root@$MASTER_IP:/root/.kube/config $HOME/.kube/
  fi
  number_of_nodes=$(kubectl get nodes |wc -l)
  if [[ $number_of_nodes -ge 3 ]]; then
    ((number_of_nodes=number_of_nodes-1))
  else
    number_of_nodes=1
  fi
  wait "calico-node" $number_of_nodes
  wait "kube-proxy" $number_of_nodes
  wait_for_ready_state "calico-node" $number_of_nodes
  configure_eg_ecosystem_on_remote $MASTER_IP $EG_NODE_CONTROLLER_WORKER_IPS
  if ! resilient_utility "read" ":DEPLOYED"; then
    kubectl apply -f $K8S_OFFLINE_DIR/k8s/metric-server.yaml
  fi
  create_ssl_certs
  for node_ip in $WORKER_IPS;
  do
    sshpass ssh root@$node_ip "mkdir -p /opt/cni/bin"
    scp $K8S_OFFLINE_DIR/cni/macvlan root@$node_ip:/opt/cni/bin/
    scp $K8S_OFFLINE_DIR/cni/host-local root@$node_ip:/opt/cni/bin/
  done
  _eg_deploy controller $EG_NODE_DEPLOY_IP $MASTER_IP
}

function _deploy_edge()
{
  password_less_ssh_check $EG_NODE_EDGE_MASTER_IPS $EG_NODE_EDGE_WORKER_IPS
  WORKER_IPS=`echo $EG_NODE_EDGE_WORKER_IPS | sed -e "s/,/ /g"`
  MASTER_IP=$(echo $EG_NODE_EDGE_MASTER_IPS|cut -d "," -f1)
  setup_eg_ecosystem
  if [[ $OFFLINE_MODE == "muno" ]]; then
    make_remote_dir $MASTER_IP $EG_NODE_EDGE_WORKER_IPS
  fi
  if [[ $SKIP_K8S != "true" ]]; then
     _deploy_k8s $EG_NODE_EDGE_MASTER_IPS $EG_NODE_EDGE_WORKER_IPS
  fi
  if [[ $OFFLINE_MODE == "muno" ]]; then
    mkdir -p $HOME/.kube
    scp root@$MASTER_IP:/root/.kube/config $HOME/.kube/
  fi
  number_of_nodes=$(kubectl get nodes |wc -l)
  if [[ $number_of_nodes -ge 3 ]]; then
    ((number_of_nodes=number_of_nodes-1))
  else
    number_of_nodes=1
  fi
  wait "calico-node" $number_of_nodes
  wait "kube-proxy" $number_of_nodes
  wait_for_ready_state "calico-node" $number_of_nodes
  configure_eg_ecosystem_on_remote  $MASTER_IP $EG_NODE_EDGE_WORKER_IPS
  if ! resilient_utility "read" ":DEPLOYED"; then
    kubectl apply -f $K8S_OFFLINE_DIR/k8s/metric-server.yaml
  fi
  create_ssl_certs
  for node_ip in $WORKER_IPS;
  do
    sshpass ssh root@$node_ip "mkdir -p /opt/cni/bin"
    scp $K8S_OFFLINE_DIR/cni/macvlan root@$node_ip:/opt/cni/bin/
    scp $K8S_OFFLINE_DIR/cni/host-local root@$node_ip:/opt/cni/bin/
  done
  _eg_deploy edge $EG_NODE_DEPLOY_IP $MASTER_IP
}

function _deploy_dns_metallb() {
   info "[Deploying DNS METALLB  ..............]" $YELLOW
  
   if [ -z "$EG_NODE_DNS_LBS_IPS" ]; then
    if [ "$EG_NODE_EDGE_MASTER_IPS" ]; then
      EG_NODE_DNS_LBS_IPS=$EG_NODE_EDGE_MASTER_IPS
    else
      EG_NODE_DNS_LBS_IPS=$EG_NODE_MASTER_IPS
    fi
   fi

   kubectl apply -f $PLATFORM_DIR/conf/edge/metallb/namespace.yaml

   sed -i 's?image: metallb/controller:v0.9.3?image: '$REGISTRY_URL'metallb/controller:v0.9.3?g' $PLATFORM_DIR/conf/edge/metallb/metallb.yaml
   sed -i 's?image: metallb/speaker:v0.9.3?image: '$REGISTRY_URL'metallb/speaker:v0.9.3?g' $PLATFORM_DIR/conf/edge/metallb/metallb.yaml
   kubectl apply -f $PLATFORM_DIR/conf/edge/metallb/metallb.yaml
   kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
   sed -i "s/192.168.100.120/${EG_NODE_DNS_LBS_IPS}/g" $PLATFORM_DIR/conf/edge/metallb/config-map.yaml
   kubectl apply -f $PLATFORM_DIR/conf/edge/metallb/config-map.yaml

   sleep 3
   wait " controller-" 1 yes
   cont_return=$?
   wait "speaker-" $number_of_nodes yes
   speaker_return=$?
   if [[ $cont_return -eq 1 || $speaker_return -eq 1 ]]; then
     resilient_utility "write" "MEP:FAILED"
     exit 1
   fi
   info "[Deployed DNS METALLB  ..............]" $GREEN
}

function _undeploy_dns_metallb() {
  info "Undeploying DNS METALLB  ..............]" $YELLOW
  kubectl delete -f $PLATFORM_DIR/conf/edge/metallb/config-map.yaml
  kubectl delete -f $PLATFORM_DIR/conf/edge/metallb/metallb.yaml
  #kubectl delete -f $PLATFORM_DIR/conf/edge/metallb/namespace.yaml
  kubectl delete secret memberlist -n metallb-system
  info "[Undeployed DNS METALLB  ..............]" $GREEN
}

function _setup_interfaces() {
  KERNEL_ARCH=$(uname -m)
  if [[ -z $EG_NODE_EDGE_MP1 ]]; then
    EG_NODE_EDGE_MP1=$(ip a | grep -B2 $PRIVATE_IP | head -n1 | cut -d ":" -f2 |cut -d " " -f2)
  fi

  if [[ -z $EG_NODE_EDGE_MM5 ]]; then
      EG_NODE_EDGE_MM5=$(ip a | grep -B2 $PRIVATE_IP | head -n1 | cut -d ":" -f2 |cut -d " " -f2)
  fi
  ip_prefix=$1
  if [[ $1 -gt 24 ]]; then
      info "[Can't support more that 24 node....]" $GREEN
      exit 1
  fi
  if [[ $OFFLINE_MODE == 'muno' ]] ; then
      ip link add vxlan-mp1 type vxlan id 100 group 239.1.1.1 dstport 4789 dev $EG_NODE_EDGE_MP1
      ip link set vxlan-mp1 up

      ip link add vxlan-mm5 type vxlan id 200 group 239.1.1.1 dstport 4789 dev $EG_NODE_EDGE_MM5
      ip link set vxlan-mm5 up

      #These ip's range is betwen x.1.1.2~x.1.1.24 . Rest reserved for allocation to pods.
      ip link add eg-mp1 link vxlan-mp1 type macvlan mode bridge
      ip addr add 200.1.1.$ip_prefix/24 dev eg-mp1
      ip link set dev eg-mp1 up

      ip link add eg-mm5 link vxlan-mm5 type macvlan mode bridge
      ip addr add 100.1.1.$ip_prefix/24 dev eg-mm5
      ip link set dev eg-mm5 up
   else
      ip link add eg-mp1 link $EG_NODE_EDGE_MP1 type macvlan mode bridge
      ip addr add 200.1.1.$ip_prefix/24 dev eg-mp1
      ip link set dev eg-mp1 up

      ip link add eg-mm5 link $EG_NODE_EDGE_MM5 type macvlan mode bridge
      ip addr add 100.1.1.$ip_prefix/24 dev eg-mm5
      ip link set dev eg-mm5 up
   fi
}

function _deploy_network_isolation_multus() {
  info "[Deploying multus cni  ..............]" $YELLOW

  sed -i 's?image: docker.io/nfvpe/multus:stable?image: '$REGISTRY_URL'docker.io/nfvpe/multus:stable?g' $PLATFORM_DIR/conf/edge/network-isolation/multus.yaml
  sed -i 's?image: docker.io/nfvpe/multus:stable-arm64v8?image: '$REGISTRY_URL'docker.io/nfvpe/multus:stable-arm64v8?g' $PLATFORM_DIR/conf/edge/network-isolation/multus.yaml

  kubectl apply -f $PLATFORM_DIR/conf/edge/network-isolation/multus.yaml
  kubectl apply -f $PLATFORM_DIR/conf/edge/network-isolation/eg-sp-rbac.yaml
  sed -i 's?image: edgegallery/edgegallery-secondary-ep-controller:latest?image: '$REGISTRY_URL'edgegallery/edgegallery-secondary-ep-controller:'$EG_IMAGE_TAG'?g' $PLATFORM_DIR/conf/edge/network-isolation/eg-sp-controller.yaml
  kubectl apply -f $PLATFORM_DIR/conf/edge/network-isolation/eg-sp-controller.yaml

  if [[ $OFFLINE_MODE == 'muno' ]] ; then
    sed -i 's?image: docker.io/dougbtv/whereabouts:latest?image: '$REGISTRY_URL'docker.io/dougbtv/whereabouts:latest?g' $PLATFORM_DIR/conf/edge/network-isolation/whereabouts-daemonset-install.yaml
    sed -i 's?image: edgegallery/whereabouts-arm64:latest?image: '$REGISTRY_URL'edgegallery/whereabouts-arm64:latest?g' $PLATFORM_DIR/conf/edge/network-isolation/whereabouts-daemonset-install.yaml

    kubectl apply -f $PLATFORM_DIR/conf/edge/network-isolation/whereabouts-daemonset-install.yaml
    kubectl apply -f $PLATFORM_DIR/conf/edge/network-isolation/whereabouts.cni.cncf.io_ippools.yaml
    wait "whereabouts" $number_of_nodes yes
    if [[ $? -eq 1 ]]; then
      resilient_utility "write" "MEP:FAILED"
      exit 1
    fi
  fi

  ip_prefix_count=2
  if [[ $OFFLINE_MODE == "muno" ]]; then
    for node_ip in $MASTER_IP;
    do
      sshpass ssh root@$node_ip "mkdir -p /tmp/remote-platform"
      scp $TARBALL_PATH/eg.sh root@$node_ip:/tmp/remote-platform
      sshpass ssh root@$node_ip "cd /tmp/remote-platform;source eg.sh;export PRIVATE_IP=$node_ip;
      export EG_NODE_EDGE_MP1=$EG_NODE_EDGE_MP1;export EG_NODE_EDGE_MM5=$EG_NODE_EDGE_MM5;export OFFLINE_MODE=$OFFLINE_MODE;_setup_interfaces $ip_prefix_count"
      ip_prefix_count=$(( ip_prefix_count + 1 ))
    done
    for node_ip in $WORKER_IPS;
    do
      sshpass ssh root@$node_ip "mkdir -p /tmp/remote-platform"
      scp $TARBALL_PATH/eg.sh root@$node_ip:/tmp/remote-platform
      sshpass ssh root@$node_ip "cd /tmp/remote-platform;source eg.sh;export PRIVATE_IP=$node_ip;
      export EG_NODE_EDGE_MP1=$EG_NODE_EDGE_MP1;export EG_NODE_EDGE_MM5=$EG_NODE_EDGE_MM5;export OFFLINE_MODE=$OFFLINE_MODE;_setup_interfaces $ip_prefix_count"
      ip_prefix_count=$(( ip_prefix_count + 1 ))
    done
  else
    PRIVATE_IP=$DEPLOY_NODE_IP
    _setup_interfaces $ip_prefix_count
  fi

  wait "kube-multus" $number_of_nodes yes
  if [[ $? -eq 1 ]]; then
    resilient_utility "write" "MEP:FAILED"
    exit 1
  fi
  info "[Deployed multus cni  ..............]" $GREEN
}

function _cleanup_network_setup(){
  KERNEL_ARCH=$(uname -m)
  rm /opt/cni/bin/macvlan /opt/cni/bin/host-local
  ip link set dev eg-mp1 down
  ip link delete eg-mp1

  ip link set dev eg-mm5 down
  ip link delete eg-mm5
  rm /opt/cni/bin/multus
  if [[ $OFFLINE_MODE == 'muno' ]]; then
      ip link delete vxlan-mp1
      ip link delete vxlan-mm5
  fi
}

function _undeploy_network_isolation_multus() {
  info "[Undeploying multus cni  ..............]" $YELLOW
  kubectl delete -f $PLATFORM_DIR/conf/edge/network-isolation/eg-sp-controller.yaml
  kubectl delete -f $PLATFORM_DIR/conf/edge/network-isolation/eg-sp-rbac.yaml
  kubectl delete -f $PLATFORM_DIR/conf/edge/network-isolation/multus.yaml

  if [[ $OFFLINE_MODE == 'muno' ]] ; then
    kubectl delete -f $PLATFORM_DIR/conf/edge/network-isolation/whereabouts-daemonset-install.yaml
    kubectl delete -f $PLATFORM_DIR/conf/edge/network-isolation/whereabouts.cni.cncf.io_ippools.yaml
  fi

  if [[ $OFFLINE_MODE == "muno" ]]; then
    for node_ip in $MASTER_IP;
    do
      sshpass ssh root@$node_ip "cd /tmp/remote-platform;source eg.sh ;export OFFLINE_MODE=$OFFLINE_MODE; _cleanup_network_setup"
    done
    for node_ip in $WORKER_IPS;
    do
      sshpass ssh root@$node_ip "cd /tmp/remote-platform;source eg.sh ;export OFFLINE_MODE=$OFFLINE_MODE; _cleanup_network_setup"
    done
  else
    _cleanup_network_setup
  fi
  info "[Udeployed multus cni  ..............]" $GREEN
}

function _print__help()
{
  info "NAME" $GREEN
  info "    eg.sh  -  deploy EdgeGallery offline" $GREEN
  info "SYNTAX" $GREEN
  info "    bash eg.sh [option]" $GREEN
  info "OPTIONS" $GREEN
  info "    -h, --help" $GREEN
  info "        display help" $GREEN
  info "    -i, --install" $GREEN
  info "        install edgegallery" $GREEN
  info "    -u, --uninstall" $GREEN
  info "        uninstall edgegallery" $GREEN
  info "    -p, --prepare" $GREEN
  info "        setup passwordLess SSH among hosts" $GREEN
  info "        example: bash eg.sh -p host1-ip,host2-ip ROOT_PASSWORD" $GREEN
}

function print_env()
{
  info "Basic Settings" "$YELLOW"
  info "WHAT_TO_DO=$WHAT_TO_DO" "$GREEN"
  info "OFFLINE_MODE=$OFFLINE_MODE" "$GREEN"
  info "EG_IMAGE_TAG=$EG_IMAGE_TAG" "$GREEN"

  info "Topology Settings" "$YELLOW"
  info "EG_NODE_DEPLOY_IP=$EG_NODE_DEPLOY_IP" "$GREEN"
  info "EG_NODE_MASTER_IPS=$EG_NODE_MASTER_IPS" "$GREEN"
  info "EG_NODE_WORKER_IPS=$EG_NODE_WORKER_IPS" "$GREEN"
  info "EG_NODE_CONTROLLER_MASTER_IPS=$EG_NODE_CONTROLLER_MASTER_IPS" "$GREEN"
  info "EG_NODE_CONTROLLER_WORKER_IPS=$EG_NODE_CONTROLLER_WORKER_IPS" "$GREEN"
  info "EG_NODE_EDGE_MASTER_IPS=$EG_NODE_EDGE_MASTER_IPS" "$GREEN"
  info "EG_NODE_EDGE_WORKER_IPS=$EG_NODE_EDGE_WORKER_IPS" "$GREEN"

  info "Advanced Settings" "$YELLOW"
  info "EG_NODE_EDGE_MP1=$EG_NODE_EDGE_MP1" "$GREEN"
  info "EG_NODE_EDGE_MM5=$EG_NODE_EDGE_MM5" "$GREEN"
  info "SKIP_K8S=$SKIP_K8S" "$GREEN"
}

function main()
{
  if [[ ($1 == "--help" || $1 == "-h")  || ("$1" != "--install"  &&  "$1" != "-i" && "$1" != "--uninstall" && "$1" != "-u" && "$1" != "--prepare" && "$1" != "-p") ]]; then
    _print__help
    exit 1
  fi

  if [[ $1 == "-p" || $1 == "--prepare" ]]; then
    if [[ -z $2 || -z $3 ]];then
      info "--prepare/-p expects 2 arguments 1.Nodelist and 2.RootPassword" $RED
      exit 1
    fi
    _install_sshpass
    setup_passwordless_ssh $2 $3
    exit 0
  fi
  if [[ $OFFLINE_MODE == "aio" ]]; then
    if [[ -n $EG_NODE_DEPLOY_IP || -n $K8S_NODE_WORKER_IPS || -n $EG_NODE_WORKER_IPS \
    || -n $EG_NODE_CONTROLLER_WORKER_IPS || -n $EG_NODE_EDGE_WORKER_IPS ]]; then
      info "Unset WORKER_IPS and DEPLOY_IP for aio mode" $RED
      exit 1
    fi
  elif [[ $OFFLINE_MODE == "muno" ]]; then
    if [[ -z $EG_NODE_DEPLOY_IP ]]; then
      info "EG_NODE_DEPLOY_IP is not set" $RED
      exit 1
    fi
    if [[ -n  $EG_NODE_DEPLOY_IP ]]; then
      if [[ $EG_NODE_DEPLOY_IP == $K8S_NODE_WORKER_IPS ]] || [[ $EG_NODE_DEPLOY_IP == $EG_NODE_WORKER_IPS ]] ||
       [[ $EG_NODE_DEPLOY_IP ==  $EG_NODE_CONTROLLER_WORKER_IPS ]] || [[ $EG_NODE_DEPLOY_IP ==  $EG_NODE_EDGE_WORKER_IPS ]]; then
         info "EG_NODE_DEPLOY_IP and Worker node are same" $RED
      fi
      hostname -I | grep $EG_NODE_DEPLOY_IP >/dev/null
      private_ip_list=$?
      curl ip.sb -s -m 2| grep $EG_NODE_DEPLOY_IP >/dev/null
      public_ip=$?
      if [[ $public_ip != 0 && $private_ip_list != 0 ]]; then
        info "Have to Run eg.sh on Deploy Node" $RED
        exit 1
      fi
    fi
    _install_sshpass
  elif [[ $OFFLINE_MODE != "muno" ]]; then
    info "Unknown OFFLINE_MODE" $RED
    info "OFFLINE_MODE: aio, muno" $RED
    exit 1
  fi

  if [[ $1  == "uninstall" || $1 == "-u" ]]; then
    #default setting:
    SKIP_ECO_SYSTEM_UN_INSTALLATION="true"
    SKIP_K8S_UN_INSTALLATION="true"
    UNINSTALL_FEATURE=$2
    if [[ $UNINSTALL_FEATURE == "all" ]]; then
      SKIP_ECO_SYSTEM_UN_INSTALLATION="false"
      SKIP_K8S_UN_INSTALLATION="false"
    elif [[ $UNINSTALL_FEATURE == "k8s" ]]; then
      if [[ $OFFLINE_MODE == "aio" ]]; then
        info "Wrong Configuration ....." $RED
        info "Suggestion: UnInstallation of k8s in aio mode is InValid....." $RED
        exit 1
      fi
      SKIP_K8S_UN_INSTALLATION="false"
    elif [[ $UNINSTALL_FEATURE == "controller" ]]; then
      if [[ $EG_NODE_CONTROLLER_MASTER_IPS && $EG_NODE_MASTER_IPS ]]; then
        info "Wrong Configuration ....." $RED
        info "Suggestion: Set either EG_NODE_CONTROLLER_MASTER_IPS or EG_NODE_MASTER_IPS ....." $RED
        exit 1
      fi
    elif [[ $UNINSTALL_FEATURE == "edge" ]]; then
      if [[ $EG_NODE_EDGE_MASTER_IPS && $EG_NODE_MASTER_IPS ]]; then
        info "Wrong Configuration ....." $RED
        info "Suggestion: Set either EG_NODE_EDGE_MASTER_IPS or EG_NODE_MASTER_IPS ....." $RED
        exit 1
      fi
    fi
  fi

  eg_undeploy_feature="all"
  controller_undeploy_feature="controller"
  edge_undeploy_feature="edge"
  if [[ $UNINSTALL_FEATURE == "controller" || $UNINSTALL_FEATURE == "edge" ]]; then
    eg_undeploy_feature=$UNINSTALL_FEATURE
    controller_undeploy_feature=$UNINSTALL_FEATURE
    edge_undeploy_feature=$UNINSTALL_FEATURE
  fi

  if [[ $OFFLINE_MODE == "aio" ]]; then
    CHART_PREFIX="$TARBALL_PATH/helm/helm-charts/"
    CHART_SUFFIX="-1.0.0.tgz"
    PROM_CHART_SUFFIX="-9.3.1.tgz"
    GRAFANA_CHART_SUFFIX="-5.5.5.tgz"
    NFS_CHART_SUFFIX="-1.2.8.tgz"
    REGISTRY_URL=""
  else
    CHART_PREFIX=""
    CHART_SUFFIX=""
    PRIVATE_REGISTRY_IP=$(echo $EG_NODE_DEPLOY_IP|cut -d "," -f1)
    REGISTRY_URL="$PRIVATE_REGISTRY_IP:5000/"
  fi

  mkdir -p $PWD/logs/
  TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
  log_file="$PWD/logs/"$TIMESTAMP"_eg$1.log"
  exec 1> >(tee -a "$log_file")  2>&1

  if ping -q -c 1 -W 1 8.8.8.8 > /dev/null; then
    internet_available=true
  else
    internet_available=false
  fi
  WHAT_TO_DO=$1
  print_env
  #Input validation
  if [[ -n  $K8S_NODE_MASTER_IPS ]]; then
    if [[ -n $EG_NODE_MASTER_IPS || -n $EG_NODE_WORKER_IPS || -n $EG_NODE_CONTROLLER_MASTER_IPS
    || -n $EG_NODE_CONTROLLER_WORKER_IPS || -n $EG_NODE_EDGE_MASTER_IPS || -n $EG_NODE_EDGE_WORKER_IPS ]]; then
      info "Wrong Configuration ....." $RED
      info "Suggestion: Unset not required configuration in env ....." $RED
      exit 1
    elif [[ $SKIP_K8S == "true" ]]; then
      info "Wrong Configuration ....." $RED
      info "Suggestion: Unset not required configuration in env ....." $RED
      exit 1
    fi
    if [ "$WHAT_TO_DO" == "-u" ] || [ "$WHAT_TO_DO" == "--uninstall" ]; then
      if [[ $SKIP_K8S_UN_INSTALLATION != "true" ]]; then
        _undeploy_k8s $K8S_NODE_MASTER_IPS $K8S_NODE_WORKER_IPS
      fi
    elif [ "$WHAT_TO_DO" == "-i" ] || [ "$WHAT_TO_DO" == "--install" ]; then
      if [[ $OFFLINE_MODE == "muno" ]]; then
        MASTER_IP=$(echo $K8S_NODE_MASTER_IPS|cut -d "," -f1)
        make_remote_dir $MASTER_IP $K8S_NODE_WORKER_IPS
      fi
      _deploy_k8s $K8S_NODE_MASTER_IPS $K8S_NODE_WORKER_IPS
    fi
  elif [[ -n  $EG_NODE_MASTER_IPS ]]; then
    if [[ -n $EG_NODE_CONTROLLER_MASTER_IPS || -n $EG_NODE_CONTROLLER_WORKER_IPS \
    || -n $EG_NODE_EDGE_MASTER_IPS || -n $EG_NODE_EDGE_WORKER_IPS ]]; then
      info "Wrong Configuration ....." $RED
      info "Suggestion: Unset not required configuration in env ....." $RED
      exit 1
    fi
    if [ "$OFFLINE_MODE" == "aio" ]; then EG_NODE_DEPLOY_IP=$(echo $EG_NODE_MASTER_IPS|cut -d "," -f1); fi
    hostname -I | grep $EG_NODE_DEPLOY_IP >/dev/null
    private_ip_list=$?
    curl ip.sb -s -m 2| grep $EG_NODE_DEPLOY_IP >/dev/null
    public_ip=$?
    if [[ $public_ip != 0 && $private_ip_list != 0 ]]; then
      info "Have to Run eg.sh on EG_NODE_MASTER_IPS" $RED
      exit 1
    fi
    if [ "$WHAT_TO_DO" == "-u" ] || [ "$WHAT_TO_DO" == "--uninstall" ]; then
      _eg_undeploy $eg_undeploy_feature $(echo $EG_NODE_MASTER_IPS|cut -d "," -f1) $EG_NODE_WORKER_IPS
      if [[ $SKIP_K8S_UN_INSTALLATION != "true" ]]; then
        _undeploy_k8s $EG_NODE_MASTER_IPS $EG_NODE_WORKER_IPS
      fi
    elif [ "$WHAT_TO_DO" == "-i" ] || [ "$WHAT_TO_DO" == "--install" ]; then
      _deploy_eg
    fi
  elif [[ -n $EG_NODE_CONTROLLER_MASTER_IPS ]]; then
    if [[ -n $EG_NODE_EDGE_MASTER_IPS || -n $EG_NODE_EDGE_WORKER_IPS ]]; then
      info "Wrong Configuration ....." $RED
      info "Suggestion: Unset not required configuration in env ....." $RED
      exit 1
    fi
    if [ "$OFFLINE_MODE" == "aio" ]; then EG_NODE_DEPLOY_IP=$(echo $EG_NODE_CONTROLLER_MASTER_IPS|cut -d "," -f1); fi
    hostname -I | grep $EG_NODE_DEPLOY_IP >/dev/null
    private_ip_list=$?
    curl ip.sb -s -m 2| grep $EG_NODE_DEPLOY_IP >/dev/null
    public_ip=$?
    if [[ $public_ip != 0 && $private_ip_list != 0 ]]; then
      info "Have to Run eg.sh on EG_NODE_CONTROLLER_MASTER_IPS" $RED
      exit 1
    fi
    if [ "$WHAT_TO_DO" == "-u" ] || [ "$WHAT_TO_DO" == "--uninstall" ]; then
      _eg_undeploy $controller_undeploy_feature $(echo $EG_NODE_CONTROLLER_MASTER_IPS|cut -d "," -f1) $EG_NODE_CONTROLLER_WORKER_IPS
      if [[ $SKIP_K8S_UN_INSTALLATION != "true" ]]; then
        _undeploy_k8s $EG_NODE_CONTROLLER_MASTER_IPS $EG_NODE_CONTROLLER_WORKER_IPS
      fi
    elif [ "$WHAT_TO_DO" == "-i" ] || [ "$WHAT_TO_DO" == "--install" ]; then
      _deploy_controller
    fi
  elif [[ -n $EG_NODE_EDGE_MASTER_IPS ]]; then
    if [ "$OFFLINE_MODE" == "aio" ]; then EG_NODE_DEPLOY_IP=$(echo $EG_NODE_EDGE_MASTER_IPS|cut -d "," -f1); fi
    hostname -I | grep $EG_NODE_DEPLOY_IP >/dev/null
    private_ip_list=$?
    curl ip.sb -s -m 2| grep $EG_NODE_DEPLOY_IP >/dev/null
    public_ip=$?
    if [[ $public_ip != 0 && $private_ip_list != 0 ]]; then
      info "Have to Run eg.sh on EG_NODE_EDGE_MASTER_IPS" $RED
      exit 1
    fi
    if [ "$WHAT_TO_DO" == "-u" ] || [ "$WHAT_TO_DO" == "--uninstall" ]; then
      _eg_undeploy $edge_undeploy_feature $(echo $EG_NODE_EDGE_MASTER_IPS|cut -d "," -f1) $EG_NODE_EDGE_WORKER_IPS
      if [[ $SKIP_K8S_UN_INSTALLATION != "true" ]]; then
        _undeploy_k8s $EG_NODE_EDGE_MASTER_IPS $EG_NODE_EDGE_WORKER_IPS
      fi
    elif [ "$WHAT_TO_DO" == "-i" ] || [ "$WHAT_TO_DO" == "--install" ]; then
      _deploy_edge
    fi
  else
    info "node IP values aren't set"  $RED
    _print__help
  fi
  if [[ $WHAT_TO_DO == '-i' || $WHAT_TO_DO == 'install' ]]; then
    failed_pod_count=$(kubectl get pods --all-namespaces | grep -v Running |wc -l)
    ((failed_pod_count=failed_pod_count-1))
    if [[ $failed_pod_count == 0 ]]; then
      if [[ -n $PORTAL_IP && -z $EG_NODE_EDGE_MASTER_IPS && -z $K8S_NODE_MASTER_IPS ]]; then
        print_portal_urls
      fi
      print_eg_logo
      info "EdgeGallery Got Deployed SuccessFully ....." $GREEN
      mkdir -p ~/.eg
      cat $PLATFORM_DIR/version.txt > ~/.eg/version
      exit 0
    else
      info "EdgeGallery Deployment Failed ....." $RED
      info "Pods with STATUS other than Running"
      kubectl get pods --all-namespaces --field-selector=status.phase!=Running
      exit 1
    fi
  fi
  exit 0
}

######################
script_name=$( basename ${0#-} )
this_script=$( basename ${BASH_SOURCE} )

#skip main in case of source
if [[ ${script_name} = ${this_script} ]] ; then
    main $@
fi
######################
