#!/bin/bash
TENANT=$1

function cmd () {
  $@
  sleep 10
}

kubectl -n ${TENANT} delete networkpolicy default-deny
kubectl -n ${TENANT}  delete networkpolicy ${TENANT}-demo-policy
kubectl -n ${TENANT} delete ingress ${TENANT}-demo-ingress
kubectl -n ${TENANT}  delete svc ${TENANT}-demo
kubectl -n ${TENANT} delete rc ${TENANT}-demo-rc
while :
do
  PODNUM=$(kubectl get pod | grep pod | wc -l) 
  if [[ $PODNUM -eq 0 ]]; then
    break
  fi
  sleep 5
done
kubectl delete ns ${TENANT}
