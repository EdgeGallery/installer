# OPC-UA profile

## Sample End To End profile use case scenario with grafana as application.
Profile has OPC-UA server, Fledge as protocol adapter, kuiper as ETL(Extract, transform and load) and tdengine as DB store.
- user can select OPC-UA profile and deploy it from Edgegallery Dev portal.
- It will start reading data from opcua server "opc.tcp://opcuasrv:4840/freeopcua/server/" for opcua device "'ns=5;s=sensor0'"   in fledge and wait for opcua deice client to connect and get data.
- Once opcua device is started, fledge will get device data and publish at "fledge" topic
- This device data will be parse/transform by Kuiper and publish at "kuiper" topic
- next this filterd data is stored in TDEngine DB
- data visualization can be done by grafana.
- for this, open grafana url "http://NodeIP:32300" with default user name and password admin/admin
- user can change the passowrd if required here
- now configure tdengine as data source with "tdengine" service name and port "6041" in source url
- create a panel for ur device and add below query: "select * from iotdb.sensor;"
- user can see his device data

 User application can get data from this profile either from tdengine as above steps OR it can get data from flegde or kuiper topic based on use case.
 
## OPC-UA Client Device simulator
we can use opcua sample client code from below git
git clone https://github.com/FreeOpcUa/python-opcua.git
go to example folder and use client-minimal.py file for client code.

change this file as below:
we can configure opcua server details in client as below:
opc.tcp://0.0.0.0:31840/freeopcua/server/

add below code for send data:
        # add new device to opcua server
        objects = client.get_objects_node()
        folder = objects.add_folder("ns=22;i=3007", "2:Folder2")
        var = folder.add_variable("ns=5;s=sensor0", "2:Variable3", 3)
        var.set_value(9.89) # just to check it works
        myvar = client.get_node("ns=5;s=sensor0")
        while True:
            counttmp += 1
            myvar.set_value(counttmp)

once changes are done, run this file:
python3 ./client_deleting.py
