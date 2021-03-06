FROM golang:1.9.1-stretch AS build_kubernetes
# rsync: building k8s
RUN apt update && apt install -y --no-install-recommends rsync
ARG K8S_VERSION=v1.10.0-alpha.0
WORKDIR /go/src/k8s.io/kubernetes
RUN git clone -b $K8S_VERSION https://github.com/kubernetes/kubernetes . \
    && make WHAT=cmd/kubectl \
    && make WHAT=test/e2e/e2e.test \
    && make ginkgo \
    && go build hack/e2e.go \
    && ./e2e

FROM golang:1.8.3-stretch AS build_acs-engine
ARG ACSENGINE_VERSION=v0.10.0
WORKDIR /go/src/github.com/Azure/acs-engine
RUN git clone -b $ACSENGINE_VERSION https://github.com/Azure/acs-engine . \
    && make

FROM microsoft/dotnet:2.0-sdk-stretch AS build_kautil
WORKDIR /build
COPY kautil .
RUN dotnet publish -c release -r debian.8-x64 -o publish \
    && chmod 755 publish/kautil

FROM buildpack-deps:stretch-scm
# libunwind8: used by dotnet core, libxml-simple-perl, used by junit_combine
RUN apt update && apt install -y --no-install-recommends libunwind8 libxml-simple-perl
ENV GOPATH="/home/k8s-ci/go"
COPY --from=build_kubernetes /go ${GOPATH}
COPY --from=build_acs-engine /go/src/github.com/Azure/acs-engine/bin/acs-engine /usr/local/bin/
COPY --from=build_kautil /build/publish /opt/k8s-azure/kautil
COPY k8s-azure /opt/k8s-azure/
COPY manifest /opt/k8s-azure/manifest
RUN ["/bin/bash", "-c", "ln -s /opt/k8s-azure/{k8s-azure,kautil/kautil} /usr/local/bin"]
ENV K8S_AZURE_MANIFEST_DIR='/opt/k8s-azure/manifest'
RUN useradd -m k8s-ci
