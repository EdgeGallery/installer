export RED='\033[0;31m'
export NC='\033[0m'
export GREEN='\033[0;32m'
export BLUE='\033[0;34m'

function info() {
  echo -e "$2 $1 $NC"
}

cat ~/.eg/version | grep "latest"
not_latest=$?
cat ~/.eg/version | grep "1.0.0"
not_1_0_0=$?

if [[ $not_1_0_0 -eq 1 && $not_latest -eq 1 ]]; then
  info "patch is not available for the installed EG version" $RED
  info "patch is for latest and 1.0.0 versions of EG" $RED
  exit 1
fi

TARBALL_PATH=$PWD
WHAT_TO_DO=$1

if [[ $OFFLINE_MODE == "muno" ]]; then
  PRIVATE_REGISTRY_IP="$EG_NODE_DEPLOY_IP"
  PORT="5000"
  REGISTRY_URL="$PRIVATE_REGISTRY_IP:$PORT/"
else
  REGISTRY_URL=""
fi

function load_docker_images_n_helm_charts()
{
  cd "$TARBALL_PATH"/eg_swr_images || exit
  for f in *.tar.gz;
  do
    cat $f | docker load
    if [ "$OFFLINE_MODE" == "muno" ]; then
      IMAGE_NAME=`echo $f|rev|cut -c8-|rev|sed -e "s/\#/:/g" | sed -e "s/\@/\//g"`;
      docker image tag $IMAGE_NAME ${REGISTRY_URL}/$IMAGE_NAME
      docker push ${REGISTRY_URL}/$IMAGE_NAME
    fi
  done
}

function install_patch_component()
{
  info "[Deploying MEP  .............]" $BLUE
  if [[ $OFFLINE_MODE == 'aio' ]] ; then
    if [[ -n $EG_NODE_MASTER_IPS ]]; then
      PRIVATE_IP=$EG_NODE_MASTER_IPS
    elif [[ -n $EG_NODE_EDGE_MASTER_IPS ]]; then
      PRIVATE_IP=$EG_NODE_EDGE_MASTER_IPS
    else
      info "either EG_NODE_MASTER_IPS or EG_NODE_EDGE_MASTER_IPS must be set for this patch " $RED
      exit 1
    fi
    if [[ -z $EG_NODE_EDGE_MP1 ]]; then
      EG_NODE_EDGE_MP1=$(ip a | grep -B2 $PRIVATE_IP | head -n1 | cut -d ":" -f2 |cut -d " " -f2)
    fi
    if [[ -z $EG_NODE_EDGE_MM5 ]]; then
        EG_NODE_EDGE_MM5=$(ip a | grep -B2 $PRIVATE_IP | head -n1 | cut -d ":" -f2 |cut -d " " -f2)
    fi
  fi
  if [[ $KERNEL_ARCH == 'x86_64' && $OFFLINE_MODE == 'muno' ]] ; then
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
  --set images.mep.repository="$REGISTRY_URL"$mep_images_mep_repository \
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
  --set ssl.secretName=$mep_ssl_secretName \
  --set global.persistence.enabled=$ENABLE_PERSISTENCE
  if [ $? -eq 0 ]; then
    info "[Deployed MEP  .........]" $GREEN
  else
    info "[MEP Deployment Failed  ]" $RED
    exit 1
  fi
}

function uninstall_patch_component()
{
  info "[UnDeploying MEP  ...........]" $BLUE
  helm uninstall mep-edgegallery
  info "[UnDeployed MEP  ............]" $GREEN
}

function main()
{
  if [ "$WHAT_TO_DO" == "-i" ] || [ "$WHAT_TO_DO" == "--install" ]; then
    CHART_PREFIX="$TARBALL_PATH/helm/helm-charts/"
    CHART_SUFFIX="-1.0.0.tgz"
    load_docker_images_n_helm_charts
    uninstall_patch_component
    install_patch_component
  fi
  if [ "$WHAT_TO_DO" == "-u" ] || [ "$WHAT_TO_DO" == "--uninstall" ]; then
    uninstall_patch_component
  fi
}

########################
main
########################
