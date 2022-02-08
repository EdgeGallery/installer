# DNPv3 profile

## Sample End To End profile use case scenario with grafana as application.
Profile has Fledge as protocol adapter, kuiper as ETL(Extract, transform and load) and tdengine as DB store.
- user can select DNPv3 profile and deploy it from Edgegallery Dev portal.
- It will start dnp server in fledge and wait for slave device to connect and get data.
- Once dnp device is started, fledge will get device data and publish at "fledge" topic
- This device data will be parse/transform by Kuiper and publish at "kuiper" topic
- next this filterd data is stored in TDEngine DB
- data visualization can be done by grafana.
- for this, open grafana url "http://NodeIP:32300" with default user name and password admin/admin
- user can change the passowrd if required here
- now configure tdengine as data source with "tdengine" service name and port "6041" in source url
- create a panel for ur device and add below query: "select * from iotdb.dnp3_01;"
- user can see his device data

 User application can get data from this profile either from tdengine as above steps OR it can get data from flegde or kuiper topic based on use case.
 
## DNPv3 Device simulator
opendnp3 Device(client) simulator.
Building opendnp3 from code:
To build opendnp3 clone the opendnp3 repository to a directory of your choice. The branch name is release-2.x

$ git clone --recursive -b release-2.x https://github.com/dnp3/opendnp3.git
$ cd opendnp3
$ export OPENDNP3_LIB_DIR=`pwd`
$ mkdir build
$ cd build
$ cmake -DSTATICLIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DDNP3_DEMO=ON ..
$ make

cd build
sudo ./outstation-demo


Test with Fledge###
now provide input
This demo application listens on any IP address, port 20001 and has link Id set to 10. 
It also assumes master link Id is 1.
Same config can be set in fledge dnp3 plugin.

Once started it logs traffic and wait for use input for sending unsolicited messages:

Enter one or more measurement changes then press <enter>
c = counter, b = binary, d = doublebit, a = analog, o = octet string, 'quit' = exit

for test fledge: enter c, and it will send one reading to fledge like below:
asset: dnp3_01remote_10_counter_0; Timestamp:**** ; readings: {"count0": 1}


reference steps:
https://github.com/fledge-iot/fledge-south-dnp3
