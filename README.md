# ocp-driver-loader

This repo provides a simple approach to load out-of-tree device driver onto openshift platform. It is 
for lab use - not for large scale deployment.

Two device drivers have been tested with this approach: ice, iavf.

For example, to load iavf driver onto workers that have a role label "worker-vm", run `DRIVER=iavf NODE_LABEL=worker-vm make build`, this will generate a machine config for openshift. Apply this machine 
config will cause the nodes with this label to reboot and the driver will be loaded after reboot. The full steps look like:
```
DRIVER=iavf NODE_LABEL=worker-vm make build
oc apply -f examples/mcp-worker-vm.yaml     # pre-defined yaml
oc apply -f oot-driver-machine-config.yaml  # generated yaml
```

To load both ice and iavf drivers at the same time, and with specific driver versions,
```
DRIVER=ice,iavf ICE_DRIVER_VERSION=1.6.4 IAVF_DRIVER_VERSION=4.2.7 NODE_LABEL=worker-vm make build
oc apply -f examples/mcp-worker-vm.yaml     # pre-defined yaml
oc apply -f oot-driver-machine-config.yaml  # generated yaml
```

To load the drivers for a custom kernel, for example if "NODE_LABEL" identifies the nodes that have a customer driver installed, first copy the customer kernel-core, kernel-devel files into the kernel folder, then build the drivers as normal, `DRIVER=iavf NODE_LABEL=worker-vm make build`. The build process will get the kernel information from the target machine, then search for the kernel packages under the kernel folder and use the customer kernel packages to build.
 
To unload the driver,
`oc delete -f oot-driver-machine-config.yaml`

 
