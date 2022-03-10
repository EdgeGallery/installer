# EdgeGallery Online Installation

## Deployment Architecture
1. Deploy Node
2. Master Node
3. Worker Node
4. Storage Node

INFO: The Deploy node and Master Node could be the same node.

INFO: The Storage node and Master Node could be the same node.

INFO: in this guide "All Nodes" refers to "Deploy, Master and Worker nodes"

## 1. Download required gitee repositories on Deploy Node
```
cd /root
git clone -b Release-v1.5 https://gitee.com/edgegallery/helm-charts.git
git clone -b Release-v1.5 https://gitee.com/edgegallery/installer.git
```

## 2. Docker Installation on All Nodes

#### Uninstall old versions:
```
apt-get remove docker docker-engine docker.io containerd runc
```
#### Install docker 20.10.7 version:
```
apt-get update
apt-get install ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce=5:20.10.7~3-0~ubuntu-bionic docker-ce-cli=5:20.10.7~3-0~ubuntu-bionic containerd.io
```

## 3. Kubernetes Tools Installation on All Nodes
```
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system

apt-get update
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubeadm=1.23.4-00 kubelet=1.23.4-00 kubectl=1.23.4-00
apt-mark hold kubelet kubeadm kubectl

apt-get update && apt-get upgrade #MAY BE THIS COMMAND IS upgrading docker
apt-get install docker-ce=5:20.10.7~3-0~ubuntu-bionic docker-ce-cli=5:20.10.7~3-0~ubuntu-bionic containerd.io

sudo mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{ "exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts":
{ "max-size": "100m" },
"storage-driver": "overlay2"
}
EOF

systemctl enable docker
systemctl daemon-reload
systemctl restart docker
```

## 4. Initiate kubernetes cluster on Master Node
```
kubeadm init --apiserver-advertise-address=10.0.0.18 --pod-network-cidr=10.244.0.0/16
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
### Apply calico.yaml
```
kubectl apply -f ./installer/ansible_package/roles/k8s/files/calico.yaml
```
### Taint nodes
```
kubectl taint nodes --all node-role.kubernetes.io/master-
```

## 5. Join all the Worker nodes to kubernetes Master
```
[on master node] kubeadm token create --print-join-command
[on worker node] kubeadm join 10.0.0.18:6443 --token bexqhx.vxxkk0tfwupoo43c --discovery-token-ca-cert-hash sha256:f14a90d7c142aa79486e69603d00145d41a8a4517632e31f505a66eabd0e6670
```

## 6. Enable remote kuernetes cluster access from Deploy node
INFO: SKIP this step if Deploy node and Master node are same

```
mkdir -p $HOME/.kube
scp <MASTER_IP>:$HOME/.kube/config $HOME/.kube
chown $(id -u):$(id -g) /root/.kube/config
```

## 7. Docker Compose Installation on Deploy Node
```
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

## 8. Harbor Installation on Deploy Node

```
cat <<EOF | sudo tee /etc/docker/daemon.json
{ "exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts":
{ "max-size": "100m" },
"storage-driver": "overlay2",
"insecure-registries":["192.168.17.108"]
}
EOF

wget https://github.com/goharbor/harbor/releases/download/v2.4.1/harbor-offline-installer-v2.4.1.tgz
tar -zxvf harbor-offline-installer-v2.4.1.tgz
cd harbor
mkdir data_volume
mkdir cert
mv harbor.yml.tmpl harbor.yml
cd /root/
openssl rand -writerand .rnd
cd harbor/cert/
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -sha512 -days 3650 -subj "/C=CN/ST=Guangzhou/L=Guangzhou/O=example/CN=192.168.17.108" -key ca.key -out ca.crt
openssl x509 -inform PEM -in ca.crt -out ca.cert

systemctl daemon-reload
systemctl restart docker
```
### Update below lines in /root/harbor/harbor.yml
```
hostname: 192.168.1.11
comment line 8,10 => http port:80
certificate: /root/harbor/cert/ca.crt #line number: 17
private_key: /root/harbor/cert/ca.key #line number: 18
harbor_admin_password: Harbor12345
data_volume: /root/harbor/data_volume/
```

### install harbor
```
cd /root/harbor/
./install.sh
docker login -uadmin -pHarbor@12345 192.168.17.108
kubectl create secret docker-registry harbor --docker-server=https://192.168.17.108 --docker-username=admin --docker-password=Harbor@12345
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "harbor"}]}'
```

## 9. Harbor Configuration on Worker Nodes
```
cat <<EOF | tee /etc/docker/daemon.json
{
"insecure-registries":["192.168.17.108"]
}
EOF

systemctl daemon-reload
systemctl restart docker
```

## 10 Helm Installation on Deploy Node
```
wget -N https://get.helm.sh/helm-v3.8.0-linux-amd64.tar.gz
tar -zxvf helm-v3.8.0-linux-amd64.tar.gz
cp ./linux-amd64/helm /usr/local/bin/
helm version
```

## 11 NFS Installation

### 11.1 NFS Server on Storage Node
```
apt-get install nfs-kernel-server 
mkdir -p /edgegallery/data/
chmod -R 755 /edgegallery/data/
vim /etc/exports
/edgegallery/data/ 192.168.17.108/32(rw,no_root_squash,sync)
systemctl restart nfs-kernel-server
exportfs -v
```

### 11.2 NFS provisioner on Deploy Node
```
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=192.168.17.108 --set nfs.path=/edgegallery/data/
```

## 12 Generate Certificates on Deploy Node
```
docker pull swr.cn-north-4.myhuaweicloud.com/edgegallery/deploy-tool:latest
export CERT_VALIDITY_IN_DAYS=365
env="-e CERT_VALIDITY_IN_DAYS=$CERT_VALIDITY_IN_DAYS"
mkdir /root/keys/
docker run $env -v /root/keys:/certs  -e CERT_PASSWORD=te9Fmv%qaq  swr.cn-north-4.myhuaweicloud.com/edgegallery/deploy-tool:latest
```

## 13 Create Controller kubernetes Secrets on Deploy Node
```
kubectl create secret generic edgegallery-ssl-secret --from-file=keystore.p12=/root/keys/keystore.p12 --from-file=keystore.jks=/root/keys/keystore.jks  --from-literal=keystorePassword=te9Fmv%qaq  --from-literal=keystoreType=PKCS12 --from-literal=keyAlias=edgegallery --from-literal=truststorePassword=te9Fmv%qaq  --from-file=trust.cer=/root/keys/ca.crt --from-file=server.cer=/root/keys/tls.crt --from-file=server_key.pem=/root/keys/encryptedtls.key  --from-literal=cert_pwd=te9Fmv%qaq

kubectl create secret generic user-mgmt-jwt-secret --from-file=publicKey=/root/keys/rsa_public_key.pem --from-file=encryptedPrivateKey=/root/keys/encrypted_rsa_private_key.pem --from-literal=encryptPassword=te9Fmv%qaq

openssl req -x509 -sha256 -nodes -days 730 -newkey rsa:1024 -passout pass:te9Fmv%qaq -keyout privatekey.pem -out cert.pem -subj /C=CN/ST=Beijing/L=Biejing/O=edgegallery/CN=edgegallery.org -addext "keyUsage = critical,digitalSignature, nonRepudiation,  keyEncipherment, dataEncipherment, keyAgreement, keyCertSign, cRLSign, encipherOnly, decipherOnly" -addext  "extendedKeyUsage = critical,1.3.6.1.5.5.7.3.1, 1.3.6.1.5.5.7.3.2, 1.3.6.1.5.5.7.3.3, 1.3.6.1.5.5.7.3.4, 1.3.6.1.5.5.7.3.8, 1.3.6.1.4.1.311.2.1.21, 1.3.6.1.4.1.311.2.1.22, 1.3.6.1.4.1.311.10.3.1, 1.3.6.1.4.1.311.10.3.3, 1.3.6.1.4.1.311.10.3.4, 2.16.840.1.113730.4.1, 1.3.6.1.4.1.311.10.3.4.1, 1.3.6.1.5.5.7.3.5, 1.3.6.1.5.5.7.3.6, 1.3.6.1.5.5.7.3.7, 1.3.6.1.5.5.8.2.2, 1.3.6.1.4.1.311.20.2.2"

openssl pkcs12 -passout pass:te9Fmv%qaq -export -out public.p12 -inkey privatekey.pem -in cert.pem

openssl x509 -outform der -in cert.pem -out public.cer

kubectl create secret generic edgegallery-signature-secret --from-file=sign_p12=public.p12 --from-file=sign_cer=public.cer --from-literal=certPwd=te9Fmv%qaq

kubectl create secret generic eg-view-ssl-secret --from-file=server.crt=/root/keys/server.crt --from-file=server.key=/root/keys/server.key

kubectl create secret generic developer-ssl-cert --from-file=server.crt=/root/keys/server.crt --from-file=server.key=/root/keys/server.key
```

## 14 Create Edge kubernetes Secrets on Deploy Node
```
kubectl create secret generic mecm-mepm-ssl-secret --from-file=server_tls.key=/root/keys/tls.key --from-file=server_tls.crt=/root/keys/tls.crt --from-file=ca.crt=/root/keys/ca.crt

kubectl create secret generic mecm-mepm-jwt-public-secret --from-file=publicKey=/root/keys/rsa_public_key.pem

mkdir /root/mep_key;     cd /root/;     openssl rand -writerand .rnd   ;  cd /root/mep_key
openssl genrsa -out ca.key 2048 2>&1 >/dev/null
openssl req -new -key ca.key -subj /C=CN/ST=Beijing/L=Beijing/O=edgegallery/CN=edgegallery -out ca.csr 2>&1 >/dev/null
openssl x509 -req -days 365 -in ca.csr -extensions v3_ca -signkey ca.key -out ca.crt 2>&1 >/dev/null

kubectl create ns mep
openssl genrsa -out mepserver_tls.key 2048 2>&1 >/dev/null
openssl rsa -in mepserver_tls.key -aes256 -passout pass:te9Fmv%qaq -out mepserver_encryptedtls.key 2>&1 >/dev/null
echo -n te9Fmv%qaq > mepserver_cert_pwd 2>&1 >/dev/null
openssl req -new -key mepserver_tls.key -subj /C=CN/ST=Beijing/L=Beijing/O=edgegallery/CN=edgegallery -out mepserver_tls.csr 2>&1 >/dev/null
openssl x509 -req -days 365 -in mepserver_tls.csr -extensions v3_req -CA ca.crt -CAkey ca.key -CAcreateserial -out mepserver_tls.crt 2>&1 >/dev/null
openssl genrsa -out jwt_privatekey 2048 2>&1 >/dev/null
openssl rsa -in jwt_privatekey -pubout -out jwt_publickey 2>&1 >/dev/null
openssl rsa -in jwt_privatekey -aes256 -passout pass:te9Fmv%qaq -out jwt_encrypted_privatekey 2>&1 >/dev/null

kubectl -n mep create secret generic pg-secret --from-literal=pg_admin_pwd=admin-Pass123 --from-literal=kong_pg_pwd=kong-Pass123 --from-file=server.key=mepserver_tls.key --from-file=server.crt=mepserver_tls.crt

kubectl -n mep create secret generic mep-ssl --from-literal=root_key="$(openssl rand -base64 256 | tr -d '\n' | tr -dc '[[:alnum:]]' | cut -c -256)" --from-literal=cert_pwd=te9Fmv%qaq --from-file=server.cer=mepserver_tls.crt --from-file=server_key.pem=mepserver_encryptedtls.key --from-file=trust.cer=ca.crt

kubectl -n mep create secret generic mepauth-secret --from-file=server.crt=mepserver_tls.crt --from-file=server.key=mepserver_tls.key --from-file=ca.crt=ca.crt --from-file=jwt_publickey=jwt_publickey  --from-file=jwt_encrypted_privatekey=jwt_encrypted_privatekey

kubectl create ns metallb-system

kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
```
## 15 Update EdgeGallery values.yaml on Deploy Node
```
cd /root
cp /root/installer/EdgeGallery_online_install/edgegallery-values.yaml /root
sed -i 's/192.168.1.11/192.168.17.108/g' /root/edgegallery-values.yaml
```

## 16 Deploy Controller components from Deploy Node
```
helm install service-center-edgegallery helm-charts/service-center -f edgegallery-values.yaml

helm install user-mgmt-edgegallery   helm-charts/user-mgmt  -f    edgegallery-values.yaml --set  global.oauth2.clients.appstore.clientSecret=te9Fmv%qaq --set  global.oauth2.clients.developer.clientSecret=te9Fmv%qaq --set  global.oauth2.clients.mecm.clientSecret=te9Fmv%qaq --set  global.oauth2.clients.atp.clientSecret=te9Fmv%qaq --set  global.oauth2.clients.edgegallery.clientSecret=te9Fmv%qaq --set  postgres.password=te9Fmv%qaq --set  redis.password=te9Fmv%qaq

helm install appstore-edgegallery  helm-charts/appstore  -f   edgegallery-values.yaml --set global.oauth2.clients.appstore.clientSecret=te9Fmv%qaq --set appstoreBe.secretName=edgegallery-signature-secret --set appstoreBe.dockerRepo.endpoint=192.168.17.108 --set appstoreBe.dockerRepo.appstore.password=Harbor@12345 --set appstoreBe.dockerRepo.appstore.username=admin --set appstoreBe.dockerRepo.developer.password=Harbor@12345 --set appstoreBe.dockerRepo.developer.username=admin --set appstoreBe.hostPackagesPath=/edgegallery/appstore/packages --set appstoreBe.appdtranstool.enabled=true --set appstoreBe.fileSystemAddress=http://192.168.17.108:30090 --set postgres.password=te9Fmv%qaq

helm install developer-edgegallery   helm-charts/developer  -f  edgegallery-values.yaml --set global.oauth2.clients.developer.clientSecret=te9Fmv%qaq --set developer.dockerRepo.endpoint=192.168.17.108 --set developer.dockerRepo.password=Harbor@12345 --set developer.dockerRepo.username=admin --set postgres.password=te9Fmv%qaq --set developer.developerBeIp=192.168.17.108 --set developer.vmImage.fileSystemAddress=http://192.168.17.108:30090  --set developer.toolChain.enabled=false --set developer.ssl.certName=developer-ssl-cert

kubectl apply -f installer/ansible_package/roles/k8s/files/metric-server.yaml

helm install mecm-meo-edgegallery   helm-charts/mecm-meo   -f   edgegallery-values.yaml --set global.oauth2.clients.mecm.clientSecret=te9Fmv%qaq --set mecm.docker.fsgroup=$(getent group docker | cut -d: -f3) --set mecm.docker.dockerRepoUserName=admin --set mecm.docker.dockerRepopassword=Harbor@12345 --set mecm.repository.dockerRepoEndpoint=192.168.17.108 --set mecm.repository.sourceRepos="repo=192.168.17.108 userName=admin password=Harbor@12345" --set mecm.postgres.postgresPass=te9Fmv%qaq --set mecm.postgres.inventoryDbPass=te9Fmv%qaq --set mecm.postgres.northDbPass=te9Fmv%qaq --set mecm.postgres.appoDbPass=te9Fmv%qaq --set mecm.postgres.apmDbPass=te9Fmv%qaq

helm install atp-edgegallery helm-charts/atp -f edgegallery-values.yaml --set global.oauth2.clients.atp.clientSecret=te9Fmv%qaq --set postgres.password=te9Fmv%qaq
helm install file-system-edgegallery helm-charts/file-system --set filesystem.hostVMImagePath=/edgegallery/filesystem/images --set postgres.password=te9Fmv%qaq -f edgegallery-values.yaml
helm install healthcheck-edgegallery helm-charts/healthcheck --set healthcheck.localIp=192.168.17.108  -f edgegallery-values.yaml
helm install healthcheck-m-edgegallery   helm-charts/healthcheck-m  --set healthcheckm.localIp=192.168.17.108  -f edgegallery-values.yaml
helm install edgegallery-fe helm-charts/edgegallery-fe  --set global.oauth2.clients.edgegalleryFe.clientSecret=te9Fmv%qaq -f edgegallery-values.yaml
helm install third-system-edgegallery helm-charts/third-system --set postgres.password=te9Fmv%qaq -f edgegallery-values.yaml
```

## 17 Deploy Edge components from Deploy Node
```
kubectl apply -f installer/ansible_package/roles/init/files/conf/manifest/mepm/mepm-service-account.yaml

cd /root
wget https://github.com/kubernetes/ingress-nginx/releases/download/helm-chart-4.0.17/ingress-nginx-4.0.17.tgz

kubectl apply -f installer/ansible_package/roles/init/files/conf/manifest/mepm/mepm-service-account.yaml

helm install  eg-ingress  ingress-nginx-4.0.17.tgz --set controller.service.type=NodePort --set controller.service.nodePorts.http=30102 --set controller.service.nodePorts.https=31252 -f installer/ansible_install/roles/mecm-mepm/files/ingress.yaml

Handle below points in helm-charts/mecm-mepm/templates/mepm-ingress/mepm-ingress.yaml
v1 - service name port number
pathType: Prefix

helm install mecm-mepm-edgegallery helm-charts/mecm-mepm  -f  edgegallery-values.yaml --set jwt.publicKeySecretName=mecm-mepm-jwt-public-secret --set ssl.secretName=mecm-mepm-ssl-secret --set mepm.postgres.postgresPass=te9Fmv%qaq --set mepm.postgres.lcmcontrollerDbPass=te9Fmv%qaq --set mepm.postgres.k8spluginDbPass=te9Fmv%qaq --set mepm.postgres.ospluginDbPass=te9Fmv%qaq --set mepm.postgres.apprulemgrDbPass=te9Fmv%qaq --set mepm.postgres.mepmtoolsDbPass=te9Fmv%qaq --set mepm.filesystem.imagePushUrl=http://192.168.17.108:30090/image-management/v1/images  --set images.commonWebssh.tag=latest

kubectl apply -f installer/EdgeGallery_online_install/metallb/namespace.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl apply -f installer/EdgeGallery_online_install/metallb/metallb.yaml
kubectl apply -f installer/EdgeGallery_online_install/metallb/config-map.yaml

ip link add eg-mp1 link ens3 type macvlan mode bridge
ip addr add 200.1.1.2/24 dev eg-mp1
ip link set dev eg-mp1 up
ip link add eg-mm5 link ens3 type macvlan mode bridge
ip addr add 100.1.1.2/24 dev eg-mm5
ip link set dev eg-mm5 up

mkdir -p /etc/network/interfaces.d/
cp installer/EdgeGallery_online_install/eg-if.cfg  /etc/network/interfaces.d/
cd installer/ansible_package/roles/init/files/conf/edge/network-isolation

Modify the image name: 
swr.cn-north-4.myhuaweicloud.com/eg-common/nfvpe/multus:stable
kubectl apply -f multus.yaml
kubectl apply -f eg-sp-rbac.yaml

sed -i 's?image: edgegallery/edgegallery-secondary-ep-controller:latest?image: swr.cn-north-4.myhuaweicloud.com/edgegallery/edgegallery-secondary-ep-controller:v1.3.0?g' eg-sp-controller.yaml
kubectl apply -f eg-sp-controller.yaml

mkdir -p /root/cni
cd /root/cni
curl -LO https://github.com/containernetworking/plugins/releases/download/v0.8.7/cni-plugins-linux-amd64-v0.8.7.tgz
tar -xzvf cni-plugins-linux-amd64-v0.8.7.tgz
cp macvlan /opt/cni/bin
cp host-local /opt/cni/bin

cd /root
helm install mep-edgegallery helm-charts/mep -f edgegallery-values.yaml --set networkIsolation.ipamType=host-local --set networkIsolation.phyInterface.mp1=ens3 --set networkIsolation.phyInterface.mm5=ens3 --set ssl.secretName=mep-ssl --set postgres.kongPass=te9Fmv%qaq --set mepauthProperties.jwtPrivateKey=te9Fmv%qaq --set postgres.kongPass=kong-Pass123
```
