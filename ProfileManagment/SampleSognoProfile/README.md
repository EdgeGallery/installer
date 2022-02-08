## Sogno Profile Management

Change following password

1. fledge-adapter deploy env variable
```
name: MQTT_RABBITMQ_PWD
value: admin
```
2. rabbitmq secret password
```
data:
rabbitmq-password: "YWRtaW4="
rabbitmq-erlang-cookie: "OXpiUlk1am1hamlKbzhaN01Hckw2RTVKUWhRR3dseGs="
```
3. rabbitmq statefulSet checksum
```
annotations:
checksum/config: 4b27bf3c075f314afe9dca0c855be147aa1ab55db4669e844c4b354e8eedd2e5
checksum/secret: a013c000f1e0908094ed163d6263f22a9b6db3ec259795b7846cd1d7eb5a99cd
```
4. pyvolt demo secret
```
data:
mqtt_user: "YWRtaW4="
mqtt_pwd: "YWRtaW4="
```
5. rabbitmq.conf
```
default_user = admin
default_pass = CHANGEME
```