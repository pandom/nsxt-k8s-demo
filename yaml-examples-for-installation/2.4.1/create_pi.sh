#!/bin/bash
#create_pi.sh

NSX_MANAGER="nsxm.ytsuboi.local"
NSX_USER="admin"
CERTIFICATE_ID='de81e6fd-42f7-4b62-893a-08a63921cbaa'

PI_NAME="infra-k8s-client-crt"
NSX_SUPERUSER_CERT_FILE="infra-k8s-client-crt.crt"
NSX_SUPERUSER_KEY_FILE="infra-k8s-client-crt.key"
NODE_ID=$(cat /proc/sys/kernel/random/uuid)

stty -echo
printf "Password: "
read NSX_PASSWORD
stty echo

pi_request=$(cat <<END
    {
         "display_name": "$PI_NAME",
         "name": "$PI_NAME",
         "permission_group": "superusers",
         "certificate_id": "$CERTIFICATE_ID",
         "node_id": "$NODE_ID"
    }
END
)

curl -k -X POST \
    "https://${NSX_MANAGER}/api/v1/trust-management/principal-identities" \
    -u "$NSX_USER:$NSX_PASSWORD" \
    -H 'content-type: application/json' \
    -d "$pi_request"

curl -k -X GET \
    "https://${NSX_MANAGER}/api/v1/trust-management/principal-identities" \
    --cert $(pwd)/"$NSX_SUPERUSER_CERT_FILE" \
    --key $(pwd)/"$NSX_SUPERUSER_KEY_FILE"
