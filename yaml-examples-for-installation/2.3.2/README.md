
```shell
kubectl apply -f ./ncp-rbac.yml
kubectl -n nsx-system create secret tls ncp-client-cert --cert=./ncp-client-crt.crt --key=ncp-client-crt.key
kubectl -n nsx-system create secret generic nsx-cert --from-file=./nsx-ca.crt
kubectl -n nsx-system create secret tls default-lb-tls --key lb-cert.key --cert lb-cert.crt
kubectl apply -f nsx-node-agent-ds.yml
```
