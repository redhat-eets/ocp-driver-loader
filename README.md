# ocp-driver-loader

This repo provides a simple approach to load out-of-tree device driver onto openshift platform. It is 
for lab use - not for large scale deployment.

Two device drivers have been tested with this approach: ice, iavf.

For example, to load iavf driver onto workers that have a role label "worker-vm", run `DRIVER=iavf NODE_LABEL=worker-vm make build`, this will generate a machine config for openshift. Apply this machine 
config will cause the nodes with this label to reboot and the driver will be loaded after reboot. So the full steps looks like:
```
DRIVER=iavf NODE_LABEL=worker-vm make build
oc apply -f examples/mcp-worker-vm.yaml     # pre-defined yaml
oc apply -f oot-driver-machine-config.yaml  # generated yaml
```
