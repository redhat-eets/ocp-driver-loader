# ocp-driver-loader

This repo provides a simple approach to load out-of-tree device driver onto openshift platform. It is 
for lab use - not for large scale deployment.

Two device drivers have been tested with this approach: ice, iavf.

For example, to load iavf driver onto workers that have a role label "worker-vm", run `DRIVER=iavf NODE_LABEL=worker-vm make build`, this will generate a machine config for openshift. Apply this machine 
config will cause the nodes with this label to reboot and the driver will be loaded after reboot. The full steps look like:
```
DRIVER=iavf NODE_LABEL=worker-vm make build
oc apply -f oot-driver-machine-config.yaml  # apply generated yaml
```

To load both ice and iavf drivers at the same time, and with specific driver versions,
```
DRIVER=ice,iavf ICE_DRIVER_VERSION=1.6.4 IAVF_DRIVER_VERSION=4.2.7 NODE_LABEL=worker-vm make build
oc apply -f oot-driver-machine-config.yaml  # apply generated yaml
```

To load the drivers for a custom kernel, for example if "NODE_LABEL" identifies the nodes that have a customer driver installed, first copy the customer kernel-core, kernel-devel files into the kernel folder, then build the drivers as normal, `DRIVER=iavf NODE_LABEL=worker-vm make build`. The build process will get the kernel information from the target machine, then search for the kernel packages under the kernel folder and use the customer kernel packages to build.
 
To unload the driver,
`oc delete -f oot-driver-machine-config.yaml`

## Background

The original work (https://github.com/openshift-kni/cnf-features-deploy/tree/master/tools/oot-driver) has a dependency on two operators: [Special Resource Operator](https://github.com/openshift-psap/special-resource-operator), [Node Feature Discovery Operator](https://docs.openshift.com/container-platform/4.8/scalability_and_performance/psap-node-feature-discovery-operator.html). For simple lab setup and quick trial, running these extra operators may not be necessary. Also, SRO (Special Resource Operator) is OCP 4.9 preview. To get it work with OCP 4.8 may not be smooth.

To make it simple, the dependency on the aforementioned operators is removed from the original work. The majority content of this repo is a direct copy from the origin work with minor modification to remove these  dependencies.

For lab use, driver binary signing is not included, though it is available in the original work.


