#!/bin/bash
#
#   Copyright 2021 Huawei Technologies Co., Ltd.
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

#!/bin/bash

set -e

echo "preparing ssl certs"

mkdir -p /tmp/ssl-eg-keys-certs
cd /tmp/ssl-eg-keys-certs
openssl genrsa -out rsa_private_key.pem 2048
openssl rsa -in rsa_private_key.pem -pubout -out rsa_public_key.pem
openssl pkcs8 -topk8 -inform PEM -in rsa_private_key.pem -outform PEM -passout pass:$CERT_PASSWORD -out encrypted_rsa_private_key.pem
openssl genrsa -out ca.key 2048
openssl req -new -key ca.key -subj /C=CN/ST=Beijing/L=Biejing/O=edgegallery/CN=edgegallery.org -out ca.csr
openssl x509 -req -days $CERT_VALIDITY_IN_DAYS -in ca.csr -extensions v3_ca -signkey ca.key -out ca.crt
openssl genrsa -out tls.key 2048
openssl rsa -in tls.key -aes256 -passout pass:$CERT_PASSWORD -out encryptedtls.key
openssl req -new -key tls.key -subj /C=CN/ST=Beijing/L=Biejing/O=edgegallery/CN=edgegallery.org -out tls.csr
openssl x509 -req -days $CERT_VALIDITY_IN_DAYS -in tls.csr -extensions v3_usr -CA ca.crt -CAkey ca.key -CAcreateserial -out tls.crt
keytool -genkey -alias edgegallery \
  -dname "CN=edgegallery,OU=edgegallery,O=edgegallery,L=edgegallery,ST=edgegallery,C=CN" \
  -storetype PKCS12 -keyalg RSA -keysize 2048 -storepass $CERT_PASSWORD -keystore keystore.p12 -validity $CERT_VALIDITY_IN_DAYS
yes yes | keytool -importcert -file ca.crt -alias clientkey -keystore keystore.jks -storepass $CERT_PASSWORD
openssl pkcs12 -in keystore.p12 -nokeys -clcerts -out server.crt -passin pass:$CERT_PASSWORD
openssl pkcs12 -nocerts -nodes -in keystore.p12 -out server.key -passin pass:$CERT_PASSWORD
rm ca.csr ca.key ca.srl tls.csr
cp -r /tmp/ssl-eg-keys-certs/* /certs
rm -rf /tmp/ssl-eg-keys-certs/
