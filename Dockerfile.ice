ARG DRIVER_TOOLKIT_IMAGE
ARG OUTPUT_BASE_IMAGE=registry.access.redhat.com/ubi8:latest

FROM ${DRIVER_TOOLKIT_IMAGE} as builder
ARG KMODVER=1.6.4
ARG KVER

WORKDIR /build/

COPY kernel ./files/kernel
COPY driver ./files/driver

# install kernel package only when necessary
RUN if [[ "${KVER}" == *"rt"* ]]; then \
    RT="rt-" ;\
    KERNEL_CORE_FILE=$(rpm -qa | grep "kernel-rt-core-") ;\
    KERNEL_VERSION=`echo $KERNEL_CORE_FILE | sed "s#kernel-rt-core-##"` ;\
    else \
    RT="" ;\
    KERNEL_CORE_FILE=$(rpm -qa | grep "kernel-core-") ;\
    KERNEL_VERSION=`echo $KERNEL_CORE_FILE | sed "s#kernel-core-##"` ;\
    fi ;\
    if [[ "${KERNEL_VERSION}" != "${KVER}" ]]; then \
    rpm -Uvh --nodeps ./files/kernel/kernel-${RT}devel-${KVER}.rpm --force; \
    rpm -Uvh --nodeps ./files/kernel/kernel-${RT}core-${KVER}.rpm --force; \
    fi

    
RUN if [[ ! -e ./files/driver/ice-$KMODVER.tar.gz ]]; then \
        wget "https://sourceforge.net/projects/e1000/files/ice%20stable/$KMODVER/ice-$KMODVER.tar.gz" ;\
    else \
        mv ./files/driver/ice-$KMODVER.tar.gz ./ ;\
    fi

RUN tar zxf ice-$KMODVER.tar.gz
WORKDIR /build/ice-$KMODVER/src

# Prep and build the module
RUN BUILD_KERNEL=${KVER} KSRC=/lib/modules/$KVER/build/ make modules_install


FROM ${OUTPUT_BASE_IMAGE}
ARG KVER
ENV KERNEL_VERSION=$KVER

RUN dnf install --disablerepo=* --enablerepo=ubi-8-baseos --setopt=install_weak_deps=False -y kmod

COPY --from=builder /lib/modules/$KVER/updates/drivers/net/ethernet/intel/ice/ice.ko /oot-driver/
COPY --from=builder /lib/modules/$KVER/updates/drivers/net/ethernet/intel/auxiliary/auxiliary.ko /oot-driver/
COPY --from=builder /lib/modules/$KVER/modules.order /lib/modules/$KVER/modules.order
COPY --from=builder /lib/modules/$KVER/modules.builtin /lib/modules/$KVER/modules.builtin
COPY scripts/entrypoint.sh /usr/local/bin/
COPY scripts/ice-load.sh /usr/local/bin/load.sh
COPY scripts/ice-unload.sh /usr/local/bin/unload.sh
RUN chmod +x /usr/local/bin/load.sh
RUN chmod +x /usr/local/bin/unload.sh

CMD ["/entrypoint.sh"]

