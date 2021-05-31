set -e

# Prepare MEP SSL

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

chmod 600 -R $MEP_CERTS_DIR
