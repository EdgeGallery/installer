set -e

function wait_for_file() {
  loop=1
  while true
  do
    if [[ $loop -gt 5 ]]; then
      echo "Timeout of waiting for file $1 is ready"
      break
    else
      if [ ! -f $1 ]; then
        echo "loop $loop: waiting for $1 is ready"
        sleep 2
        loop=$((loop+1))
      else
        break
      fi
    fi
  done
}

echo "==========Install MEP=========="
# Prepare MEP SSL
curPath=$(dirname $(readlink -f "$0"))
MEP_CERTS_DIR=/tmp/.mep_tmp_cer
rm -rf $MEP_CERTS_DIR
mkdir -p $MEP_CERTS_DIR
cd $MEP_CERTS_DIR

openssl genrsa -out ca.key 2048
openssl req -new -key ca.key -subj /C=CN/ST=Peking/L=Beijing/O=edgegallery/CN=edgegallery -out ca.csr
openssl x509 -req -days 365 -in ca.csr -extensions v3_ca -signkey ca.key -out ca.crt
openssl genrsa -out mepserver_tls.key 2048
openssl rsa -in mepserver_tls.key -aes256 -passout pass:te9Fmv%qaq -out mepserver_encryptedtls.key
openssl req -new -key mepserver_tls.key -subj /C=CN/ST=Beijing/L=Beijing/O=edgegallery/CN=edgegallery -out mepserver_tls.csr
openssl x509 -req -days 365 -in mepserver_tls.csr -extensions v3_req -CA ca.crt -CAkey ca.key -CAcreateserial -out mepserver_tls.crt
openssl genrsa -out jwt_privatekey 2048
openssl rsa -in jwt_privatekey -pubout -out jwt_publickey
openssl rsa -in jwt_privatekey -aes256 -passout pass:te9Fmv%qaq -out jwt_encrypted_privatekey

chmod 644 -R $MEP_CERTS_DIR

MEP_ROOT_KEY=`openssl rand -base64 256 | tr -d '\n' | tr -dc '[[:alnum:]]' | cut -c -256`
export MEP_ROOT_KEY=$MEP_ROOT_KEY

cd $curPath/mep
docker-compose up -d

echo "==========Install MEPM=========="

if [ ! -f /tmp/keys/rsa_public_key.pem ]; then
  cd $curPath/setup
  docker-compose up -d
  wait_for_file /tmp/keys/rsa_public_key.pem
fi

export ENV_IP=$1
export JWT_PUBLIC_KEY=`cat /tmp/keys/rsa_public_key.pem`

cd $curPath/mepm
sed -i "s/mep-mm5.mep:80/$ENV_IP:8088/g" mepm-fe-data/nginx.conf
docker-compose up -d
