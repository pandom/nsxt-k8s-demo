# NCP 2.3.2 installtion example

## Generate PI

Edit shell scripts and run them

```shell
./generate-superuser.sh
./create_pi.sh
```

These scripts were downloaded from the following link.
https://docs.pivotal.io/runtimes/pks/1-3/generate-nsx-pi-cert.html


## Command to deploy NCP

```shell
kubectl apply -f ./ncp-rbac.yml
kubectl -n nsx-system create secret tls ncp-client-cert --cert=./ncp-client-crt.crt --key=ncp-client-crt.key
kubectl -n nsx-system create secret generic nsx-cert --from-file=./nsx-ca.crt
kubectl -n nsx-system create secret tls default-lb-tls --key lb-cert.key --cert lb-cert.crt
kubectl apply -f ncp-rc.yml
kubectl apply -f nsx-node-agent-ds.yml
```
