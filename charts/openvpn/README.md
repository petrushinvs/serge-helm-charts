# openvpn

![Version: 0.4.2](https://img.shields.io/badge/Version-0.4.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.6.8](https://img.shields.io/badge/AppVersion-2.6.8-informational?style=flat-square)

OpenVPN in kubernetes

**Homepage:** <https://github.com/sergelogvinov/helm-charts>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| sergelogvinov |  | <https://github.com/sergelogvinov> |

## Source Code

* <https://github.com/sergelogvinov/helm-charts/tree/master/charts/openvpn>
* <https://openvpn.net>

## Deploy openvpn with users

Cert manager creates a tls secrets and store in kubernetes secretes.
`clientConfigRBAC` sets RBAC policy, it allow to download openvpn config/secrets by users.

```yaml
# helm values
certManager:
  createCerts: true

  clientConfigRBAC: true
  clients:
    - user-1@example.com
    - user-2@example.com

openvpn:
  hostName: vpn.example.com

  config: |
    server 172.30.1.0 255.255.255.0
    topology p2p
    data-ciphers AES-256-GCM:AES-128-GCM
    data-ciphers-fallback AES-256-CBC

  defaultroutes: |
    push "dhcp-option DNS 172.30.1.1"
    push "route 1.1.1.1"
    push "route 8.8.8.8"
```

## Deploy openvpn with users and OTP

As previous example, we will create a tls certs and user configs.
Additionally, we will use OTP (one time password) to login on openvpn.

To create OTP key: `docker run --rm -ti --entrypoint=google-authenticator ghcr.io/sergelogvinov/openvpn:2.5.8-2 -tdfW -r 3 -R 60`

```yaml
# helm values
certManager:
  createCerts: true

  clientConfigRBAC: true
  clients:
    - user-1@example.com
    - user-2@example.com

openvpn:
  hostName: vpn.example.com
  # google-authenticator -tdfW -r 3 -R 60
  otp: PMTYASQTPLU6OKR2

  config: |
    server 172.30.1.0 255.255.255.0
    topology p2p
    data-ciphers AES-256-GCM:AES-128-GCM
    data-ciphers-fallback AES-256-CBC

  defaultroutes: |
    push "dhcp-option DNS 172.30.1.1"
    push "route 1.1.1.1"
    push "route 8.8.8.8"
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| replicaCount | int | `1` |  |
| image.repository | string | `"ghcr.io/sergelogvinov/openvpn"` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.tag | string | `""` |  |
| imagePullSecrets | list | `[]` |  |
| nameOverride | string | `""` |  |
| fullnameOverride | string | `""` |  |
| certManager.createCerts | bool | `false` |  |
| certManager.clientConfigRBAC | bool | `false` |  |
| certManager.clients | list | `[]` |  |
| clusterDomain | string | `nil` |  |
| openvpn | object | `{"ca":null,"cert":null,"config":null,"defaultroutes":null,"dh":null,"hostName":"vpn.example.com","key":null,"otp":null,"redirectGateway":false,"revoke":null,"tlsauth":null}` | genkey secret ta.key  -----BEGIN OpenVPN Static key V1----- -----END OpenVPN Static key V1----- |
| openvpn.cert | string | `nil` | ---END CERTIFICATE----- |
| openvpn.key | string | `nil` | ---END CERTIFICATE----- |
| podAnnotations | object | `{}` | Annotations for pod. ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/ |
| podSecurityContext | object | `{"fsGroup":101,"fsGroupChangePolicy":"OnRootMismatch","runAsGroup":101,"runAsUser":0}` | Pod Security Context. ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod |
| securityContext | object | `{"capabilities":{"add":["NET_ADMIN","MKNOD","SETUID","SETGID"],"drop":["ALL"]},"runAsGroup":101,"seccompProfile":{"type":"RuntimeDefault"}}` | Container Security Context. ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod |
| service | object | `{"annotations":{},"ipFamilies":["IPv4"],"port":1190,"ports":[],"proto":"UDP","type":"ClusterIP"}` | Service parameters ref: https://kubernetes.io/docs/user-guide/services/ |
| resources | object | `{"limits":{"cpu":1,"memory":"128Mi"},"requests":{"cpu":"100m","memory":"32Mi"}}` | Resource requests and limits. ref: https://kubernetes.io/docs/user-guide/compute-resources/ |
| useDaemonSet | bool | `false` | Use a daemonset instead of a deployment |
| updateStrategy | object | `{"rollingUpdate":{"maxUnavailable":1},"type":"RollingUpdate"}` | pod deployment update stategy type. ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment |
| nodeSelector | object | `{}` | Node labels for pod assignment. ref: https://kubernetes.io/docs/user-guide/node-selection/ |
| tolerations | list | `[]` | Tolerations for pod assignment. ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/ |
| affinity | object | `{}` | Affinity for pod assignment. ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity |

