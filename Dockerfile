FROM  debian:stretch-slim

ADD ./bin/sriov /usr/src/sriov-cni/bin/sriov
ADD ./bin/fixipam /usr/src/sriov-cni/bin/fixipam
ADD ./k8s-installer/installer.sh /installer/
ADD ./k8s-installer/10-sriov-cni.conf /installer/
ADD ./k8s-installer/installer_sleep.sh /installer/

WORKDIR /

LABEL io.k8s.display-name="SR-IOV CNI"

ADD ./images/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
