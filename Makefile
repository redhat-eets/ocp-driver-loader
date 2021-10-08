REGISTRY ?= 10.16.231.113:5000
REGISTRY_USER ?= "openshift"
REGISTRY_PASSWORD ?= "redhat"
REGISTRY_CERT ?= "domain.crt"
OPENSHIFT_SECRET_FILE ?= pull-secrets.json 
KUBECONFIG ?= $(HOME)/.kube/config
NODE_LABEL ?= "worker-cnf"

$(shell oc get secret/pull-secret -n openshift-config --template='{{index .data ".dockerconfigjson" | base64decode}}' > ${OPENSHIFT_SECRET_FILE})
$(shell oc registry login --skip-check --registry="${REGISTRY}" --auth-basic="${REGISTRY_USER}:${REGISTRY_PASSWORD}" --to=${OPENSHIFT_SECRET_FILE})
$(shell oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=${OPENSHIFT_SECRET_FILE})

DRIVER_TOOLKIT_IMAGE ?= $(shell oc adm release info --image-for=driver-toolkit)
KERNEL_VERSION ?= $(shell hack/get_kernel_version_from_node.sh $(NODE_LABEL) $(KUBECONFIG))

STD_KERNEL_VERSIONS := $(shell hack/get_kernel_version.sh $(DRIVER_TOOLKIT_IMAGE) $(OPENSHIFT_SECRET_FILE))

CUSTOM_KERNEL_FILES := $(wildcard kernel/*$(KERNEL_VERSION).rpm)
# DRIVER: comma seperated driver name, for example, "ice,iavf"
DRIVER ?= ice
ICE_DRIVER_VERSION ?= 1.7.0_rc79
IAVF_DRIVER_VERSION ?= 4.2.7
DPDK_VERSION ?= 20.11.1

IMAGE_DIR ?= oot-driver

.PHONY: registry_cert login_registry build check_kernel

registry_cert:
	@{ \
	set -e ;\
	oc delete configmap registry-cas -n openshift-config 2>/dev/null || true \
	oc create configmap registry-cas -n openshift-config --from-file=$(subst :,..,${REGISTRY})=${REGISTRY_CERT} \
	oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-cas"}}}' --type=merge \
	}

login_registry:
ifdef REGISTRY_USER
	podman login --tls-verify=false -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${REGISTRY}
endif

build: check_kernel login_registry 
	hack/build.sh $(DRIVER_TOOLKIT_IMAGE) $(KERNEL_VERSION) $(DRIVER) $(REGISTRY) $(IMAGE_DIR) $(NODE_LABEL) "ice=$(ICE_DRIVER_VERSION),iavf=$(IAVF_DRIVER_VERSION),dpdk=${DPDK_VERSION}"


check_kernel:
ifeq (,$(findstring $(KERNEL_VERSION),$(STD_KERNEL_VERSIONS)))
        $(info KERNEL_VERSION: $(KERNEL_VERSION); STD_KERNEL_VERSIONS: $(STD_KERNEL_VERSIONS))
	$(info using customer kernel, checking kernel folder for packages)
	@{ \
	set -eu ;\
	echo $(CUSTOM_KERNEL_FILES) ;\
	if [ -z "$(CUSTOM_KERNEL_FILES)" ]; then \
	echo "please copy kernel-core, kernel-devel files to kernel folder and try again" ;\
	false ;\
	else echo "found customer kernel files under kernel folder" ;\
	fi ;\
	}
endif
 
deploy: build
	oc create -f oot-driver-machine-config.yaml

destroy:
	oc delete -f oot-driver-machine-config.yaml

cleanup_images:
	@podman rmi -f $$(podman images -f dangling=true -q) 2>/dev/null || true
