# NSX-T K8s Integration demo repository

## basic-demo-scenario

This includes basic demo to show off benefit of NSX-T
Please look at README.md under the folder.

```
├── basic-demo-scenario
│   ├── apple
│   ├── orange
│   ├── README.md
│   └── resources
```

## adv-demo-scenario

This includes adv application demo to show off benefit of NSX-T
Please look at README.md under the folder.

```
├── adv-demo-scenario
│   ├── planespotter
│   ├── README.md
│   └── vcp
```

## samples of k8s-yaml

There are some yaml samples which are not guaranteed to work. 


```
├── k8s-yaml
│   ├── configure-snat-ip-pool-per-service
│   ├── ippool-for-service-type-lb
│   ├── networkpolicy-demo
│   ├── nginx-demo
│   ├── nginx-ingresscontroller
│   ├── nsx-demo
│   ├── persistent-storage
│   ├── probe-service-test
│   ├── rbac
│   ├── service-with-multiple-ports
│   └── vsphere-pv
```

## test-scripts

It is useful when you create multiple tenants at the same time.
If you want ingress in a new tenant, you can do like `./create-ingress.sh new-tenant`
If you want service type lb in a new tenant, you can do like `./create-lbservice.sh new-tenant`

```
├── test-scripts
│   ├── clean-tenant.sh
│   ├── create-ingress.sh
│   ├── create-lbservice.sh
│   └── demo-init.sh
```

## yaml-examples-for-installation

This is an example when you deploy ncp/nsx-node-agent on native kubernetes

```
└── yaml-examples-for-installation
    ├── 2.3
    ├── 2.3.1
    ├── 2.3.2
    └── 2.4.0
```

## yaml example for ncp feature

The folder name is like `<supported version>-<feature name>`

```
├── ncp-features-example
│   ├── 0_ncp-feature-ns.yml
│   ├── 2.1.0.2-wildcard-uri
│   ├── 2.1.2-matchexpression-with-networkpolicy
│   ├── 2.1.2-snat-per-service
│   ├── 2.1.4-ingress-rewrite
│   ├── 2.1.4-loadbalancerip-on-service
│   ├── 2.2.0-tls-ingress
│   ├── 2.2.1-snat-per-service-only-for-ns
│   ├── 2.3.0-networkpolicy-with-another-ns
│   ├── 2.3.2-allow-http
│   ├── 2.3.2-snat-per-namespace
│   ├── 2.4.0-service-with-loadbalancerip
│   ├── 2.4.0-service-with-sessionaffinity
│   ├── create_template.sh
│   ├── ncp-feature-namespace.yml
│   └── template
```