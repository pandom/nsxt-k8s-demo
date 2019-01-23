# vSphere Cloud Provider

VCP allows for storage claims and persistent volumes. This allows the use of stateful sets.

Note the content of this repo is officially deprecated. With that said it is the easiest way to get persistent storage with vSphere running.

The official way is rather manual and I've not done any automation for it.

Deploy by doing the following:

1. `kubectl create -f 1-vcp_namespace_account_and_roles.yaml`
2. Edit `2-vcp_secret.yaml` and update base64 credentials if needed
3. `kubectl create --save-config -f 2-vcp_secret.yaml`
4. `kubectl create 3-vcp_enable.yaml`
5. Due to an issue a `ProviderID:` is missing. Please run the script to apply the provider ID to each K8s node
6. `sudo . vspherestorage.sh`

Persistent Storage should now work.
