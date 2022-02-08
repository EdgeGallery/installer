# CSV profile

## Sample End To End profile use case scenario with grafana as application.
Profile has Fledge as protocol adapter, kuiper as ETL(Extract, transform and load) and tdengine as DB store.
- user can select CSV profile and deploy it from Edgegallery Dev portal.
- It will start csv file reader  in fledge and wait for slave device to connect and get data.
- Once dnp device is started, fledge will get device data and publish at "fledge" topic
- This device data will be parse/transform by Kuiper and publish at "kuiper" topic
- next this filterd data is stored in TDEngine DB
- data visualization can be done by grafana.
- for this, open grafana url "http://NodeIP:32300" with default user name and password admin/admin
- user can change the passowrd if required here
- now configure tdengine as data source with "tdengine" service name and port "6041" in source url
- create a panel for ur device and add below query: "select * from iotdb.sensor;"
- user can see his device data

 User application can get data from this profile either from tdengine as above steps OR it can get data from flegde or kuiper topic based on use case.
 
## CSV Device simulator
CSV Device simulator:
for CSV based devices, It read data from csv file.
This particular CSV reader support single CSV file, without timestamps in the file. It assumes every value is a data value. 
It will read data from the file up until a newline or a comma character and make that as single data point in an asset and return that.

For example simple csv file may contains below reading:
10

Then profile will prepared reading json, including, Asset name, datapoint with value 10 and time stamp as below:
{"asset":"sensor","temperature":0,"timestamp":"2021-12-27 06:23:58.770802+00:00"}


Testing:
For test csv profile, 
1. A test csv file need to be present in host vm
2. in IOT csv profile yaml, provide host mapping to fledge pod so that fledge can read this csv file.
3. sample csv file and its config in yaml file has been provided defult.

