#!/bin/bash
set -eu

if [[ "$(uname -r)" != ${KERNEL_VERSION}  ]]
then
echo "oot driver container was compiled for kernel version ${KERNEL_VERSION} but the running version is $(uname -r)"
exit 1
fi

mkdir -p /lib/modules/$(uname -r)/updates/drivers/net/ethernet/intel/ice/
mkdir -p /lib/modules/$(uname -r)/updates/drivers/net/ethernet/intel/auxiliary/

# Link OPAE drivers
ln -s /oot-driver/ice.ko "/lib/modules/$(uname -r)/updates/drivers/net/ethernet/intel/ice/"
ln -s /oot-driver/auxiliary.ko "/lib/modules/$(uname -r)/updates/drivers/net/ethernet/intel/auxiliary/"

rmmod ice || true
rmmod auxiliary || true 

depmod
modprobe auxiliary
modprobe ice

echo "oot ice driver loaded"

