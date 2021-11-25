

# 通过代理访问EdgeGallery的配置指南

如果您需要通过代理来访问EdgeGallery，需要按照本文档说明配置代理和EdgeGallery，否则将无法通过代理正常访问EdgeGallery。

## 文档中引用的变量说明

PORTAL_IP：访问EdgeGallery页面的IP地址。

PROXY_IP：代理IP地址。

## 代理配置

EdgeGallery支持两种代理访问模式，Nginx反向代理访问模式与NAT访问模式。本文针对两种模式说明EdgeGallery对代理的配置要求。

### Nginx反向代理配置

针对通过Nginx反向代理访问的场景，EdgeGallery要求按照如下配置来设置路由规则。

```
        location /edgegallery/web/ {
            proxy_pass https://{PORTAL_IP}:30095/; 
        }
        location /edgegallery/usermgmt/ { 
            proxy_pass https://{PORTAL_IP}:30067/;
        }
        location /edgegallery/appstore/ { 
            proxy_pass https://{PORTAL_IP}:30091/; 
        }
        location /edgegallery/developer/ { 
            proxy_pass https://{PORTAL_IP}:30092/; 
        }
        location /edgegallery/mecm/ { 
            proxy_pass https://{PORTAL_IP}:30093/; 
        }
        location /edgegallery/atp/ { 
            proxy_pass https://{PORTAL_IP}:30094/; 
        }
        location /edgegallery/appd/ { 
            proxy_pass https://{PORTAL_IP}:30087/; 
        }
        location /edgegallery/egviewdoc/ { 
            proxy_pass https://{PORTAL_IP}:30089/; 
        }
        location /edgegallery/healthcheck/ { 
            proxy_pass https://{PORTAL_IP}:32757/; 
        }
```

### NAT访问模式

NAT即网络地址转换。EdgeGallery对这种代理模式的配置无要求。

```
说明：仅支持IP转换。
```

## EdgeGallery配置

通过代理访问EdgeGallery，需要在部署EdgeGallery时配置相应的参数。这些参数请在文件`/install/default-var.yml`中进行配置。

```
# Auth Server(即User Management）对应的代理访问地址
AUTH_SERVER_ADDRESS_CLIENT_ACCESS: https://xxx.xxx.xxx.xxx/xx/xx

# EdgeGallery融合前端代理访问地址
EDGEGALLERY_CLIENT_ACCESS_URL: https://xxx.xxx.xxx.xxx/xx/xx
# AppStore子平台前端代理访问地址
APPSTORE_CLIENT_ACCESS_URL: https://xxx.xxx.xxx.xxx/xx/xx
# Developer子平台前端代理访问地址
DEVELOPER_CLIENT_ACCESS_URL: https://xxx.xxx.xxx.xxx/xx/xx
# Mecm子平台前端代理访问地址
MECM_CLIENT_ACCESS_URL: https://xxx.xxx.xxx.xxx/xx/xx
# Atp子平台前端代理访问地址
ATP_CLIENT_ACCESS_URL: https://xxx.xxx.xxx.xxx/xx/xx
```

### Nginx反向代理模式下EdgeGallery配置

```
AUTH_SERVER_ADDRESS_CLIENT_ACCESS: https://{PROXY_IP}/edgegallery/usermgmt

EDGEGALLERY_CLIENT_ACCESS_URL: https://{PROXY_IP}/edgegallery/web
APPSTORE_CLIENT_ACCESS_URL: https://{PROXY_IP}/edgegallery/appstore
DEVELOPER_CLIENT_ACCESS_URL: https://{PROXY_IP}/edgegallery/developer
MECM_CLIENT_ACCESS_URL: https://{PROXY_IP}/edgegallery/mecm
ATP_CLIENT_ACCESS_URL: https://{PROXY_IP}/edgegallery/atp
```

### NAT代理模式下EdgeGallery配置

```
AUTH_SERVER_ADDRESS_CLIENT_ACCESS: https://{PROXY_IP}:30067

EDGEGALLERY_CLIENT_ACCESS_URL: https://{PROXY_IP}:30095
APPSTORE_CLIENT_ACCESS_URL: https://{PROXY_IP}:30091
DEVELOPER_CLIENT_ACCESS_URL: https://{PROXY_IP}:30092
MECM_CLIENT_ACCESS_URL: https://{PROXY_IP}:30093
ATP_CLIENT_ACCESS_URL: https://{PROXY_IP}:30094
```