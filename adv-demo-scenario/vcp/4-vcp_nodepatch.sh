export KUBECONFIG=/etc/kubernetes/admin.conf
NeedRebootList=""
for h in $(sudo kubectl get nodes | tail -n +2 | awk '{print $1}'); do
  uuid=$(sudo kubectl describe node/$h | grep -i UUID | tr '[:upper:]' '[:lower:]' | awk '{print $3}')
  eval sudo kubectl patch node $h -p \'{\"spec\":{\"providerID\":\"vsphere://${uuid}\"}}\' | grep 'no change' >/dev/null
  [[ $? -gt 0 ]] && NeedRebootList="$NeedRebootList $h"
done
[[ -n $NeedRebootList ]] && echo "$NeedRebootList" | tr ' ' '\n' | tail -n +2
