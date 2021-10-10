#!/bin/bash
set -eu

export DRIVER_TOOLKIT_IMAGE=$1; shift
export KERNEL_VERSION=$1; shift
export DRIVER=$1; shift
export REGISTRY=$1; shift
export IMAGE_DIR=$1; shift
export NODE_LABEL=$1; shift
export VERSIONS=$1; shift

# build machine config first half content
export SCRIPT=`base64 -w 0 ./scripts/oot-driver`
envsubst <  ./templates/oot-driver-machine-config.yaml.template > "./oot-driver-machine-config.yaml"

# build image for each driver and fill second half machine config

# DRIVER is a comma seperated driver name list, for example "iavf,ice,dpdk"
IFS=',' read -r -a array_driver <<< "${DRIVER}"

# VERSIONS is a comma seperated kay=value string
IFS=',' read -r -a array_version <<< "${VERSIONS}"

for assignment in ${array_version[@]}; do
    eval "${assignment}"
done

for driver in ${array_driver[@]}; do
    export OOT_DRIVER_NAME=${driver}
    export OOT_DRIVER_IMAGE_NAME=${IMAGE_DIR}/${driver}-driver-container
    envsubst < "./templates/systemd.template" >> "./oot-driver-machine-config.yaml"
    podman build --build-arg KVER=${KERNEL_VERSION} --build-arg DRIVER_TOOLKIT_IMAGE=${DRIVER_TOOLKIT_IMAGE} --build-arg KMODVER=$(eval echo \$${driver}) -t ${REGISTRY}/${OOT_DRIVER_IMAGE_NAME}:${KERNEL_VERSION} -f Dockerfile.${driver} . 
    podman push --tls-verify=false ${REGISTRY}/${OOT_DRIVER_IMAGE_NAME}:${KERNEL_VERSION}
done
