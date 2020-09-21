## Deploy EdgeGallery using OneClickDeployment shell script

1. Check the [preconditions](../README.md#preconditions)

2. Go to the main directory & use use following commands
cd platform-mgmt/

**Install EdgeGallery.**
```
bash one_click_deploy.sh -i all
```
**Uninstall EdgeGallery.**
```
bash one_click_deploy.sh -r all
```
**Install EdgeGallery's Edge Node.**
```
bash one_click_deploy.sh -i edge
```
**Uninstall EdgeGallery's Edge Node.**
```
bash one_click_deploy.sh -r edge
```
**Install EdgeGallery's Controller Node.**
```
bash one_click_deploy.sh -i controller
```
**Uninstall EdgeGallery's Controller Node.**
```
bash one_click_deploy.sh -r controller
```
**Install EdgeGallery's Infrastructure.**
```
bash one_click_deploy.sh -i infra
```
**Uninstall EdgeGallery's Infrastructure.**
```
bash one_click_deploy.sh -r infra
```
**Install MEP on the edge nodes listed in nodelist.ini.**
```
bash one_click_deploy.sh -i mep
```
**Uninstall MEP on the edge nodes listed in nodelist.ini.**
```
bash one_click_deploy.sh -r mep
```
**Install AppLcm on EdgeGallery's Edge Nodes.**
```
bash one_click_deploy.sh -i applcm
```
**Uninstall AppLcm on EdgeGallery's Edge Nodes.**
```
bash one_click_deploy.sh -r applcm
```
**Install service-center on the edge nodes listed in nodelist.ini.**
```
bash one_click_deploy.sh -i service-center
```
**Uninstall service-center on the edge nodes listed in nodelist.ini.**
```
bash one_click_deploy.sh -r service-center
```
**Install tool-chain on the edge nodes listed in nodelist.ini.**
```
bash one_click_deploy.sh -i tool-chain
```
**Uninstall tool-chain on the edge nodes listed in nodelist.ini.**
```
bash one_click_deploy.sh -r tool-chain
```
**Install user-mgmt on the edge nodes listed in nodelist.ini.**
```
bash one_click_deploy.sh -i user-mgmt
```
**Uninstall user-mgmt on the edge nodes listed in nodelist.ini.**
```
bash one_click_deploy.sh -r user-mgmt
```
**Install MECM on the controller node listed in nodelist.ini.**
```
bash one_click_deploy.sh -i mecm
```
**uninstall MECM on the controller node listed in nodelist.ini.**
```
bash one_click_deploy.sh -r mecm
```
**Install appstore on the edge nodes listed in nodelist.ini.**
```
bash one_click_deploy.sh -i appstore
```
**Uninstall appstore on the edge nodes listed in nodelist.ini.**
```
bash one_click_deploy.sh -r appstore
```
**Install developer on the edge nodes listed in nodelist.ini.**
```
bash one_click_deploy.sh -i developer
```
**Uninstall developer on the edge nodes listed in nodelist.ini.**
```
bash one_click_deploy.sh -r developer
```

## Verification of the EdgeGallery Deployment
Verify the deployment by following [verification-of-edgegallery-deployment](../README.md#verification-of-edgegallery-deployment)
