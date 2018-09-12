#!/bin/bash

TENANT=$1
TMPYML="/tmp/tenant-all.yaml"

kubectl get ns ${TENANT} > /dev/null 2>&1

if [[ $? -eq 0 ]]; then
  echo "${TENANT} already exits"
  exit 1
fi

cat << EOF > ${TMPYML}
---
apiVersion: v1
kind: ReplicationController
metadata:
  name: ${TENANT}-demo-rc
  labels:
    app: ${TENANT}-demo
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: ${TENANT}-demo
    spec:
      containers:
      - name: ${TENANT}-demo
        image: yfauser/nsx-demo
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: ${TENANT}-demo
  labels:
    app: ${TENANT}-demo
spec:
  ports:
    # the port that this service should serve on
    - port: 80
      targetPort: 80
      protocol: TCP
      name: tcp
  selector:
    app: ${TENANT}-demo
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ${TENANT}-demo-ingress
spec:
  rules:
  - host: ${TENANT}.demo.corp.local
    http:
      paths:
      - backend:
          serviceName: ${TENANT}-demo
          servicePort: 80

EOF

kubectl create ns ${TENANT}
kubectl -n ${TENANT} create -f ${TMPYML}
