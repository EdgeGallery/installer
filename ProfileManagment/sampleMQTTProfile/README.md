### Profile Management Architecture



### Prerequisites
- Docker
- Docker-Compose

### Usage
1. Bring up all related docker container

`docker-compose up -d`

2. configure the related components 

`sh ./iot_config.sh`

3.  Now you can check the fledge installation successfully or not

`fledge-ui: http://x.x.x.x:8080`

4. simulate ~1000 mqtt devices

`sudo docker run -it --network profilemanagement_app-network libujacob/mqtt-device`

5. Demo: Using Grafana

`Grafana Portal: http://x.x.x.x:3000`

6. Configure the DataSouce as TDEngine

`TDEngine server: http://td-engine:6041 User: <Empty> Password: <Empty>`

7. Create New Dashboard and Panel for it

`Select * from iotdb.meters`