# ocp-driver-loader

## Install out-of-tree driver in openshift
 
This repo provides a simple approach to load out-of-tree device driver onto openshift platform. It is 
for lab use - not for large scale deployment.

Two device drivers have been tested with this approach: ice, iavf.

For example, to load iavf driver onto workers that have a role label "worker-vm", run `DRIVER=iavf NODE_LABEL=worker-vm make build`, this will generate a machine config for openshift. Apply this machine 
config will cause the nodes with this label to reboot and the driver will be loaded after reboot. The full steps look like:
```
DRIVER=iavf NODE_LABEL=worker-vm make build
oc apply -f oot-driver-machine-config.yaml  # apply generated yaml
```

A MachineConfigPool needs to be defined (or pre-defined). A sample MachineConfigPool is shown below,
```
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfigPool
metadata:
  name: worker-vm
  namespace: openshift-machine-config-operator
  labels:
    machineconfiguration.openshift.io/role: worker-vm
spec:
  paused: false
  machineConfigSelector:
    matchExpressions:
      - key: machineconfiguration.openshift.io/role
        operator: In
        values: [worker,worker-vm]
  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/worker-vm: ""
```

To load both ice and iavf drivers at the same time, and with specific driver versions,
```
DRIVER=ice,iavf ICE_DRIVER_VERSION=1.6.4 IAVF_DRIVER_VERSION=4.2.7 NODE_LABEL=worker-vm make build
oc apply -f oot-driver-machine-config.yaml
```

To load the drivers for a custom kernel, for example if "NODE_LABEL" identifies the nodes that have a customer driver installed, first copy the customer kernel-core, kernel-devel files into the kernel folder, then build the drivers as normal, `DRIVER=iavf NODE_LABEL=worker-vm make build`. The build process will get the kernel information from the target machine, then search for the kernel packages under the kernel folder and use the customer kernel packages to build.
 
To unload the driver,
`oc delete -f oot-driver-machine-config.yaml`

## Custom kernel

Sometimes the openshift node might use a customer kernel, not the default kernel shipped by openshift. To install driver for the customer kernel, the customer kernel files can be downloaded and put under the kernel directory before build the image, for example,
```
kernel/kernel-core-4.18.0-240.22.1.el8_3.x86_64.rpm
kernel/kernel-devel-4.18.0-240.22.1.el8_3.x86_64.rpm
```

The env KERNEL_VERSION need to set to the customer kernel version,
```
export KERNEL_VERSION=4.18.0-240.22.1.el8_3.x86_64
make build
```

## Update E810 firmware

First build a container which the ice driver and the firmware update tool.
```
export ICE_DRIVER_VERSION=1.6.4
export FW_TOOL_URL=https://downloadmirror.intel.com/29738/eng/e810_nvmupdatepackage_v3_00_linux.tar_.gz
make e810
```

This will build a container image of name form e810:<kernel-version>. When this container image is run, it will install this ice driver. One can get inside the container and use the firmware update tool.

For example,
```
cat <<EOF | oc create -f -
apiVersion: v1 
kind: Pod 
metadata:
  name: e810
spec:
  restartPolicy: Never
  hostNetwork: true
  containers:
  - name: e810
    image: 10.16.231.128:5000/oot-driver/e810:4.18.0-240.22.1.el8_3.x86_64
    imagePullPolicy: Always
    securityContext:
      privileged: true
  nodeSelector:
    node-role.kubernetes.io/worker-cnf: ""
EOF

oc exec -it e810 sh
# use the firmware update tool inside the container 
```

If using podman on the node directly,
```
podman pull 10.16.231.128:5000/oot-driver/e810:4.18.0-240.22.1.el8_3.x86_64 --tls-verify=false
podman run --net host --name e810 --rm -d --privileged 10.16.231.128:5000/oot-driver/e810:4.18.0-240.22.1.el8_3.x86_64
podman exec -it e810 sh
# use the firmware update tool inside the container 
```

## Background

The original work (https://github.com/openshift-kni/cnf-features-deploy/tree/master/tools/oot-driver) has a dependency on two operators: [Special Resource Operator](https://github.com/openshift-psap/special-resource-operator), [Node Feature Discovery Operator](https://docs.openshift.com/container-platform/4.8/scalability_and_performance/psap-node-feature-discovery-operator.html). For simple lab setup and quick trial, running these extra operators may not be necessary. Also, SRO (Special Resource Operator) is OCP 4.9 preview. To get it work with OCP 4.8 may not be smooth.

To make it simple, the dependency on the aforementioned operators is removed from the original work. The majority content of this repo is a direct copy from the origin work with minor modification to remove these  dependencies.

For lab use, driver binary signing is not included, though it is available in the original work.


