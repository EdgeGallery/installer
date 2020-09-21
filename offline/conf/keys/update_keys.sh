#!/bin/bash
######################################################################################
# Copyright (c) 2019 Huawei Tech and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
#######################################################################################
KEYS_DIR=$PWD
rm -rf /tmp/ssl-eg-keys-certs
mkdir -p /tmp/ssl-eg-keys-certs
cd /tmp/ssl-eg-keys-certs || exit

## Generate a RSA keypair through openssl
openssl genrsa -out rsa_private_key.pem 2048
openssl rsa -in rsa_private_key.pem -pubout -out rsa_public_key.pem
openssl pkcs8 -topk8 -inform PEM -in rsa_private_key.pem -outform PEM -passout pass:te9Fmv%qaq -out encrypted_rsa_private_key.pem

## Generate ca certificate
openssl genrsa -out ca.key 2048
openssl req -new -key ca.key -subj /C=CN/ST=Beijing/L=Biejing/O=edgegallery/CN=edgegallery.org -out ca.csr
openssl x509 -req -days 365 -in ca.csr -extensions v3_ca -signkey ca.key -out ca.crt

## Generate tls certificate
openssl genrsa -out tls.key 2048
openssl rsa -in tls.key -aes256 -passout pass:te9Fmv%qaq -out encryptedtls.key
openssl req -new -key tls.key -subj /C=CN/ST=Beijing/L=Biejing/O=edgegallery/CN=edgegallery.org -out tls.csr
openssl x509 -req -in tls.csr -extensions v3_usr -CA ca.crt -CAkey ca.key -CAcreateserial -out tls.crt

## Generate a keystore.p12 through keytool
keytool -genkey -alias edgegallery \
  -dname "CN=edgegallery,OU=edgegallery,O=edgegallery,L=edgegallery,ST=edgegallery,C=CN" \
  -storetype PKCS12 -keyalg RSA -keysize 2048 -storepass te9Fmv%qaq -keystore keystore.p12 -validity 365

yes yes | keytool -importcert -file ca.crt -alias clientkey -keystore keystore.jks -storepass te9Fmv%qaq

rm ca.csr ca.key ca.srl tls.csr

cp -r /tmp/ssl-eg-keys-certs/* $KEYS_DIR
rm -rf /tmp/ssl-eg-keys-certs/
exit 0