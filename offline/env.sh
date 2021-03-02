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
this_script_name=$( basename ${BASH_SOURCE} )
image_tag_env=$(cat $this_script_name | grep "EG_IMAGE_TAG=" | grep -v "#export")
$image_tag_env

#Set the following env as described in README and source it in console session
#CAUTION: Set only those env required, otherwise unset other env variables

#export OFFLINE_MODE=
#export PORTAL_IP=
#export EG_NODE_DEPLOY_IP=
#export EG_NODE_MASTER_IPS=
#export EG_NODE_WORKER_IPS=
#export EG_NODE_EDGE_MP1=
#export EG_NODE_EDGE_MM5=
#export EG_NODE_CONTROLLER_MASTER_IPS=
#export EG_NODE_CONTROLLER_WORKER_IPS=
#export EG_NODE_EDGE_MASTER_IPS=
#export EG_NODE_EDGE_WORKER_IPS=
#export SKIP_K8S=
#export EG_IMAGE_TAG=

REGISTRY_URL=""
if [[ $OFFLINE_MODE == "muno" ]]; then
  REGISTRY_URL="$EG_NODE_DEPLOY_IP:5000/"
fi

##ENABLE_PERSISTENCE
#set "true" to enable persistence storage
export ENABLE_PERSISTENCE="false"
export NFS_SERVER_IP=""
export NFS_PATH=""

##SSL certs validity
export CERT_VALIDITY_IN_DAYS=365

#MEP values
PG_ADMIN_PWD=""
KONG_PG_PWD=""
CERT_PWD=""

export mep_images_mep_repository="$REGISTRY_URL"edgegallery/mep
export mep_images_mepauth_repository="$REGISTRY_URL"edgegallery/mepauth
export mep_images_dns_repository="$REGISTRY_URL"edgegallery/mep-dns-server
export mep_images_kong_repository="$REGISTRY_URL"kong
export mep_images_postgres_repository="$REGISTRY_URL"postgres
export mep_images_mep_tag="$EG_IMAGE_TAG"
export mep_images_mepauth_tag="$EG_IMAGE_TAG"
export mep_images_dns_tag="$EG_IMAGE_TAG"
export mep_images_kong_tag=2.0.4-ubuntu
export mep_images_postgres_tag=12.3
export mep_images_mep_pullPolicy=IfNotPresent
export mep_images_mepauth_pullPolicy=IfNotPresent
export mep_images_dns_pullPolicy=IfNotPresent
export mep_images_kong_pullPolicy=IfNotPresent
export mep_images_postgres_pullPolicy=IfNotPresent
export mep_ssl_secretName=mep-ssl

#MECM-MEPM Values
export mepm_jwt_publicKeySecretName=mecm-mepm-jwt-public-secret
export mepm_mepm_secretName=edgegallery-mepm-secret
export mepm_ssl_secretName=mecm-mepm-ssl-secret
export mepm_images_lcmcontroller_repository="$REGISTRY_URL"edgegallery/mecm-applcm
export mepm_images_k8splugin_repository="$REGISTRY_URL"edgegallery/mecm-applcm-k8splugin
export mepm_images_apprulemgr_repository="$REGISTRY_URL"edgegallery/mecm-apprulemgr
export mepm_images_postgres_repository="$REGISTRY_URL"postgres
export mepm_images_lcmcontroller_tag="$EG_IMAGE_TAG"
export mepm_images_k8splugin_tag="$EG_IMAGE_TAG"
export mepm_images_apprulemgr_tag="$EG_IMAGE_TAG"
export mepm_images_postgres_tag=12.3
export mepm_images_lcmcontroller_pullPolicy=IfNotPresent
export mepm_images_k8splugin_pullPolicy=IfNotPresent
export mepm_images_apprulemgr_pullPolicy=IfNotPresent
export mepm_images_postgres_pullPolicy=IfNotPresent

#ServiceCenter Values
export servicecenter_images_repository="$REGISTRY_URL"edgegallery/service-center
export servicecenter_images_tag=latest
export servicecenter_images_pullPolicy=IfNotPresent
export servicecenter_global_ssl_enabled=true
export servicecenter_global_ssl_secretName=edgegallery-ssl-secret

#UserMgmt Values
export usermgmt_jwt_secretName=user-mgmt-jwt-secret
export usermgmt_images_usermgmt_repository="$REGISTRY_URL"edgegallery/user-mgmt
export usermgmt_images_postgres_repository="$REGISTRY_URL"edgegallery/postgres
export usermgmt_images_redis_repository="$REGISTRY_URL"edgegallery/redis
export usermgmt_images_initservicecenter_repository="$REGISTRY_URL"edgegallery/curl
export usermgmt_images_usermgmt_tag="$EG_IMAGE_TAG"
export usermgmt_images_postgres_tag=12.2
export usermgmt_images_redis_tag=6.0.3
export usermgmt_images_initservicecenter_tag=latest
export usermgmt_images_usermgmt_pullPolicy=IfNotPresent
export usermgmt_images_postgres_pullPolicy=IfNotPresent
export usermgmt_images_redis_pullPolicy=IfNotPresent
export usermgmt_images_initservicecenter_pullPolicy=IfNotPresent
export usermgmt_global_ssl_enabled=true
export usermgmt_global_ssl_secretName=edgegallery-ssl-secret
#export usermgmt_mail_enabled=
#export usermgmt_mail_host=
#export usermgmt_mail_port=
#export usermgmt_mail_sender=
#export usermgmt_mail_authcode=

#MEO values
export meo_ssl_secretName=mecm-ssl-secret
export meo_mecm_secretName=edgegallery-mecm-secret
export meo_images_inventory_repository="$REGISTRY_URL"edgegallery/mecm-inventory
export meo_images_appo_repository="$REGISTRY_URL"edgegallery/mecm-appo
export meo_images_apm_repository="$REGISTRY_URL"edgegallery/mecm-apm
export meo_images_postgres_repository="$REGISTRY_URL"postgres
export meo_images_inventory_tag="$EG_IMAGE_TAG"
export meo_images_appo_tag="$EG_IMAGE_TAG"
export meo_images_apm_tag="$EG_IMAGE_TAG"
export meo_images_postgres_tag=12.3
export meo_images_inventory_pullPolicy=IfNotPresent
export meo_images_appo_pullPolicy=IfNotPresent
export meo_images_apm_pullPolicy=IfNotPresent
export meo_images_postgres_pullPolicy=IfNotPresent

#MECM-FE values
export mecm_fe_images_mecmFe_repository="$REGISTRY_URL"edgegallery/mecm-fe
export mecm_fe_images_initservicecenter_repository="$REGISTRY_URL"edgegallery/curl
export mecm_fe_images_mecmFe_tag="$EG_IMAGE_TAG"
export mecm_fe_images_initservicecenter_tag=latest
export mecm_fe_images_mecmFe_pullPolicy=IfNotPresent
export mecm_fe_images_initservicecenter_pullPolicy=IfNotPresent
export mecm_fe_global_ssl_enabled=true
export mecm_fe_global_ssl_secretName=edgegallery-ssl-secret

#AppStore Values
export appstore_images_appstoreFe_repository="$REGISTRY_URL"edgegallery/appstore-fe
export appstore_images_appstoreBe_repository="$REGISTRY_URL"edgegallery/appstore-be
export appstore_images_postgres_repository="$REGISTRY_URL"edgegallery/postgres
export appstore_images_initservicecenter_repository="$REGISTRY_URL"edgegallery/curl
export appstore_images_appstoreFe_tag="$EG_IMAGE_TAG"
export appstore_images_appstoreBe_tag="$EG_IMAGE_TAG"
export appstore_images_postgres_tag=12.2
export appstore_images_initservicecenter_tag=latest
export appstore_images_appstoreFe_pullPolicy=IfNotPresent
export appstore_images_appstoreBe_pullPolicy=IfNotPresent
export appstore_images_postgres_pullPolicy=IfNotPresent
export appstore_images_initservicecenter_pullPolicy=IfNotPresent
export appstore_global_ssl_enabled=true
export appstore_global_ssl_secretName=edgegallery-ssl-secret
export appstore_poke_platformUrl=https://"$PORTAL_IP":30099
export appstore_poke_atpReportUrl=https://"$PORTAL_IP":30094/#/atpreport?taskid=%s

#Developer Values
export developer_images_developerFe_repository="$REGISTRY_URL"edgegallery/developer-fe
export developer_images_developerBe_repository="$REGISTRY_URL"edgegallery/developer-be
export developer_images_postgres_repository="$REGISTRY_URL"edgegallery/postgres
export developer_images_initservicecenter_repository="$REGISTRY_URL"edgegallery/curl
export developer_images_toolChain_repository="$REGISTRY_URL"edgegallery/tool-chain
export developer_images_portingAdvisor_repository="$REGISTRY_URL"edgegallery/porting-advisor
export developer_images_developerFe_tag="$EG_IMAGE_TAG"
export developer_images_developerBe_tag="$EG_IMAGE_TAG"
export developer_images_toolChain_tag="$EG_IMAGE_TAG"
export developer_images_postgres_tag=12.2
export developer_images_initservicecenter_tag=latest
export developer_images_portingAdvisor_tag=latest
export developer_images_developerFe_pullPolicy=IfNotPresent
export developer_images_developerBe_pullPolicy=IfNotPresent
export developer_images_postgres_pullPolicy=IfNotPresent
export developer_images_initservicecenter_pullPolicy=IfNotPresent
export developer_images_toolChain_pullPolicy=IfNotPresent
export developer_images_portingAdvisor_pullPolicy=IfNotPresent
export developer_global_ssl_enabled=true
export developer_global_ssl_secretName=edgegallery-ssl-secret

#ATP Values
export atp_images_atpFe_repository="$REGISTRY_URL"edgegallery/atp-fe
export atp_images_atp_repository="$REGISTRY_URL"edgegallery/atp-be
export atp_images_postgres_repository="$REGISTRY_URL"edgegallery/postgres
export atp_images_initservicecenter_repository="$REGISTRY_URL"edgegallery/curl
export atp_images_atpFe_tag="$EG_IMAGE_TAG"
export atp_images_atp_tag="$EG_IMAGE_TAG"
export atp_images_postgres_tag=12.2
export atp_images_initservicecenter_tag=latest
export atp_images_atpFe_pullPolicy=IfNotPresent
export atp_images_atp_pullPolicy=IfNotPresent
export atp_images_postgres_pullPolicy=IfNotPresent
export atp_images_initservicecenter_pullPolicy=IfNotPresent
export atp_global_ssl_enabled=true
export atp_global_ssl_secretName=edgegallery-ssl-secret
