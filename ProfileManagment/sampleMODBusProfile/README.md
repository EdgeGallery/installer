# ModBus profile

## Sample End To End profile use case scenario with grafana as application.
Profile has Fledge as protocol adapter, kuiper as ETL(Extract, transform and load) and tdengine as DB store.
- user can select modbus profile and deploy it from Edgegallery Dev portal.
- It will start Mod bus master in fledge and wait for slave device to connect and get data.
- Once ModBus device is started, fledge will get device data and publish at "fledge" topic
- This device data will be parse/transform by Kuiper and publish at "kuiper" topic
- next this filterd data is stored in TDEngine DB
- data visualization can be done by grafana.
- for this, open grafana url "http://NodeIP:32300" with default user name and password admin/admin
- user can change the passowrd if required here
- now configure tdengine as data source with "tdengine" service name and port "6041" in source url
- create a panel for ur device and add below query: "select * from iotdb.ModbusDev;"
- user can see his device data

 User application can get data from this profile either from tdengine as above steps OR it can get data from flegde or kuiper topic based on use case.
 
## ModBus Device simulator
For testing, pymodbus tcp simultor can be used as modbus slave device
Below is referene links
https://sourceforge.net/projects/pymodslave/

#pyModSlave
pyModSlave is a free python-based implementation of a ModBus slave application for simulation purposes.

It starts a TCP/RTU ModBus Slave.
Builds 4 data blocks (coils,discrete inputs,input registers,holding registers) and sets random values. 
You can also set values for individual registers.

We can find details about this simulator:
- install pymodbus "pip install pyModSlave"
- downlaod tar file for slave code form "https://pypi.org/project/pyModSlave/#files"
- untar the zip file
```sh
cd pyModSlave-code-0.4.3-2
sudo python3 pyModSlave.py
```
- this is pop up a window for device simultor.
- we can configure tcp ip and port as "127.0.0.1" and "502"
- enable sim button for all 4 registers, to start generating values by simulator
- now press connect button to start connection and sending readings.
- at this stage, fledge will starting getting data from modbus simulator devices and same can be verify in fledge GUI if needed. 
