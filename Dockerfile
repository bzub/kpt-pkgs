# syntax = docker.io/docker/dockerfile-upstream:1.4.0-rc2

ARG GOLANG_IMAGE
ARG KPT_IMAGE
ARG KIND_IMAGE
ARG CLUSTERCTL_V0_3_IMAGE
ARG CLUSTERCTL_V0_4_IMAGE
ARG CLUSTERCTL_V1_1_IMAGE

FROM $GOLANG_IMAGE as golang
FROM $KPT_IMAGE as kpt
FROM $KIND_IMAGE as kind
FROM $CLUSTERCTL_V0_3_IMAGE as clusterctl-v0_3
FROM $CLUSTERCTL_V0_4_IMAGE as clusterctl-v0_4
FROM $CLUSTERCTL_V1_1_IMAGE as clusterctl-v1_1

FROM golang as tools
RUN apk add -U git build-base curl bash docker
COPY --link --from=kpt /kpt /usr/local/bin/kpt
COPY --link --from=kind /kind /usr/local/bin/kind
COPY --link --from=clusterctl-v0_3 /clusterctl /usr/local/bin/clusterctl-v0_3
COPY --link --from=clusterctl-v0_4 /clusterctl /usr/local/bin/clusterctl-v0_4
COPY --link --from=clusterctl-v1_1 /clusterctl /usr/local/bin/clusterctl-v1_1

FROM tools as kpt-sink-render-from-url
ARG DOCKER_HOST
ENV DOCKER_HOST=${DOCKER_HOST}
ARG PACKAGE_PATH
ARG RESOURCES_URL
RUN curl -L "${RESOURCES_URL}" | kpt fn sink "/pkg"
COPY --link ${PACKAGE_PATH}/Kptfile /pkg/Kptfile
RUN kpt fn render /pkg && rm /pkg/Kptfile

FROM scratch as pkg
COPY --link --from=kpt-sink-render-from-url /pkg /

FROM tools as clusterctl-provider-kpt-sink
ARG GITHUB_TOKEN
ENV GITHUB_TOKEN=${GITHUB_TOKEN}
ARG CLUSTERCTL
ARG PROVIDER_TYPE
ARG PROVIDER_NAME
ARG PROVIDER_VERSION
RUN <<eot
#!/usr/bin/env sh
set -euxo pipefail

provider_arg="--${PROVIDER_TYPE}=${PROVIDER_NAME}:${PROVIDER_VERSION}"

case "${CLUSTERCTL}" in
  clusterctl-v0_3)
    "${CLUSTERCTL}" config provider "${provider_arg}" -o yaml \
    | kpt fn sink "/pkg"
    ;;
  *)
    "${CLUSTERCTL}" generate provider "${provider_arg}" \
    | kpt fn sink "/pkg"
esac
eot

FROM scratch as cluster-api-provider-upstream
COPY --link --from=clusterctl-provider-kpt-sink /pkg /

FROM tools as cluster-api-provider-pkg-render
ARG GITHUB_TOKEN
ENV GITHUB_TOKEN=${GITHUB_TOKEN}
ARG DOCKER_HOST
ENV DOCKER_HOST=${DOCKER_HOST}
ARG CLUSTERCTL
ARG PROVIDER_TYPE
ARG PROVIDER_NAME
ARG PROVIDER_VERSION
ARG CAPI_API_GROUP
ARG PKG_PATH="cluster-api/${CAPI_API_GROUP}/${PROVIDER_TYPE}/${PROVIDER_NAME}"
ARG KPTFILE_SRC="${PKG_PATH}/Kptfile"
COPY --link Kptfile /kpt-files/Kptfile
COPY --link cluster-api/Kptfile /kpt-files/cluster-api/Kptfile
COPY --link ${KPTFILE_SRC} /kpt-files/${KPTFILE_SRC}
COPY --link --from=cluster-api-provider-upstream / /kpt-files/${PKG_PATH}
RUN kpt fn render /kpt-files
RUN cp -r "/kpt-files/${PKG_PATH}" /pkg
RUN find /pkg -type f -name 'Kptfile' -delete

FROM scratch as cluster-api-provider-pkg
COPY --link --from=cluster-api-provider-pkg-render /pkg /
