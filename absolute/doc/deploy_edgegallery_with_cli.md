## Deploy EdgeGallery using OneClickDeployment CLI

1. Check the [preconditions](../README.md#preconditions)

### Build & run CLI
```
1. Go to the CLI directory
   platform-mgmt/utilities/cli/
2. build CLI
   source build_cli.sh
3. Comeback to platform-mgmt directory
   cd platform-mgmt/
4. run CLI by "edgegallery"
```
**Note:** All CLI commands should be given inside **platform-mgmt** directory

### CLI commands to deploy EdgeGallery
**Note:** In case of module level deployment on Controller Prefer to install service-center,tool-chain,user-mgmt first as other modules have dependancy on these modules

**Install EdgeGallery.**
```
edgegallery init all
```
**Uninstall EdgeGallery.**
```
edgegallery stop all
```
**Install EdgeGallery's Edge Node.**
```
edgegallery init edge
```
**Uninstall EdgeGallery's Edge Node.**
```
edgegallery stop edge
```
**Install EdgeGallery's Controller Node.**
```
edgegallery init controller
```
**Uninstall EdgeGallery's Controller Node.**
```
edgegallery stop controller
```
**Install EdgeGallery's Infrastructure.**
```
edgegallery init infra
```
**Uninstall EdgeGallery's Infrastructure.**
```
edgegallery stop infra
```
**Install MEP on the edge nodes listed in nodelist.ini.**
```
edgegallery init mep
```
**Uninstall MEP on the edge nodes listed in nodelist.ini.**
```
edgegallery stop mep
```
**Install AppLcm on EdgeGallery's Edge Nodes.**
```
edgegallery init applcm
```
**Uninstall AppLcm on EdgeGallery's Edge Nodes.**
```
edgegallery stop applcm
```
**Install service-center on the edge nodes listed in nodelist.ini.**
```
edgegallery init service-center
```
**Uninstall service-center on the edge nodes listed in nodelist.ini.**
```
edgegallery stop service-center
```
**Install tool-chain on the edge nodes listed in nodelist.ini.**
```
edgegallery init tool-chain
```
**Uninstall tool-chain on the edge nodes listed in nodelist.ini.**
```
edgegallery stop tool-chain
```
**Install user-mgmt on the edge nodes listed in nodelist.ini.**
```
edgegallery init user-mgmt
```
**Uninstall user-mgmt on the edge nodes listed in nodelist.ini.**
```
edgegallery stop user-mgmt
```
**Install MECM on the controller node listed in nodelist.ini.**
```
edgegallery init mecm
```
**uninstall MECM on the controller node listed in nodelist.ini.**
```
edgegallery stop mecm
```
**Install appstore on the edge nodes listed in nodelist.ini.**
```
edgegallery init appstore
```
**Uninstall appstore on the edge nodes listed in nodelist.ini.**
```
edgegallery stop appstore
```
**Install developer on the edge nodes listed in nodelist.ini.**
```
edgegallery init developer
```
**Uninstall developer on the edge nodes listed in nodelist.ini.**
```
edgegallery stop developer
```

## Verification of EdgeGallery Deployment
Verify the deployment by following [verification-of-edgegallery-deployment](../README.md#verification-of-edgegallery-deployment)
