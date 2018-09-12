#!/bin/bash

kubectl delete networkpolicy default-deny
kubectl delete networkpolicy apple-demo-policy
kubectl delete ingress apple-demo-ingress
kubectl delete svc apple-demo
kubectl delete rc apple-demo-rc
while :
do
  PODNUM=$(kubectl get pod | grep pod | wc -l) 
  if [[ $PODNUM -eq 0 ]]; then
    break
  fi
  sleep 5
done
kubectl delete ns apple
kubectl -n orange delete svc/orange-demo
