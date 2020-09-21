## EdgeGallery Ingress deployment
1. See [Required configurations for edgegallery Ingress](https://github.com/EdgeGallery/helm-charts#ingress) to get to know the required configurations
2. Update the values of `auth_domain,appstore_domain,developer_domain,mecm_domain,tls_enabled,tls_secretName`
in `platform-mgmt/utilities/env.sh` file according to helm chart configurations seen in step 1.
3. Check the [preconditions](../README.md#preconditions)
4. Use below sections to perform edgegallery ingress deployment

## EdgeGallery Ingress deployment using cli
Before trying below cli commands, build cli using [Build & RUn Cli](deploy_edgegallery_with_cli.md#build--run-cli) section and comeback.

**Install EdgeGallery in Ingress mode.**
```
edgegallery init all --expose-type=ingress
```
**UnInstall EdgeGallery in Ingress mode.**
```
edgegallery stop all --expose-type=ingress
```

## EdgeGallery Ingress deployment using bash script
**Install EdgeGallery in Ingress mode.**
```
bash one_click_deploy.sh -i all --expose-type=ingress
```
**UnInstall EdgeGallery in Ingress mode.**
```
bash one_click_deploy.sh -r all --expose-type=ingress
```