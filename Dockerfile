FROM registry.ci.openshift.org/origin/4.12:artifacts as artifacts

FROM quay.io/coreos-assembler/fcos:testing-devel
ARG FEDORA_COREOS_VERSION=412.36.0

WORKDIR /go/src/github.com/openshift/okd-machine-os
COPY . .
COPY --from=artifacts /srv/repo/*.rpm /tmp/rpms/
RUN cat /etc/os-release \
    && rpm-ostree --version \
    && ostree --version \
    && cp -irvf overlay.d/*/* / \
    && systemctl enable gcp-routes gcp-hostname \
    && cp -irvf bootstrap / \
    && cp -irvf manifests / \
    && cp -ivf *.repo /etc/yum.repos.d/ \
    && rpm-ostree install \
        NetworkManager-ovs \
        open-vm-tools \
        qemu-guest-agent \
        cri-o \
        cri-tools \
        /tmp/rpms/openshift-clients-[0-9]*.rpm \
        /tmp/rpms/openshift-hyperkube-*.rpm \
    && rpm-ostree override replace \
         --experimental --freeze \
         --from repo=coreos-continuous \
         rpm-ostree rpm-ostree-libs \
         https://kojipkgs.fedoraproject.org//packages/kernel/5.19.7/200.fc36/x86_64/kernel-5.19.7-200.fc36.x86_64.rpm \
         https://kojipkgs.fedoraproject.org//packages/kernel/5.19.7/200.fc36/x86_64/kernel-core-5.19.7-200.fc36.x86_64.rpm \
         https://kojipkgs.fedoraproject.org//packages/kernel/5.19.7/200.fc36/x86_64/kernel-modules-5.19.7-200.fc36.x86_64.rpm \
    && rpm-ostree cleanup -m \
    && sed -i 's/^enabled=1/enabled=0/g' /etc/yum.repos.d/*.repo \
    && rm -rf /go /tmp/rpms /var/cache
LABEL io.openshift.release.operator=true \
      io.openshift.build.version-display-names="machine-os=Fedora CoreOS" \
      io.openshift.build.versions="machine-os=${FEDORA_COREOS_VERSION}"
ENTRYPOINT ["/noentry"]
