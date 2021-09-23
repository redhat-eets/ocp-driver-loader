#!/bin/bash
set -eu

if [[ "$(uname -r)" != ${KERNEL_VERSION}  ]]
then
echo "oot driver container was compiled for kernel version ${KERNEL_VERSION} but the running version is $(uname -r)"
exit 1
fi

mkdir -p /lib/modules/$(uname -r)/updates/drivers/net/ethernet/intel/iavf/

# Link OPAE drivers
ln -s /oot-driver/*.ko "/lib/modules/$(uname -r)/updates/drivers/net/ethernet/intel/iavf/"

depmod

rmmod iavf || true
modprobe iavf

echo "oot iavf driver loaded"

