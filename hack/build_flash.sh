#!/bin/bash
set -eu

export DRIVER_TOOLKIT_IMAGE=$1; shift
export KERNEL_VERSION=$1; shift
export REGISTRY=$1; shift
export IMAGE_DIR=$1; shift
export KMODVER=$1; shift
export IMAGE_NAME=$1; shift
export FW_TOOL_URL=$1; shift

export ICE_IMAGE=${REGISTRY}/${IMAGE_DIR}/ice-driver-container:${KERNEL_VERSION}

podman build --build-arg KVER=${KERNEL_VERSION} --build-arg DRIVER_TOOLKIT_IMAGE=${DRIVER_TOOLKIT_IMAGE} --build-arg KMODVER=${KMODVER} -t ${ICE_IMAGE} -f Dockerfile.ice .

tag=${REGISTRY}/${IMAGE_DIR}/${IMAGE_NAME}:${KERNEL_VERSION}
podman build --build-arg ICE_IMAGE=${ICE_IMAGE} --build-arg KVER=${KERNEL_VERSION} --build-arg FW_TOOL_URL=${FW_TOOL_URL} -t ${tag} -f Dockerfile.${IMAGE_NAME} . 
podman push --tls-verify=false ${tag} 
