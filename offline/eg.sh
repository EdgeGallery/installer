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
USER_MGMT=30067

#===========================k8s-offline=========================================
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

function _docker_deploy() {
    docker version >/dev/null
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

    systemctl stop firewalld
    systemctl disable firewalld

    swapoff -a
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
  kubectl cluster-info >/dev/null
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
        kubeadm init --apiserver-advertise-address=$K8S_MASTER_IP --pod-network-cidr=10.244.0.0/16 -v=5

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
#tarball structure
#./eg_swr_images/
#./helm/
#./helm/helm-charts
#./helm/helm-charts/edgegallery
#./helm/helm-charts/stable
#./registry/
#./platform-mgmt
#./platform-mgmt/mep-deploy
#./nodelist.ini
#./README.md
#./LICENCE
#./eg-ecosystem.sh
#./eg-deploy.sh

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
  grep  -i "insecure-registries" /etc/docker/daemon.json | grep "$PRIVATE_REGISTRY_IP:5000" >/dev/null
  if [  $? != 0 ]; then
    mkdir -p /etc/docker
cat <<EOF | tee /etc/docker/daemon.json
{
    "insecure-registries" : ["$PRIVATE_REGISTRY_IP:5000"]
}
EOF
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
      "source /tmp/remote-platform/eg.sh; export PRIVATE_REGISTRY_IP=$PRIVATE_REGISTRY_IP; _help_insecure_registry;" < /dev/null
    done
    if [[ -n $WORKER_LIST ]]; then
    for node_ip in $WORKER_LIST;
    do
      scp $TARBALL_PATH/eg.sh root@$node_ip:/tmp/remote-platform
      sshpass ssh root@$node_ip \
      "source /tmp/remote-platform/eg.sh; export PRIVATE_REGISTRY_IP=$PRIVATE_REGISTRY_IP; _help_insecure_registry;" < /dev/null
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

  for f in *.tar.gz;
  do
    cat $f | docker load
    if [ "$OFFLINE_MODE" == "muno" ]; then
      IMAGE_NAME=`echo $f|rev|cut -c8-|rev|sed -e "s/\#/:/g" | sed -e "s/\@/\//g"`;
      docker image tag $IMAGE_NAME $IP:$PORT/$IMAGE_NAME
      docker push $IP:$PORT/$IMAGE_NAME
    fi
  done
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
  docker run --name helm-repo -v "$TARBALL_PATH"/helm/helm-charts/:/usr/share/nginx/html:ro  -d -p 8080:80  nginx:stable
  helm repo remove edgegallery stable;
  sleep 3
  helm repo add edgegallery http://${PRIVATE_REGISTRY_IP}:8080/edgegallery;
  helm repo add stable http://${PRIVATE_REGISTRY_IP}:8080/stable
}

function cleanup_eg_ecosystem()
{
  helm repo remove edgegallery stable
  docker stop helm-repo; docker rm -v helm-repo
  docker stop registry; docker rm -v registry
  docker image prune -a -f
  rm /root/.kube/config
}

function setup_eg_ecosystem()
{
  tar -xf $TARBALL_PATH/kubernetes_offline_installer.tar.gz -C $K8S_OFFLINE_DIR;
  export K8S_NODE_TYPE=WORKER; kubernetes_deploy;
  if [ "$OFFLINE_MODE" == "muno" ]; then
    _help_insecure_registry
    _load_and_run_docker_registry
  fi
  _load_swr_images_and_push_to_private_registry
  _help_install_helm_binary
  if [ "$OFFLINE_MODE" == "muno" ]; then
    _setup_helm_repo
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
  echo -e "$GREEN MECM PORTAL       : $BLUE https://$PORTAL_IP:$MECM_PORT"
  echo -e "$GREEN APPSTORE PORTAL   : $BLUE https://$PORTAL_IP:$APPSTORE_PORT"
  echo -e "$GREEN DEVELOPER PORTAL  : $BLUE https://$PORTAL_IP:$DEVELOPER_PORT"
  echo ""
}

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
  t=0
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
      break
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
  install_EdgeGallery $FEATURE $PORTAL_IP
}

function _eg_undeploy()
{
  FEATURE=$1
  MASTER_IP=$2
  uninstall_EdgeGallery $FEATURE
  if [[ $SKIP_ECO_SYSTEM_UN_INSTALLATION != "true" ]]; then
    cleanup_eg_ecosystem
  fi
  if [ $OFFLINE_MODE == "muno" ]; then
    for node_ip in $MASTER_IP;
    do
      if [[ $SKIP_ECO_SYSTEM_UN_INSTALLATION != "true" ]]; then
        sshpass ssh root@$node_ip \
        "docker image prune -a -f"
      fi
    done
  fi
}

function install_prometheus()
{
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
  else
    info "[Prometheus Deployment Failed]" $RED
    exit 1
  fi
}

function uninstall_prometheus()
{
  info "[UnDeploying Prometheus  ....]" $BLUE
  helm uninstall mep-prometheus
  info "[UnDeploying Prometheus  ....]" $GREEN
}

function install_grafana()
{
  info "[Deploying Grafana  .........]" $BLUE
  info "[it would take maximum of 5mins .......]" $BLUE

  rm -rf /mnt/grafana; mkdir -p /mnt/grafana
  cp $PLATFORM_DIR/conf/keys/tls.key /mnt/grafana/
  cp $PLATFORM_DIR/conf/keys/tls.crt /mnt/grafana/

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
  else
    info "[Grafana Deployment Failed  .]" $RED
    exit 1
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
  info "[UnDeployed Grafana  ........]" $GREEN
}

function install_rabbitmq()
{
  info "[Deploying Rabbitmq  ........]" $BLUE
  info "[it would take maximum of 5mins .......]" $BLUE
  suffix=""
  if [[ $REGISTRY_URL != "" ]]; then
    suffix="_private_registry"
    cp $PLATFORM_DIR/conf/manifest/rabbitmq/statefulset_x86.yaml $PLATFORM_DIR/conf/manifest/rabbitmq/statefulset_x86_private_registry.yaml
    cp $PLATFORM_DIR/conf/manifest/rabbitmq/statefulset_arm.yaml $PLATFORM_DIR/conf/manifest/rabbitmq/statefulset_arm_private_registry.yaml
    sed -i 's?image: rabbitmq:3.7-management-alpine?image: '$REGISTRY_URL'rabbitmq:3.7-management-alpine?g' $PLATFORM_DIR/conf/manifest/rabbitmq/statefulset_x86_private_registry.yaml
    sed -i 's?image: arm64v8/rabbitmq:3.7-management-alpine?image: '$REGISTRY_URL'arm64v8/rabbitmq:3.7-management-alpine?g' $PLATFORM_DIR/conf/manifest/rabbitmq/statefulset_arm_private_registry.yaml
  fi
  cd $PLATFORM_DIR/conf/manifest/rabbitmq
  if [ $KERNEL_ARCH == 'aarch64' ]; then
    kubectl apply -f common
    kubectl apply -f statefulset_arm$suffix.yaml
  else
    kubectl apply -f common
    kubectl apply -f statefulset_x86$suffix.yaml
  fi
  if [ $? -eq 0 ]; then
    wait "rabbitmq" 1
    info "[Deployed Rabbitmq  .........]" $GREEN
  else
    info "[Rabbitmq Deployment Failed  ]" $RED
  fi
}

function uninstall_rabbitmq()
{
  info "[UnDeploying Rabbitmq  ......]"  $BLUE
  cd $PLATFORM_DIR/conf/manifest/rabbitmq
  if [ $KERNEL_ARCH == 'aarch64' ]; then
    kubectl delete -f common
    kubectl delete -f statefulset_arm.yaml
    kubectl delete -f statefulset_arm_private_registry.yaml
  else
    kubectl delete -f common
    kubectl delete -f statefulset_x86.yaml
    kubectl delete -f statefulset_x86_private_registry.yaml
  fi
  info "[UnDeployed Rabbitmq  .......]"  $BLUE
}

function install_mep()
{
  info "[Deploying MEP  .............]" $BLUE
  info "[it would take maximum of 5mins .......]" $BLUE
  _deploy_dns_metallb
  _deploy_network_isolation_multus

  helm install --wait mep-edgegallery "$CHART_PREFIX"edgegallery/mep"$CHART_SUFFIX" \
  --set networkIsolation.phyInterface.mp1=$EG_NODE_EDGE_MP1 \
  --set networkIsolation.phyInterface.mm5=$EG_NODE_EDGE_MM5 \
  --set images.mep.repository=$mep_images_mep_repository \
  --set images.mepauth.repository=$mep_images_mepauth_repository \
  --set images.dns.repository=$mep_images_dns_repository \
  --set images.kong.repository=$mep_images_kong_repository \
  --set images.postgres.repository=$mep_images_postgres_repository \
  --set images.mep.tag=$mep_images_mep_tag \
  --set images.mepauth.tag=$mep_images_mepauth_tag \
  --set images.dns.tag=$mep_images_dns_tag \
  --set images.mep.pullPolicy=$mep_images_mep_pullPolicy \
  --set images.mepauth.pullPolicy=$mep_images_mepauth_pullPolicy \
  --set images.dns.pullPolicy=$mep_images_dns_pullPolicy \
  --set images.kong.pullPolicy=$mep_images_kong_pullPolicy \
  --set images.postgres.pullPolicy=$mep_images_postgres_pullPolicy \
  --set ssl.secretName=$mep_ssl_secretName

  if [ $? -eq 0 ]; then
    info "[Deployed MEP  .........]" $GREEN
  else
    info "[MEP Deployment Failed  ]" $RED
    exit 1
  fi
  
  info "[Deployed MEP  ..............]" $GREEN
}

function uninstall_mep()
{
  info "[UnDeploying MEP  ...........]" $BLUE
  helm uninstall mep-edgegallery
  _undeploy_network_isolation_multus
  _undeploy_dns_metallb
  info "[UnDeployed MEP  ............]" $GREEN
}

function install_common-svc()
{
  install_prometheus
  install_grafana
  install_rabbitmq
}

function uninstall_common-svc()
{
  uninstall_prometheus
  uninstall_grafana
  uninstall_rabbitmq
}

function install_mecm-mepm ()
{
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

  helm install --wait mecm-mepm-edgegallery "$CHART_PREFIX"edgegallery/mecm-mepm"$CHART_SUFFIX" \
    --set jwt.publicKeySecretName=$mepm_jwt_publicKeySecretName \
    --set mepm.secretName=$mepm_mepm_secretName \
    --set ssl.secretName=$mepm_ssl_secretName \
    --set images.lcmcontroller.repository=$mepm_images_lcmcontroller_repository \
    --set images.k8splugin.repository=$mepm_images_k8splugin_repository \
    --set images.postgres.repository=$mepm_images_postgres_repository \
    --set images.lcmcontroller.tag=$mepm_images_lcmcontroller_tag \
    --set images.k8splugin.tag=$mepm_images_k8splugin_tag \
    --set images.postgres.tag=$mepm_images_postgres_tag \
    --set images.lcmcontroller.pullPolicy=$mepm_images_lcmcontroller_pullPolicy \
    --set images.k8splugin.pullPolicy=$mepm_images_k8splugin_pullPolicy \
    --set images.postgres.pullPolicy=$mepm_images_postgres_pullPolicy
  if [ $? -eq 0 ]; then
    info "[Deployed MECM-MEPM  ........]" $GREEN
  else
    info "[MECM-MEPM Deployment Failed ]" $RED
    exit 1
  fi
}

function uninstall_mecm-mepm ()
{
    info "[UnDeploying MECM-MEPM  .....]" $BLUE
    helm uninstall mecm-mepm-edgegallery
    kubectl delete secret mecm-mepm-jwt-public-secret mecm-mepm-ssl-secret edgegallery-mepm-secret
    info "[UnDeployed MECM-MEPM  ......]" $GREEN
}

function install_mecm-meo ()
{
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
    --from-literal=edgeRepoUserName=admin	 \
    --from-literal=edgeRepoPassword=admin123

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
    --set images.postgres.pullPolicy=$meo_images_postgres_pullPolicy
  if [ $? -eq 0 ]; then
    info "[Deployed MECM-MEO  .........]" $GREEN
  else
    info "[MECM-MEO Deployment Failed  ]" $RED
    exit 1
  fi
}

function uninstall_mecm-meo ()
{
    info "[UnDeploying MECM-MEO  ........]" $BLUE
    helm uninstall mecm-meo-edgegallery
    kubectl delete secret mecm-ssl-secret edgegallery-mecm-secret
    info "[UnDeployed MECM-MEO  .......]" $GREEN
}

function install_mecm-fe ()
{
  info "[Deploying MECM-FE  ........]" $BLUE
  info "[it would take maximum of 5mins .......]" $BLUE
  helm install --wait mecm-fe-edgegallery "$CHART_PREFIX"edgegallery/mecm-fe"$CHART_SUFFIX" \
    --set global.oauth2.authServerAddress=https://$NODEIP:$USER_MGMT \
    --set images.mecmFe.repository=$mecm_fe_images_mecmFe_repository \
    --set images.initservicecenter.repository=$mecm_fe_images_initservicecenter_repository \
    --set images.mecmFe.tag=$mecm_fe_images_mecmFe_tag \
    --set images.mecmFe.pullPolicy=$mecm_fe_images_mecmFe_pullPolicy \
    --set images.initservicecenter.pullPolicy=$mecm_fe_images_initservicecenter_pullPolicy \
    --set global.ssl.enabled=$mecm_fe_global_ssl_enabled \
    --set global.ssl.secretName=$mecm_fe_global_ssl_secretName
  if [ $? -eq 0 ]; then
    info "[Deployed MECM-FE  ..........]" $GREEN
  else
    info "[MECM-FE Deployment Failed  .]" $RED
    exit 1
  fi
}

function uninstall_mecm-fe ()
{
    info "[UnDeploying MECM-FE  .......]" $BLUE
    helm uninstall mecm-fe-edgegallery
    info "[UnDeployed MECM-FE  ........]" $GREEN
}

function install_appstore ()
{
  info "[Deploying AppStore  ........]" $BLUE
  info "[it would take maximum of 5mins .......]" $BLUE
  helm install --wait appstore-edgegallery "$CHART_PREFIX"edgegallery/appstore"$CHART_SUFFIX" \
  --set global.oauth2.authServerAddress=https://$NODEIP:$USER_MGMT \
  --set images.appstoreFe.repository=$appstore_images_appstoreFe_repository \
  --set images.appstoreBe.repository=$appstore_images_appstoreBe_repository \
  --set images.postgres.repository=$appstore_images_postgres_repository \
  --set images.initservicecenter.repository=$appstore_images_initservicecenter_repository \
  --set images.appstoreFe.tag=$appstore_images_appstoreFe_tag \
  --set images.appstoreBe.tag=$appstore_images_appstoreBe_tag \
  --set images.appstoreFe.pullPolicy=$appstore_images_appstoreFe_pullPolicy \
  --set images.appstoreBe.pullPolicy=$appstore_images_appstoreBe_pullPolicy \
  --set images.postgres.pullPolicy=$appstore_images_postgres_pullPolicy \
  --set images.initservicecenter.pullPolicy=$appstore_images_initservicecenter_pullPolicy \
  --set global.ssl.enabled=$appstore_global_ssl_enabled \
  --set global.ssl.secretName=$appstore_global_ssl_secretName
  if [ $? -eq 0 ]; then
    info "[Deployed AppStore  .........]" $GREEN
  else
    info "[AppStore Deployment Failed  ]" $RED
    exit 1
  fi
}

function uninstall_appstore ()
{
  info "[UnDeploying AppStore  ......]" $BLUE
  helm uninstall appstore-edgegallery
  info "[UnDeployed AppStore  .......]" $GREEN
}

function install_developer ()
{
  info "[Deploying Developer  .......]"  $BLUE
  info "[it would take maximum of 5mins .......]" $BLUE
  helm install --wait developer-edgegallery "$CHART_PREFIX"edgegallery/developer"$CHART_SUFFIX" \
  --set global.oauth2.authServerAddress=https://$NODEIP:$USER_MGMT \
  --set images.developerFe.repository=$developer_images_developerFe_repository \
  --set images.developerBe.repository=$developer_images_developerBe_repository \
  --set images.postgres.repository=$developer_images_postgres_repository \
  --set images.initservicecenter.repository=$developer_images_initservicecenter_repository \
  --set images.developerFe.tag=$developer_images_developerFe_tag \
  --set images.developerBe.tag=$developer_images_developerBe_tag \
  --set images.developerFe.pullPolicy=$developer_images_developerFe_pullPolicy \
  --set images.developerBe.pullPolicy=$developer_images_developerBe_pullPolicy \
  --set images.postgres.pullPolicy=$developer_images_postgres_pullPolicy \
  --set images.initservicecenter.pullPolicy=$developer_images_initservicecenter_pullPolicy \
  --set global.ssl.enabled=$developer_global_ssl_enabled \
  --set global.ssl.secretName=$developer_global_ssl_secretName
  if [ $? -eq 0 ]; then
    info "[Deployed Developer .........]" $GREEN
  else
    fail "[Developer Deployment Failed ]" $RED
    exit 1
  fi
}

function uninstall_developer ()
{
  info "[UnDeploying Developer  .....]" $BLUE
  helm uninstall developer-edgegallery
  info "[UnDeployed Developer  ......]" $GREEN
}

function install_service-center ()
{
  info "[Deploying ServiceCenter  ...]" $BLUE
  info "[it would take maximum of 5mins .......]" $BLUE
  helm install --wait service-center-edgegallery "$CHART_PREFIX"edgegallery/servicecenter"$CHART_SUFFIX" \
  --set images.repository=$servicecenter_images_repository \
  --set images.pullPolicy=$servicecenter_images_pullPolicy \
  --set global.ssl.enabled=$servicecenter_global_ssl_enabled \
  --set global.ssl.secretName=$servicecenter_global_ssl_secretName
  if [ $? -eq 0 ]; then
    info "[Deployed ServiceCenter  ....]" $GREEN
  else
    info "[ServiceCenter Deployment Failed]" $RED
    exit 1
  fi
}

function uninstall_service-center ()
{
  info "[UnDeploying ServiceCenter  .]" $BLUE
  helm uninstall service-center-edgegallery
  info "[UnDeployed ServiceCenter  ..]"
}

function install_user-mgmt ()
{
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
global.oauth2.clients.mecm.clientUrl=https://$NODEIP:$MECM_PORT, \
--set jwt.secretName=$usermgmt_jwt_secretName \
--set images.usermgmt.repository=$usermgmt_images_usermgmt_repository \
--set images.postgres.repository=$usermgmt_images_postgres_repository \
--set images.redis.repository=$usermgmt_images_redis_repository \
--set images.initservicecenter.repository=$usermgmt_images_initservicecenter_repository \
--set images.usermgmt.tag=$usermgmt_images_usermgmt_tag \
--set images.usermgmt.pullPolicy=$usermgmt_images_usermgmt_pullPolicy \
--set images.postgres.pullPolicy=$usermgmt_images_postgres_pullPolicy \
--set images.redis.pullPolicy=$usermgmt_images_redis_pullPolicy \
--set images.initservicecenter.pullPolicy=$usermgmt_images_initservicecenter_pullPolicy \
--set global.ssl.enabled=$usermgmt_global_ssl_enabled \
--set global.ssl.secretName=$usermgmt_global_ssl_secretName

  if [ $? -eq 0 ]; then
    info "[Deployed UserMgmt  .........]" $GREEN
  else
    info "[UserMgmt Deployment Failed .]" $RED
    exit 1
  fi
}

function uninstall_user-mgmt ()
{
  info "[UnDeploying UserMgmt  ......]" $BLUE
  helm uninstall user-mgmt-edgegallery
  kubectl delete secret user-mgmt-jwt-secret
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

function install_EdgeGallery ()
{
  FEATURE=$1
  NODEIP=$2
  if [ -z "$DEPLOY_TYPE" ]; then
    DEPLOY_TYPE="nodePort"
  fi
  if [[ $FEATURE == 'edge' || $FEATURE == 'all' ]]; then
    install_mep
    install_mecm-mepm
    install_common-svc
  fi
  if [[ ($FEATURE == 'controller' || $FEATURE == 'all') && ($DEPLOY_TYPE == 'nodePort') ]]; then
    kubectl create secret generic edgegallery-ssl-secret \
    --from-file=keystore.p12=$PLATFORM_DIR/conf/keys/keystore.p12 \
    --from-literal=keystorePassword=te9Fmv%qaq \
    --from-literal=keystoreType=PKCS12 \
    --from-literal=keyAlias=edgegallery \
    --from-file=trust.cer=$PLATFORM_DIR/conf/keys/ca.crt \
    --from-file=server.cer=$PLATFORM_DIR/conf/keys/tls.crt \
    --from-file=server_key.pem=$PLATFORM_DIR/conf/keys/encryptedtls.key \
    --from-literal=cert_pwd=te9Fmv%qaq
    install_service-center
    install_user-mgmt
    install_mecm-meo
    install_mecm-fe
    install_appstore
    install_developer
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
     uninstall_mep
     uninstall_mecm-mepm
     uninstall_common-svc
   fi
   if [[ ($FEATURE == 'controller' || $FEATURE == 'all') && ($DEPLOY_TYPE == 'nodePort') ]]; then
     uninstall_mecm-fe
     uninstall_mecm-meo
     uninstall_appstore
     uninstall_developer
     uninstall_user-mgmt
     uninstall_service-center
     kubectl delete secret edgegallery-ssl-secret
   elif [[ ($FEATURE == 'controller' || $FEATURE == 'all') && ($DEPLOY_TYPE == 'ingress') ]]; then
     uninstall_controller_with_ingress
   fi
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
  configure_eg_ecosystem_on_remote $MASTER_IP $EG_NODE_WORKER_IPS
  _eg_deploy all $EG_NODE_DEPLOY_IP $MASTER_IP
}

function _deploy_controller()
{
  password_less_ssh_check $EG_NODE_CONTROLLER_MASTER_IPS $EG_NODE_CONTROLLER_WORKER_IPS
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
  configure_eg_ecosystem_on_remote $MASTER_IP $EG_NODE_CONTROLLER_WORKER_IPS
  _eg_deploy controller $EG_NODE_DEPLOY_IP $MASTER_IP
}

function _deploy_edge()
{
  password_less_ssh_check $EG_NODE_EDGE_MASTER_IPS $EG_NODE_EDGE_WORKER_IPS
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
  configure_eg_ecosystem_on_remote  $MASTER_IP $EG_NODE_EDGE_WORKER_IPS
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
   kubectl apply -f $PLATFORM_DIR/conf/edge/metallb/metallb.yaml
   kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
   sed -i "s/192.168.100.120/${EG_NODE_DNS_LBS_IPS}/g" $PLATFORM_DIR/conf/edge/metallb/config-map.yaml
   kubectl apply -f $PLATFORM_DIR/conf/edge/metallb/config-map.yaml

   sleep 3
   info "[Deployed DNS METALLB  ..............]" $GREEN
}

function _undeploy_dns_metallb() {
  info "Undeploying DNS METALLB  ..............]" $YELLOW
  kubectl delete secret memberlist -n metallb-system
  info "[Undeployed DNS METALLB  ..............]" $GREEN
}

function _deploy_network_isolation_multus() {
  info "[Deploying multus cni  ..............]" $YELLOW

  if [[ -z $EG_NODE_EDGE_MP1 ]]; then
      EG_NODE_EDGE_MP1=eth0
  fi

  if [[ -z $EG_NODE_EDGE_MM5 ]]; then
    EG_NODE_EDGE_MM5=eth0
  fi

  if [[ ! -d /opt/cni/bin ]]; then
    mkdir -p /opt/cni/bin
  fi

  cp $K8S_OFFLINE_DIR/cni/macvlan /opt/cni/bin/
  cp $K8S_OFFLINE_DIR/cni/host-local /opt/cni/bin/

  kubectl apply -f $PLATFORM_DIR/conf/edge/network-isolation/multus.yaml
  kubectl apply -f $PLATFORM_DIR/conf/edge/network-isolation/eg-sp-rbac.yaml
  kubectl apply -f $PLATFORM_DIR/conf/edge/network-isolation/eg-sp-controller.yaml

  ip link add eg-mp1 link $EG_NODE_EDGE_MP1 type macvlan mode bridge 
  ip addr add 200.1.1.100/24 dev eg-mp1
  ip link set dev eg-mp1 up

  ip link add eg-mm5 link $EG_NODE_EDGE_MM5 type macvlan mode bridge 
  ip addr add 100.1.1.100/24 dev eg-mm5
  ip link set dev eg-mm5 up

  info "[Deployed multus cni  ..............]" $GREEN
}

function _undeploy_network_isolation_multus() {
  info "[Undeploying multus cni  ..............]" $YELLOW
	rm /opt/cni/bin/macvlan /opt/cni/bin/host-local
	
  ip link set dev eg-mp1 down
	ip link delete eg-mp1
	
  ip link set dev eg-mm5 down
	ip link delete eg-mm5
  
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
  info "EG_NODE_CONTROLLER_WORKER_MASTER_IPS=$EG_NODE_CONTROLLER_WORKER_MASTER_IPS" "$GREEN"
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
      curl ip.sb | grep $EG_NODE_DEPLOY_IP >/dev/null
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
    CHART_SUFFIX="-1.0.1.tgz"
    PROM_CHART_SUFFIX="-9.3.1.tgz"
    GRAFANA_CHART_SUFFIX="-5.5.5.tgz"
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
    curl ip.sb | grep $EG_NODE_DEPLOY_IP >/dev/null
    public_ip=$?
    if [[ $public_ip != 0 && $private_ip_list != 0 ]]; then
      info "Have to Run eg.sh on EG_NODE_MASTER_IPS" $RED
      exit 1
    fi
    if [ "$WHAT_TO_DO" == "-u" ] || [ "$WHAT_TO_DO" == "--uninstall" ]; then
      _eg_undeploy $eg_undeploy_feature $(echo $EG_NODE_MASTER_IPS|cut -d "," -f1)
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
    curl ip.sb | grep $EG_NODE_DEPLOY_IP >/dev/null
    public_ip=$?
    if [[ $public_ip != 0 && $private_ip_list != 0 ]]; then
      info "Have to Run eg.sh on EG_NODE_CONTROLLER_MASTER_IPS" $RED
      exit 1
    fi
    if [ "$WHAT_TO_DO" == "-u" ] || [ "$WHAT_TO_DO" == "--uninstall" ]; then
      _eg_undeploy $controller_undeploy_feature $(echo $EG_NODE_CONTROLLER_MASTER_IPS|cut -d "," -f1)
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
    curl ip.sb | grep $EG_NODE_DEPLOY_IP >/dev/null
    public_ip=$?
    if [[ $public_ip != 0 && $private_ip_list != 0 ]]; then
      info "Have to Run eg.sh on EG_NODE_EDGE_MASTER_IPS" $RED
      exit 1
    fi
    if [ "$WHAT_TO_DO" == "-u" ] || [ "$WHAT_TO_DO" == "--uninstall" ]; then
      _eg_undeploy $edge_undeploy_feature $(echo $EG_NODE_EDGE_MASTER_IPS|cut -d "," -f1)
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
