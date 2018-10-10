# ncp/nsx-node-agent configuration
This document assumes that host OS is Redhat.
## Preparation for rsyslog 

Do the following command on all nodes including masters and workers

```posh
# on each node
mkdir /var/log/nsx-ujo
# this should be user has id:1000
chown localadmin:localadmin /var/log/nsx-ujo
cat <<EOF >  /etc/logrotate.d/nsx-ujo
/var/log/nsx-ujo/*.log {
       copytruncate
       daily
       size 100M
       rotate 4
       delaycompress
       compress
       notifempty
       missingok
}
EOF
```

## Preparation for NCP PI 
```
[root@k8s-jump ~]# NSX_MANAGER="nsxm-site2.ytsuboi.local"
[root@k8s-jump ~]# NSX_USER="admin"
[root@k8s-jump ~]# NSX_PASSWORD='VMware1!'
[root@k8s-jump ~]# PI_NAME="ncp-nsx-t-superuser"
[root@k8s-jump ~]# NSX_SUPERUSER_CERT_FILE="ncp-nsx-t-superuser.crt"
[root@k8s-jump ~]# NSX_SUPERUSER_KEY_FILE="ncp-nsx-t-superuser.key"
[root@k8s-jump ~]# NODE_ID=$(cat /proc/sys/kernel/random/uuid)
[root@k8s-jump ~]#
[root@k8s-jump ~]# openssl req \
> -newkey rsa:2048 \
> -x509 \
> -nodes \
> -keyout "$NSX_SUPERUSER_KEY_FILE" \
> -new \
> -out "$NSX_SUPERUSER_CERT_FILE" \
> -subj /CN=pks-nsx-t-superuser \
> -extensions client_server_ssl \
> -config <(
> cat /etc/pki/tls/openssl.cnf \
> <(printf '[client_server_ssl]\nextendedKeyUsage = clientAuth\n')
> ) \
> -sha256 \
> -days 730
Generating a 2048 bit RSA private key
..........+++
................................................................................................................+++
writing new private key to 'ncp-nsx-t-superuser.key'
-----
[root@k8s-jump ~]#
[root@k8s-jump ~]#
[root@k8s-jump ~]#
[root@k8s-jump ~]# cert_request=$(cat <<END
>   {
>     "display_name": "$PI_NAME",
>     "pem_encoded": "$(awk '{printf "%s\\n", $0}' $NSX_SUPERUSER_CERT_FILE)"
>   }
> END
> )
[root@k8s-jump ~]#
[root@k8s-jump ~]# curl -k -X POST \
> "https://${NSX_MANAGER}/api/v1/trust-management/certificates?action=import" \
> -u "$NSX_USER:$NSX_PASSWORD" \
> -H 'content-type: application/json' \
> -d "$cert_request"
{
  "results" : [ {
    "resource_type" : "certificate_self_signed",
    "id" : "351b8b76-6d1d-4193-806a-eb3cd5fc06a8",
    "display_name" : "ncp-nsx-t-superuser",
    "tags" : [ ],
    "pem_encoded" : "-----BEGIN CERTIFICATE-----\nMIIC1jCCAb6gAwIBAgIJAMz0P13WWMOlMA0GCSqGSIb3DQEBCwUAMB4xHDAaBgNV\nBAMME3Brcy1uc3gtdC1zdXBlcnVzZXIwHhcNMTgwNzEyMDczNTU2WhcNMjAwNzEx\nMDczNTU2WjAeMRwwGgYDVQQDDBNwa3MtbnN4LXQtc3VwZXJ1c2VyMIIBIjANBgkq\nhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuFd1smguQNzG8mFQpnYfohYn3lcToVVW\nbmxENDCYGLhuj8FrerdPGoHHYmk4RwQioZPbLemesZIUxFhISWMkrBN8kXo4JvO/\nX/lGrkydHT9nVd3LNpyGL7Df9G5Qis0bSnqotdY922v0vybO31tI4u1pqlDZ5VjP\nFfAWMx0HUVD2RHQsMaFb/EIzRCq+RUuyg9dSElAsfBdJ91IoPRLdbJP3w0q65O4i\nSMKEdyJOaXXNdU1VqR3YlObIVLdhr7MXcfcQgYVbW6fd2SmZTdLSJO0tVyWIwOfS\nzGDEsv2Wq1pBeuwnQXXMX6vog+ld7EQkkDfI4GWxml6fYXTCc/61MwIDAQABoxcw\nFTATBgNVHSUEDDAKBggrBgEFBQcDAjANBgkqhkiG9w0BAQsFAAOCAQEARtULkj+X\nqcKrBA7TLkfWlLm64yFLgTta0TBKYGRG8rouBwu6u2rAcq/QIvWPKK7r1DH2IWaf\nM65JcF9oyJYxb6Eg+MLDe0PevZn+3oQMoawSkw3gOA9jWXNkGIKEEaezw7Cd2aAE\nNFHDqwr2xn5Ij345+aSInAsl8PHx1v++4As+eSLtgUFK2Y/uHLHyJNW4638uZD2M\nRa6F/DY3L/7ZwoLRs3yVuovdAgOd1pD5mb4u6KkidGMsHqf3Rn3/Ubu3yqGummc9\nJ0tDCQT+oXEuqC1xFHgsprbz9kxtdcWTiqYH1/kZ5JlD1E19YsOI+n54Y7/tx/L+\nRfJx+tW8QpQC9w==\n-----END CERTIFICATE-----\n",
    "used_by" : [ ],
    "_create_user" : "admin",
    "_create_time" : 1531380469402,
    "_last_modified_user" : "admin",
    "_last_modified_time" : 1531380469402,
    "_system_owned" : false,
    "_protection" : "NOT_PROTECTED",
    "_revision" : 0
  } ]
}[root@k8s-jump ~]#
[root@k8s-jump ~]#
[root@k8s-jump ~]# CERTIFICATE_ID=351b8b76-6d1d-4193-806a-eb3cd5fc06a8
[root@k8s-jump ~]# pi_request=$(cat <<END
>   {
>     "name": "$PI_NAME",
>     "certificate_id": "$CERTIFICATE_ID",
>     "node_id": "$NODE_ID",
>     "role": "enterprise_admin",
>     "is_protected": "true"
>   }
> END
> )
[root@k8s-jump ~]#
[root@k8s-jump ~]#
[root@k8s-jump ~]# curl -k -X POST \
>   "https://${NSX_MANAGER}/api/v1/trust-management/principal-identities" \
>   -u "$NSX_USER:$NSX_PASSWORD" \
>   -H 'content-type: application/json' \
>   -d "$pi_request"
{
  "resource_type" : "PrincipalIdentity",
  "id" : "0d5a8161-3d67-49c8-bf39-bc87be1343c2",
  "display_name" : "ncp-nsx-t-superuser@73d55ed9-4a8e-4480-a066-0b183b028e9b",
  "tags" : [ ],
  "certificate_id" : "351b8b76-6d1d-4193-806a-eb3cd5fc06a8",
  "role" : "enterprise_admin",
  "name" : "ncp-nsx-t-superuser",
  "permission_group" : "undefined",
  "is_protected" : true,
  "node_id" : "73d55ed9-4a8e-4480-a066-0b183b028e9b",
  "_create_user" : "admin",
  "_create_time" : 1531380638379,
  "_last_modified_user" : "admin",
  "_last_modified_time" : 1531380638379,
  "_system_owned" : false,
  "_protection" : "NOT_PROTECTED",
  "_revision" : 0
}
[root@k8s-jump ~]#
[root@k8s-jump ~]#
[root@k8s-jump ~]#
[root@k8s-jump ~]# curl -k -X GET \
> "https://${NSX_MANAGER}/api/v1/trust-management/principal-identities" \
> --cert $(pwd)/"$NSX_SUPERUSER_CERT_FILE" \
> --key $(pwd)/"$NSX_SUPERUSER_KEY_FILE"
{
  "results" : [ {
    "resource_type" : "PrincipalIdentity",
    "id" : "0d5a8161-3d67-49c8-bf39-bc87be1343c2",
    "display_name" : "ncp-nsx-t-superuser@73d55ed9-4a8e-4480-a066-0b183b028e9b",
    "tags" : [ ],
    "certificate_id" : "351b8b76-6d1d-4193-806a-eb3cd5fc06a8",
    "role" : "enterprise_admin",
    "name" : "ncp-nsx-t-superuser",
    "permission_group" : "undefined",
    "is_protected" : true,
    "node_id" : "73d55ed9-4a8e-4480-a066-0b183b028e9b",
    "_create_user" : "admin",
    "_create_time" : 1531380638379,
    "_last_modified_user" : "admin",
    "_last_modified_time" : 1531380638379,
    "_system_owned" : false,
    "_protection" : "NOT_PROTECTED",
    "_revision" : 0
  }, {
    "resource_type" : "PrincipalIdentity",
    "id" : "0bd93d40-c785-4fa6-a08e-a9d3a1965baa",
    "display_name" : "ncp-user@ncp-node",
    "tags" : [ ],
    "certificate_id" : "62eadc00-33ae-48d2-b586-8f01d6c65683",
    "role" : "enterprise_admin",
    "name" : "ncp-user",
    "permission_group" : "undefined",
    "is_protected" : true,
    "node_id" : "ncp-node",
    "_create_user" : "admin",
    "_create_time" : 1531380167930,
    "_last_modified_user" : "admin",
    "_last_modified_time" : 1531380167930,
    "_system_owned" : false,
    "_protection" : "NOT_PROTECTED",
    "_revision" : 0
  } ]
}
```

## Preparation for NSX Manager Cert

```
[root@k8s-jump ~]# cat nsx-cert.cnf
[ req ]
default_bits = 2048
distinguished_name = req_distinguished_name
req_extensions = req_ext
prompt = no

[ req_distinguished_name ]
countryName = JP
stateOrProvinceName = Tokyo
localityName = Minato-ku
organizationName = VMware
commonName = nsxm-site2.ytsuboi.local

[ req_ext ]
subjectAltName=DNS:nsxm-site2.ytsuboi.local,IP:10.16.187.13

[SAN]
subjectAltName=DNS:nsxm-site2.ytsuboi.local,IP:10.16.187.13

[root@k8s-jump ~]# openssl req -newkey rsa:2048 -x509 -nodes -keyout nsx.key -new -out nsx.crt -subj /CN=$NSX_MANAGER_COMMONNAME -reqexts SAN -extensions SAN -config ./nsx-cert.cnf -sha256 -days 365
Generating a 2048 bit RSA private key
.....................................................................................................................+++
....................................................+++
writing new private key to 'nsx.key'
-----
[root@k8s-jump ~]# ls -la
total 652144
dr-xr-x---.  5 root root      4096 Jul 12 16:02 .
dr-xr-xr-x. 17 root root       224 Jul 11 13:45 ..
-rw-------.  1 root root      3413 Jul 12 15:03 .bash_history
-rw-r--r--.  1 root root        18 Dec 29  2013 .bash_logout
-rw-r--r--.  1 root root       176 Dec 29  2013 .bash_profile
-rw-r--r--.  1 root root       176 Dec 29  2013 .bashrc
-rw-r--r--.  1 root root       100 Dec 29  2013 .cshrc
drwxr-xr-x.  4 root root        51 Jul 12 10:01 .kube
drwxr-----.  3 root root        19 Jul 11 13:43 .pki
-rw-------.  1 root root      1024 Jul 12 16:02 .rnd
-rw-r--r--.  1 root root      1283 Jul 11 16:39 .screenrc
drwx------.  2 root root        57 Jul 11 16:38 .ssh
-rw-r--r--.  1 root root       129 Dec 29  2013 .tcshrc
-rw-------.  1 root root      2038 Jul 11 12:07 anaconda-ks.cfg
-rw-r--r--.  1 root root       411 Jul 12 16:01 nsx-cert.cnf
-rw-r--r--.  1 root root 667740969 Jul 11 18:13 nsx-container-2.2.0.8740202.zip
-rw-r--r--.  1 root root      1265 Jul 12 16:02 nsx.crt
-rw-r--r--.  1 root root      1708 Jul 12 16:02 nsx.key
[root@k8s-jump ~]#
[root@k8s-jump ~]#
[root@k8s-jump ~]# openssl x509 -in nsx.crt -text -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            f8:34:2c:bd:32:4c:0d:b7
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=JP, ST=Tokyo, L=Minato-ku, O=VMware, CN=nsxm-site2.ytsuboi.local
        Validity
            Not Before: Jul 12 07:02:13 2018 GMT
            Not After : Jul 12 07:02:13 2019 GMT
        Subject: C=JP, ST=Tokyo, L=Minato-ku, O=VMware, CN=nsxm-site2.ytsuboi.local
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:a8:0e:2a:0f:d1:0e:f9:f8:72:d9:45:54:54:98:
                    b5:bc:3e:5a:fc:bb:57:e6:ed:89:4e:ae:32:0e:86:
                    cc:fd:c7:73:c5:ed:b9:cd:f9:0a:23:94:eb:fa:9e:
                    32:83:e7:3b:b5:fd:4a:14:ad:d2:6f:54:0b:ae:5e:
                    17:ed:3e:76:72:cc:76:31:cf:84:41:29:b3:f5:8f:
                    38:e2:b6:ba:12:8e:d7:b7:26:cc:ea:76:6a:ca:33:
                    a4:08:cb:c1:d5:9a:d9:6a:3c:10:d5:b8:cf:e2:03:
                    c0:9c:8b:f3:ea:93:0b:61:e6:cd:8b:22:19:b9:b1:
                    8d:69:59:49:82:90:7d:6e:12:b4:d6:67:0f:99:19:
                    9b:92:d6:d1:b5:a5:a0:61:9a:1e:1b:06:f6:b1:c3:
                    99:ea:c1:9c:04:97:31:4c:32:4b:c7:7a:33:58:81:
                    0f:45:84:79:b1:bb:1c:a5:1b:94:a8:1d:3c:63:4f:
                    2d:d3:a6:fe:27:db:1f:59:21:62:1e:8c:23:af:9b:
                    dd:91:f9:be:56:98:21:b5:30:9f:b1:27:a6:77:36:
                    85:cb:6c:4b:ee:21:0d:4f:f1:4f:48:17:36:c3:e6:
                    af:d4:e4:80:ef:b6:8f:73:5a:20:cf:1a:16:63:c3:
                    cb:b3:fa:ec:a7:3d:41:ee:35:2b:30:69:dc:92:18:
                    a9:e1
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Subject Alternative Name:
                DNS:nsxm-site2.ytsuboi.local, IP Address:10.16.187.13
    Signature Algorithm: sha256WithRSAEncryption
         84:a4:1e:d1:85:a4:a5:4e:ca:1c:35:06:7a:b5:53:f8:14:8a:
         b6:5e:38:65:78:12:fe:f4:07:51:52:2c:b6:d1:22:c4:cf:8d:
         7c:da:70:ba:99:0a:cb:51:6a:dd:91:57:55:bc:94:03:fb:73:
         a4:62:c9:35:ce:bc:14:50:ea:3b:55:62:98:51:60:0d:8e:fb:
         2c:cd:6e:ac:1e:7e:c0:9b:19:60:f4:57:b8:ae:b2:08:f0:bc:
         00:97:52:df:e4:83:7c:a6:57:d3:be:01:7a:c4:40:17:1a:3a:
         38:be:ce:32:3e:42:cc:98:d1:28:57:45:10:7a:3c:49:22:66:
         59:cb:40:66:70:8f:54:ee:77:49:ff:d6:76:c7:99:5e:39:34:
         fc:8b:55:b6:95:6f:63:44:9f:ca:78:4f:38:71:cf:49:70:55:
         5f:ea:d0:1c:87:3e:7c:75:da:74:28:e4:7b:07:83:60:c5:08:
         db:31:96:82:83:27:55:12:b1:c2:24:57:59:64:14:e2:a8:f0:
         06:a8:6d:53:c8:82:d3:e3:26:61:dc:24:80:34:84:8b:10:e0:
         7a:a3:2e:1b:d6:b3:6e:a1:a1:21:27:c9:ef:41:0d:98:70:98:
         92:7c:7e:c1:f5:35:fc:fe:35:53:33:1e:7c:12:a7:4e:4d:02:
         67:e4:27:3c
         
# Import from UI
[root@k8s-jump ~]# cat nsx.crt
-----BEGIN CERTIFICATE-----
MIIDejCCAmKgAwIBAgIJAPg0LL0yTA23MA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNV
BAYTAkpQMQ4wDAYDVQQIDAVUb2t5bzESMBAGA1UEBwwJTWluYXRvLWt1MQ8wDQYD
VQQKDAZWTXdhcmUxITAfBgNVBAMMGG5zeG0tc2l0ZTIueXRzdWJvaS5sb2NhbDAe
Fw0xODA3MTIwNzAyMTNaFw0xOTA3MTIwNzAyMTNaMGUxCzAJBgNVBAYTAkpQMQ4w
DAYDVQQIDAVUb2t5bzESMBAGA1UEBwwJTWluYXRvLWt1MQ8wDQYDVQQKDAZWTXdh
cmUxITAfBgNVBAMMGG5zeG0tc2l0ZTIueXRzdWJvaS5sb2NhbDCCASIwDQYJKoZI
hvcNAQEBBQADggEPADCCAQoCggEBAKgOKg/RDvn4ctlFVFSYtbw+Wvy7V+btiU6u
Mg6GzP3Hc8Xtuc35CiOU6/qeMoPnO7X9ShSt0m9UC65eF+0+dnLMdjHPhEEps/WP
OOK2uhKO17cmzOp2asozpAjLwdWa2Wo8ENW4z+IDwJyL8+qTC2HmzYsiGbmxjWlZ
SYKQfW4StNZnD5kZm5LW0bWloGGaHhsG9rHDmerBnASXMUwyS8d6M1iBD0WEebG7
HKUblKgdPGNPLdOm/ifbH1khYh6MI6+b3ZH5vlaYIbUwn7Enpnc2hctsS+4hDU/x
T0gXNsPmr9TkgO+2j3NaIM8aFmPDy7P67Kc9Qe41KzBp3JIYqeECAwEAAaMtMCsw
KQYDVR0RBCIwIIIYbnN4bS1zaXRlMi55dHN1Ym9pLmxvY2FshwQKELsNMA0GCSqG
SIb3DQEBCwUAA4IBAQCEpB7RhaSlTsocNQZ6tVP4FIq2XjhleBL+9AdRUiy20SLE
z4182nC6mQrLUWrdkVdVvJQD+3OkYsk1zrwUUOo7VWKYUWANjvsszW6sHn7Amxlg
9Fe4rrII8LwAl1Lf5IN8plfTvgF6xEAXGjo4vs4yPkLMmNEoV0UQejxJImZZy0Bm
cI9U7ndJ/9Z2x5leOTT8i1W2lW9jRJ/KeE84cc9JcFVf6tAchz58ddp0KOR7B4Ng
xQjbMZaCgydVErHCJFdZZBTiqPAGqG1TyILT4yZh3CSANISLEOB6oy4b1rNuoaEh
J8nvQQ2YcJiSfH7B9TX8/jVTMx58EqdOTQJn5Cc8
-----END CERTIFICATE-----
[root@k8s-jump ~]# cat nsx.key
-----BEGIN PRIVATE KEY-----
MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQCoDioP0Q75+HLZ
RVRUmLW8Plr8u1fm7YlOrjIOhsz9x3PF7bnN+QojlOv6njKD5zu1/UoUrdJvVAuu
XhftPnZyzHYxz4RBKbP1jzjitroSjte3JszqdmrKM6QIy8HVmtlqPBDVuM/iA8Cc
i/Pqkwth5s2LIhm5sY1pWUmCkH1uErTWZw+ZGZuS1tG1paBhmh4bBvaxw5nqwZwE
lzFMMkvHejNYgQ9FhHmxuxylG5SoHTxjTy3Tpv4n2x9ZIWIejCOvm92R+b5WmCG1
MJ+xJ6Z3NoXLbEvuIQ1P8U9IFzbD5q/U5IDvto9zWiDPGhZjw8uz+uynPUHuNSsw
adySGKnhAgMBAAECggEBAKIQrs17/aZgy1juPAotDq2PsK0jefywPAcNhCZwJwXh
r6tDuziAHx/7QKr6npqHhxTVQ/i3PEWyVmV8RjS7VP0WYjFc/xzcO7jmuqQgNUcq
S6tLlrfRJOEEdf8piC8XWu3RKScCSC+dEMWnTb18urBaJQQ1CXwDVu0udu6bqupX
PZ2NKPob6D0CxyoDrpzfoki58VXSb6Gj5zeyOVUt9HHYa/JCIJqLJsyVKxXIFrdY
36m9XG684iiC6uueAC5XGF3pcCpRv+pu2gs53pihDCHVJMrV59XAgu4ZKVxxG7md
F3ptMomhjSQFQhFLjCADnQ1KfIreXKim5rYSszH5UAECgYEA1iIUdJ8fl3bXStF8
CRLBqKxYJwY04JKEk6YiQjTG3xNdfVyaowHm/sF3AiBhtu+Zi8659sgJe07sTEdI
nUSYrgO2V155bxHJPrwpWvxv2XczqppBOFWb64h4OdG1zKrOyAtPv/epP6qhV6za
b9lpLga70/jDlYkNbKvcJIL2U4ECgYEAyOnFVenGWot3N2p3waJZ365uBrK1K4/z
qlIIKfX4B4ytJZtXowmI+IcKXTQDgemwooS1Zm/GxlH2rkvmWvnptgwQ46ky7TdG
sUF6KuO/G+XDKZx09+Y9r2zUOEMxC8HhnowHqh3IXitcEmTpEFrwZtH9tXDwfqXg
hH1MH3vOBmECgYEA0+HE++C4Ede2EIJYiWHV3mEqmPK7P7u7E55AJ+KxJeqzh2gq
W0F2oH4ulBwWlD1hYcWcnWQyfaEKkC+42mUV7podwzXoUs72ouzsvusqgbRBm34n
KucK8XSIAi5QBcS995O5xen5vtXH8ElJm4M1YCWplYWBgmWqsu0bV8V+mAECgYB5
AQqf3sdfGyY3EwGDdrNoW5bao+EnlnBrwTI3i3PRoDFcN/4FLKX5AOQGFGCUatm+
V+0k/+cY5J6MhRv86Q2QXh4B75LDegoykbvxfu9H7w6mzhtIfrviHsqGBDnS2fd3
1OB83akixjySu4H/HrYxRwHluFqv/FmHkis5vwfroQKBgQDTLu274A7Frc0uHM9w
zO1FsTVY4a+g3WeUDHtWOSrGecYV8PPmRTw71OMdHpR8g+InE20fsz9C0O7M3yNT
3z6Oc0zHdQX1aEEd4ZcNCjrhGneS5m9YM1T8QtDyLkjC63HD7kLQAndI7G/opNQ8
yzUeDJBV9TRQf+zt3VdPsRd84w==
-----END PRIVATE KEY-----
[root@k8s-jump ~]# curl --insecure -u admin:VMware1! -X GET https://nsxm-site2.ytsuboi.local/api/v1/trust-management/certificates
{
  "result_count" : 4,
  "results" : [ {
    "resource_type" : "certificate_self_signed",
    "id" : "492396e5-1714-4463-90a8-5a89dd191702",
    "display_name" : "MP Cluster Certificate",
    "tags" : [ ],
    "pem_encoded" : "-----BEGIN CERTIFICATE-----\nMIIDhDCCAmygAwIBAgIEbyn/YzANBgkqhkiG9w0BAQsFADBnMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExEjAQBgNVBAcTCVBhbG8gQWx0bzEUMBIGA1UEChMLVk13YXJlIEluYy4xDDAKBgNVBAsTA05TWDETMBEGA1UEAxMKbnN4bS1zaXRlMjAeFw0xODA3MTAwNjU0MjVaFw0yODA3MDcwNjU0MjVaMGcxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJDQTESMBAGA1UEBxMJUGFsbyBBbHRvMRQwEgYDVQQKEwtWTXdhcmUgSW5jLjEMMAoGA1UECxMDTlNYMRMwEQYDVQQDEwpuc3htLXNpdGUyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmme/ScfsKPiLCpZJ5+OwYowzbXqbK7Io6gKNJHzWeJTlH17YdBEJdRo5m4uEo9Pwb5c3oeti2qf8X6YPK5rMCKYYJg6GHXUcfR4H7vM2ODFpaQ4Bt+704v1F+a5XIrzM1W1kMBkc4FewDZjOXkeH4DTm/k18Y1lc4AHZdk3vQeOu6qW0ieaQ8t82B85h4rUddUWdhSo3SSl3z+8cy62M/VxBhXwcnAxpT2ymTklBWvBkIVtGLy9yIa8jKJn4zMC1RZAl5JyYYIl/RDxuiongUsE4Y3AWERdmm7pbN3/p0DLCFX+qfoHP40c7lJ664Jkubqx0fnTZxNezauY4NFFT8wIDAQABozgwNjAVBgNVHREEDjAMggpuc3htLXNpdGUyMB0GA1UdDgQWBBR90+F/pA9QCrEllRpRgH/nyi2zqjANBgkqhkiG9w0BAQsFAAOCAQEAkS1FAtLG4B7dVaBTTXhcHHRPP7nBfLWABmgQV5iT6z0kk0+lWeJsj1243s9terJHqHwgDqdzgMniVyk0NFCagFbcGnA4mCdbppSxwZsSTcl4hNFGSC2tMjDLRsoG2dhoSI9K+ywMVvjmsDomw02xEzxMOcgXZG6GiJRhBHvVjvt8BGhPBmMRsVdzm6Spx1ggSs32JTrXcgpHRKHm6UCi7kbpLdm72lVJoEQjts/qpjnmHkPpgQ7c8SFYZB0M+fzgsYZHHrgsI53M3sL7mK33x03UygyH57bfqeOlX4cbZxUdOUHqxhUMxWff+yzZo/G/GzvTTrM89nSK3XF2OJBPxQ==\n-----END CERTIFICATE-----",
    "used_by" : [ {
      "service_types" : [ "Cluster Certificate" ],
      "node_id" : "95932842-8564-1ede-5b58-13bdef335f64"
    } ],
    "_create_user" : "system",
    "_create_time" : 1531207354229,
    "_last_modified_user" : "system",
    "_last_modified_time" : 1531207354229,
    "_system_owned" : false,
    "_protection" : "NOT_PROTECTED",
    "_revision" : 1
  }, {
    "resource_type" : "certificate_self_signed",
    "description" : "Client certificate for TLS authentication with KeyManager",
    "id" : "aae0d4bf-1ef4-4147-a8f8-bcdc09d455fc",
    "display_name" : "NSX MP Client Certificate for Key Manager",
    "tags" : [ ],
    "pem_encoded" : "-----BEGIN CERTIFICATE-----\nMIIDmzCCAoOgAwIBAgIGAWSDEgX3MA0GCSqGSIb3DQEBCwUAMHoxJzAlBgNVBAMM\nHlZNd2FyZSBOU1hBUEkgVHJ1c3QgTWFuYWdlbWVudDETMBEGA1UECgwKVk13YXJl\nIEluYzEMMAoGA1UECwwDTlNYMQswCQYDVQQGEwJVUzELMAkGA1UECAwCQ0ExEjAQ\nBgNVBAcMCVBhbG8gQWx0bzAeFw0xODA3MTAwNzIyMzNaFw0yODA3MDcwNzIyMzNa\nMHoxJzAlBgNVBAMMHlZNd2FyZSBOU1hBUEkgVHJ1c3QgTWFuYWdlbWVudDETMBEG\nA1UECgwKVk13YXJlIEluYzEMMAoGA1UECwwDTlNYMQswCQYDVQQGEwJVUzELMAkG\nA1UECAwCQ0ExEjAQBgNVBAcMCVBhbG8gQWx0bzCCASIwDQYJKoZIhvcNAQEBBQAD\nggEPADCCAQoCggEBAOPrLPgr0/2pf47GtURprWkhaYpIa0IsziAOniXVO4qcoYrE\n9U6YgB7mMxzii0qSFEuYhrPmJViOzr6VEIVUGssFtKn7dr5tFx8sE823A8fgxUBA\ndKbPBSSo4JFVMFKnA6lWWM2WOkQ/M+AqiOZMbMH/Pa/XIb31IfZ0QVWwRsvRrwaZ\nt+rq9pV8ARaJy/6kr6pY0NnwxwP04mX1cufe/42p1iyznZDv6wamp2EoOLY8Q4JN\nkbq1dRq5M3rmP99+op9caGNNB62czAiVLY5gAkMYevR4ollLGsAOSXmBzzUcpX23\n72e/vO/+13CC+X7pGbTnDiuSCTUDo7H75v6WaQcCAwEAAaMnMCUwDgYDVR0PAQH/\nBAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMCMA0GCSqGSIb3DQEBCwUAA4IBAQAu\nTZuWqvnUN4yBy1GUSbCDuNEQ08xpOQTW7OHt+VUEBxZwNVtlHEJOKnzMZihCxmML\nlLMtESX5gCiD6wcfqyJQr61WxHD2zlCuw5Hg9mfIVHWwopk+Ag6HA91xCltatxH1\n6YIbSSl2caK8Zh7zvMRllGuXh9JvxoLyp13qULhKRYTEDrxkS7n0wZJzhzwmQGij\n7xojKZHWT/t54q6xNRTDM0Y7mMbl001WvU/C2hLbCul2u5VrwLYd9bobnIfRtJtf\nGcV9RJMx4bPfV82Qh3oPbfc/JGKuP2OiHXIwb2iDJpx9wsVnrjLGw3tMGgUmT/xt\nVim4JH2mmISoJagkc8Ot\n-----END CERTIFICATE-----\n",
    "used_by" : [ {
      "service_types" : [ "MGMT_PLANE_DNE" ],
      "node_id" : "95932842-8564-1ede-5b58-13bdef335f64"
    } ],
    "_create_user" : "system",
    "_create_time" : 1531207353941,
    "_last_modified_user" : "system",
    "_last_modified_time" : 1531207353941,
    "_system_owned" : true,
    "_protection" : "NOT_PROTECTED",
    "_revision" : 1
  }, {
    "resource_type" : "certificate_self_signed",
    "id" : "351b8b76-6d1d-4193-806a-eb3cd5fc06a8",
    "display_name" : "ncp-nsx-t-superuser",
    "tags" : [ ],
    "pem_encoded" : "-----BEGIN CERTIFICATE-----\nMIIC1jCCAb6gAwIBAgIJAMz0P13WWMOlMA0GCSqGSIb3DQEBCwUAMB4xHDAaBgNV\nBAMME3Brcy1uc3gtdC1zdXBlcnVzZXIwHhcNMTgwNzEyMDczNTU2WhcNMjAwNzEx\nMDczNTU2WjAeMRwwGgYDVQQDDBNwa3MtbnN4LXQtc3VwZXJ1c2VyMIIBIjANBgkq\nhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuFd1smguQNzG8mFQpnYfohYn3lcToVVW\nbmxENDCYGLhuj8FrerdPGoHHYmk4RwQioZPbLemesZIUxFhISWMkrBN8kXo4JvO/\nX/lGrkydHT9nVd3LNpyGL7Df9G5Qis0bSnqotdY922v0vybO31tI4u1pqlDZ5VjP\nFfAWMx0HUVD2RHQsMaFb/EIzRCq+RUuyg9dSElAsfBdJ91IoPRLdbJP3w0q65O4i\nSMKEdyJOaXXNdU1VqR3YlObIVLdhr7MXcfcQgYVbW6fd2SmZTdLSJO0tVyWIwOfS\nzGDEsv2Wq1pBeuwnQXXMX6vog+ld7EQkkDfI4GWxml6fYXTCc/61MwIDAQABoxcw\nFTATBgNVHSUEDDAKBggrBgEFBQcDAjANBgkqhkiG9w0BAQsFAAOCAQEARtULkj+X\nqcKrBA7TLkfWlLm64yFLgTta0TBKYGRG8rouBwu6u2rAcq/QIvWPKK7r1DH2IWaf\nM65JcF9oyJYxb6Eg+MLDe0PevZn+3oQMoawSkw3gOA9jWXNkGIKEEaezw7Cd2aAE\nNFHDqwr2xn5Ij345+aSInAsl8PHx1v++4As+eSLtgUFK2Y/uHLHyJNW4638uZD2M\nRa6F/DY3L/7ZwoLRs3yVuovdAgOd1pD5mb4u6KkidGMsHqf3Rn3/Ubu3yqGummc9\nJ0tDCQT+oXEuqC1xFHgsprbz9kxtdcWTiqYH1/kZ5JlD1E19YsOI+n54Y7/tx/L+\nRfJx+tW8QpQC9w==\n-----END CERTIFICATE-----\n",
    "used_by" : [ {
      "service_types" : [ "Client Authentication" ],
      "node_id" : "{name: 'ncp-nsx-t-superuser',node_id: '73d55ed9-4a8e-4480-a066-0b183b028e9b',role: 'enterprise_admin',protected: 'true'}"
    } ],
    "_create_user" : "admin",
    "_create_time" : 1531380469402,
    "_last_modified_user" : "admin",
    "_last_modified_time" : 1531380469402,
    "_system_owned" : false,
    "_protection" : "NOT_PROTECTED",
    "_revision" : 1
  }, {
    "resource_type" : "certificate_self_signed",
    "id" : "a41c03dd-fd18-4420-ba50-fd9b85da3f3c",
    "display_name" : "nsx-ncp-cert",
    "tags" : [ ],
    "pem_encoded" : "-----BEGIN CERTIFICATE-----\nMIIDejCCAmKgAwIBAgIJAPg0LL0yTA23MA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNV\nBAYTAkpQMQ4wDAYDVQQIDAVUb2t5bzESMBAGA1UEBwwJTWluYXRvLWt1MQ8wDQYD\nVQQKDAZWTXdhcmUxITAfBgNVBAMMGG5zeG0tc2l0ZTIueXRzdWJvaS5sb2NhbDAe\nFw0xODA3MTIwNzAyMTNaFw0xOTA3MTIwNzAyMTNaMGUxCzAJBgNVBAYTAkpQMQ4w\nDAYDVQQIDAVUb2t5bzESMBAGA1UEBwwJTWluYXRvLWt1MQ8wDQYDVQQKDAZWTXdh\ncmUxITAfBgNVBAMMGG5zeG0tc2l0ZTIueXRzdWJvaS5sb2NhbDCCASIwDQYJKoZI\nhvcNAQEBBQADggEPADCCAQoCggEBAKgOKg/RDvn4ctlFVFSYtbw+Wvy7V+btiU6u\nMg6GzP3Hc8Xtuc35CiOU6/qeMoPnO7X9ShSt0m9UC65eF+0+dnLMdjHPhEEps/WP\nOOK2uhKO17cmzOp2asozpAjLwdWa2Wo8ENW4z+IDwJyL8+qTC2HmzYsiGbmxjWlZ\nSYKQfW4StNZnD5kZm5LW0bWloGGaHhsG9rHDmerBnASXMUwyS8d6M1iBD0WEebG7\nHKUblKgdPGNPLdOm/ifbH1khYh6MI6+b3ZH5vlaYIbUwn7Enpnc2hctsS+4hDU/x\nT0gXNsPmr9TkgO+2j3NaIM8aFmPDy7P67Kc9Qe41KzBp3JIYqeECAwEAAaMtMCsw\nKQYDVR0RBCIwIIIYbnN4bS1zaXRlMi55dHN1Ym9pLmxvY2FshwQKELsNMA0GCSqG\nSIb3DQEBCwUAA4IBAQCEpB7RhaSlTsocNQZ6tVP4FIq2XjhleBL+9AdRUiy20SLE\nz4182nC6mQrLUWrdkVdVvJQD+3OkYsk1zrwUUOo7VWKYUWANjvsszW6sHn7Amxlg\n9Fe4rrII8LwAl1Lf5IN8plfTvgF6xEAXGjo4vs4yPkLMmNEoV0UQejxJImZZy0Bm\ncI9U7ndJ/9Z2x5leOTT8i1W2lW9jRJ/KeE84cc9JcFVf6tAchz58ddp0KOR7B4Ng\nxQjbMZaCgydVErHCJFdZZBTiqPAGqG1TyILT4yZh3CSANISLEOB6oy4b1rNuoaEh\nJ8nvQQ2YcJiSfH7B9TX8/jVTMx58EqdOTQJn5Cc8\n-----END CERTIFICATE-----",
    "used_by" : [ ],
    "_create_user" : "admin",
    "_create_time" : 1531381061400,
    "_last_modified_user" : "admin",
    "_last_modified_time" : 1531381061400,
    "_system_owned" : false,
    "_protection" : "NOT_PROTECTED",
    "_revision" : 0
  } ]
}[root@k8s-jump ~]#
[root@k8s-jump ~]# curl --insecure -u admin:VMware1! -X POST 'https://nsxm-site2.ytsuboi.local/api/v1/node/services/http?action=apply_certificate&certificate_id=a41c03dd-fd18-4420-ba50-fd9b85da3f3c'
[root@k8s-jump ~]#
[root@k8s-jump ~]#
[root@k8s-jump ~]# ssh -l admin nsxm-site2.ytsuboi.local
The authenticity of host 'nsxm-site2.ytsuboi.local (10.16.187.13)' can't be established.
ECDSA key fingerprint is SHA256:Nx2uoutMWPdNCpUKj4WM0lGfldF2Rp/PBzeL19rgKJE.
ECDSA key fingerprint is MD5:e0:ea:4b:48:0c:1a:6a:b5:bc:e2:a5:e0:87:1c:cf:5b.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'nsxm-site2.ytsuboi.local,10.16.187.13' (ECDSA) to the list of known hosts.
admin@nsxm-site2.ytsuboi.local's password:
Last login: Tue Jul 10 07:37:10 2018 from 10.127.1.133
***************************************************************************
NOTICE TO USERS

This computer system is the private property of its owner, whether
individual, corporate or government. It is for authorized use only.
Users (authorized or unauthorized) have no explicit or implicit
expectation of privacy.

Any or all uses of this system and all files on this system may be
intercepted, monitored, recorded, copied, audited, inspected, and
disclosed to your employer, to authorized site, government, and law
enforcement personnel, as well as authorized officials of government
agencies, both domestic and foreign.

By using this system, the user consents to such interception, monitoring,
recording, copying, auditing, inspection, and disclosure at the
discretion of such personnel or officials. Unauthorized or improper use
of this system may result in civil and criminal penalties and
administrative or disciplinary action, as appropriate. By continuing to
use this system you indicate your awareness of and consent to these terms
and conditions of use. LOG OFF IMMEDIATELY if you do not agree to the
conditions stated in this warning.
****************************************************************************

NSX CLI (Manager 2.2.0.0.0.8680778). Press ? for command list or enter: help
nsxm-site2> get api
% Command not found: get api

  Possible alternatives:
    get all capture sessions
    get arp-table
    get auth-policy api lockout-period
    get auth-policy api lockout-reset-period
    get auth-policy api max-auth-failures
    get auth-policy cli lockout-period
    get auth-policy cli max-auth-failures
    get auth-policy minimum-password-length
    get auth-policy vidm

nsxm-site2> get api
% Command not found: get api

  Possible alternatives:
    get all capture sessions
    get arp-table
    get auth-policy api lockout-period
    get auth-policy api lockout-reset-period
    get auth-policy api max-auth-failures
    get auth-policy cli lockout-period
    get auth-policy cli max-auth-failures
    get auth-policy minimum-password-length
    get auth-policy vidm

nsxm-site2> get certificate api
  thumbprint  Certificate thumbprint
  <CR>        Execute command
  |           Output modifiers

nsxm-site2> get certificate api
-----BEGIN CERTIFICATE-----
MIIDejCCAmKgAwIBAgIJAPg0LL0yTA23MA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNV
BAYTAkpQMQ4wDAYDVQQIDAVUb2t5bzESMBAGA1UEBwwJTWluYXRvLWt1MQ8wDQYD
VQQKDAZWTXdhcmUxITAfBgNVBAMMGG5zeG0tc2l0ZTIueXRzdWJvaS5sb2NhbDAe
Fw0xODA3MTIwNzAyMTNaFw0xOTA3MTIwNzAyMTNaMGUxCzAJBgNVBAYTAkpQMQ4w
DAYDVQQIDAVUb2t5bzESMBAGA1UEBwwJTWluYXRvLWt1MQ8wDQYDVQQKDAZWTXdh
cmUxITAfBgNVBAMMGG5zeG0tc2l0ZTIueXRzdWJvaS5sb2NhbDCCASIwDQYJKoZI
hvcNAQEBBQADggEPADCCAQoCggEBAKgOKg/RDvn4ctlFVFSYtbw+Wvy7V+btiU6u
Mg6GzP3Hc8Xtuc35CiOU6/qeMoPnO7X9ShSt0m9UC65eF+0+dnLMdjHPhEEps/WP
OOK2uhKO17cmzOp2asozpAjLwdWa2Wo8ENW4z+IDwJyL8+qTC2HmzYsiGbmxjWlZ
SYKQfW4StNZnD5kZm5LW0bWloGGaHhsG9rHDmerBnASXMUwyS8d6M1iBD0WEebG7
HKUblKgdPGNPLdOm/ifbH1khYh6MI6+b3ZH5vlaYIbUwn7Enpnc2hctsS+4hDU/x
T0gXNsPmr9TkgO+2j3NaIM8aFmPDy7P67Kc9Qe41KzBp3JIYqeECAwEAAaMtMCsw
KQYDVR0RBCIwIIIYbnN4bS1zaXRlMi55dHN1Ym9pLmxvY2FshwQKELsNMA0GCSqG
SIb3DQEBCwUAA4IBAQCEpB7RhaSlTsocNQZ6tVP4FIq2XjhleBL+9AdRUiy20SLE
z4182nC6mQrLUWrdkVdVvJQD+3OkYsk1zrwUUOo7VWKYUWANjvsszW6sHn7Amxlg
9Fe4rrII8LwAl1Lf5IN8plfTvgF6xEAXGjo4vs4yPkLMmNEoV0UQejxJImZZy0Bm
cI9U7ndJ/9Z2x5leOTT8i1W2lW9jRJ/KeE84cc9JcFVf6tAchz58ddp0KOR7B4Ng
xQjbMZaCgydVErHCJFdZZBTiqPAGqG1TyILT4yZh3CSANISLEOB6oy4b1rNuoaEh
J8nvQQ2YcJiSfH7B9TX8/jVTMx58EqdOTQJn5Cc8
-----END CERTIFICATE-----
```


## Preparation for LB certification
```
[root@k8s-jump Kubernetes]# openssl genrsa -aes256 -out nsxt-lb-ca.key 4096
Generating RSA private key, 4096 bit long modulus
............................................................................................................................................++
.....++
e is 65537 (0x10001)
Enter pass phrase for nsxt-lb-ca.key:
Verifying - Enter pass phrase for nsxt-lb-ca.key:
[root@k8s-jump Kubernetes]# openssl req -key nsxt-lb-ca.key -new -x509 -days 365 -sha256 -extensions v3_ca -out nsxt-lb-ca.crt
Enter pass phrase for nsxt-lb-ca.key:
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [XX]:JP
State or Province Name (full name) []:Tokyo
Locality Name (eg, city) [Default City]:Minato-ku
Organization Name (eg, company) [Default Company Ltd]:VMware
Organizational Unit Name (eg, section) []:CS
Common Name (eg, your name or your server's hostname) []:default.demo.ytsuboi.local
Email Address []:
[root@k8s-jump Kubernetes]#
[root@k8s-jump Kubernetes]# openssl req -out nsxt-lb-https.csr -new -newkey rsa:2048 -nodes -keyout nsxt-lb-https.key
Generating a 2048 bit RSA private key
.............+++
.............................................................+++
writing new private key to 'nsxt-lb-https.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [XX]:JP
State or Province Name (full name) []:Tokyo
Locality Name (eg, city) [Default City]:Minato-ku
Organization Name (eg, company) [Default Company Ltd]:VMware
Organizational Unit Name (eg, section) []:
Common Name (eg, your name or your server's hostname) []:default.demo.ytsuboi.local
Email Address []:

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
[root@k8s-jump Kubernetes]#
[root@k8s-jump Kubernetes]# openssl x509 -req -days 360 -in nsxt-lb-https.csr -CA nsxt-lb-ca.crt -CAkey nsxt-lb-ca.key -CAcreateserial -out nsxt-lb-https.crt -sha256
Signature ok
subject=/C=JP/ST=Tokyo/L=Minato-ku/O=VMware/CN=default.demo.ytsuboi.local
Getting CA Private Key
Enter pass phrase for nsxt-lb-ca.key:
[root@k8s-jump Kubernetes]#
[root@k8s-jump Kubernetes]# kubectl -n nsx-system create secret tls default-lb-tls --key nsxt-lb-https.key --cert nsxt-lb-https.crt
secret "default-lb-tls" created
```



## Deploy ncp ReplicationController and nsx-node-agent Daemonset
### Create namspace for ncp
```
kubectl create ns nsx-system
```

### Setup RBAC for ncp service account

```
kubectl apply ncp-rbac.yaml
```

### Create secret used for NSX API client in NCP
```
kubectl -n nsx-system create secret tls ncp-client-cert --cert=./ncp-nsx-t-superuser.crt --key=./ncp-nsx-t-superuser.key
kubectl -n nsx-system create secret generic nsx-cert --from-file=./nsx.crt
```
### Apply ncp configuration

```
kubectl apply -f nsx-ncp-rsyslog-conf.yaml
kubectl apply -f ncp-rc.yml
```

### Apply nsx-node-agent configuration

```
kubectl apply -f nsx-node-agent-rsyslog-conf.yaml
kubectl apply -f nsx-node-agent-ds.yml
```

