#!/bin/bash
set -eu

if [[ "$(uname -r)" != ${KERNEL_VERSION}  ]]
then
echo "oot driver container was compiled for kernel version ${KERNEL_VERSION} but the running version is $(uname -r)"
exit 1
fi

# Unload will return the in-tree driver
rmmod ice
rmmod auxiliary

rm -rf /lib/modules/$(uname -r)/updates/drivers/net/ethernet/intel/auxiliary/ || true
rm -rf /lib/modules/$(uname -r)/updates/drivers/net/ethernet/intel/ice/ || true

depmod
modprobe ice

echo "oot ice driver unloaded and in tree driver was reloaded"

