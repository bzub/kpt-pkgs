# syntax = docker.io/docker/dockerfile-upstream:1.4.0

ARG GOLANG_IMAGE
ARG KPT_IMAGE
ARG KIND_IMAGE
ARG KUBECTL_IMAGE
ARG CLUSTERCTL_V0_3_IMAGE
ARG CLUSTERCTL_V0_4_IMAGE
ARG CLUSTERCTL_V1_1_IMAGE
ARG KPT_FN_SEARCH_REPLACE_IMAGE
ARG KPT_FN_SET_ANNOTATIONS_IMAGE
ARG KPT_FN_SET_NAMESPACE_IMAGE
ARG KPT_FN_CREATE_SETTERS_IMAGE
ARG KPT_FN_APPLY_SETTERS_IMAGE
ARG KPT_FN_STARLARK_IMAGE

FROM $GOLANG_IMAGE as golang
FROM $KPT_IMAGE as kpt
FROM $KIND_IMAGE as kind
FROM $KUBECTL_IMAGE as kubectl
FROM $CLUSTERCTL_V0_3_IMAGE as clusterctl-v0_3
FROM $CLUSTERCTL_V0_4_IMAGE as clusterctl-v0_4
FROM $CLUSTERCTL_V1_1_IMAGE as clusterctl-v1_1
FROM $KPT_FN_SEARCH_REPLACE_IMAGE as kpt-fn-search-replace
FROM $KPT_FN_SET_ANNOTATIONS_IMAGE as kpt-fn-set-annotations
FROM $KPT_FN_SET_NAMESPACE_IMAGE as kpt-fn-set-namespace
FROM $KPT_FN_CREATE_SETTERS_IMAGE as kpt-fn-create-setters
FROM $KPT_FN_APPLY_SETTERS_IMAGE as kpt-fn-apply-setters
FROM $KPT_FN_STARLARK_IMAGE as kpt-fn-starlark

FROM golang as tools
RUN apk add -U git build-base curl bash docker
COPY --link --from=kpt /kpt /usr/local/bin/kpt
COPY --link --from=kind /kind /usr/local/bin/kind
COPY --link --from=kubectl /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/kubectl
COPY --link --from=clusterctl-v0_3 /clusterctl /usr/local/bin/clusterctl-v0_3
COPY --link --from=clusterctl-v0_4 /clusterctl /usr/local/bin/clusterctl-v0_4
COPY --link --from=clusterctl-v1_1 /clusterctl /usr/local/bin/clusterctl-v1_1
COPY --link --from=kpt-fn-search-replace /usr/local/bin/function /usr/local/bin/kpt-fn-search-replace
COPY --link --from=kpt-fn-set-annotations /usr/local/bin/function /usr/local/bin/kpt-fn-set-annotations
COPY --link --from=kpt-fn-set-namespace /usr/local/bin/function /usr/local/bin/kpt-fn-set-namespace
COPY --link --from=kpt-fn-create-setters /usr/local/bin/function /usr/local/bin/kpt-fn-create-setters
COPY --link --from=kpt-fn-apply-setters /usr/local/bin/function /usr/local/bin/kpt-fn-apply-setters
COPY --link --from=kpt-fn-starlark /usr/local/bin/function /usr/local/bin/kpt-fn-starlark
# Workaround talos to siderolabs github org rename.
ARG CLUSTERCTL_CONFIG="/root/.cluster-api/clusterctl.yaml"
COPY --link <<eot ${CLUSTERCTL_CONFIG}
providers:
  - name: "talos"
    url: "https://github.com/siderolabs/cluster-api-bootstrap-provider-talos/releases/latest/bootstrap-components.yaml"
    type: "BootstrapProvider"
  - name: "talos"
    url: "https://github.com/siderolabs/cluster-api-control-plane-provider-talos/releases/latest/control-plane-components.yaml"
    type: "ControlPlaneProvider"
  - name: "sidero"
    url: "https://github.com/siderolabs/sidero/releases/latest/infrastructure-components.yaml"
    type: "InfrastructureProvider"
eot

FROM tools as kpt-sink-render-from-url
ARG PACKAGE_PATH
ARG RESOURCES_URL
ARG REPO_KPTFILE="./Kptfile"
COPY --link ${REPO_KPTFILE} /pkgs/Kptfile
RUN curl -L "${RESOURCES_URL}" | kpt fn sink "/pkgs/${PACKAGE_PATH}"
COPY --link ${PACKAGE_PATH}/Kptfile /pkgs/${PACKAGE_PATH}/Kptfile
RUN sed -i 's|image: gcr.io/kpt-fn/\(.*\):.*|exec: /usr/local/bin/kpt-fn-\1|' /pkgs/Kptfile
RUN sed -i 's|image: gcr.io/kpt-fn/\(.*\):.*|exec: /usr/local/bin/kpt-fn-\1|' /pkgs/${PACKAGE_PATH}/Kptfile
RUN kpt fn render --allow-exec --truncate-output=false "/pkgs"
RUN rm "/pkgs/${PACKAGE_PATH}/Kptfile"
RUN cp -r "/pkgs/${PACKAGE_PATH}" /pkg

FROM scratch as pkg
COPY --link --from=kpt-sink-render-from-url /pkg /

FROM tools as clusterctl-provider-kpt-sink
ARG CLUSTERCTL
ARG PROVIDER_TYPE
ARG PROVIDER_NAME
ARG PROVIDER_VERSION
ARG PROVIDER_COMPONENTS_URL="none"
ARG SECRETS_ENV_FILE="/run/secrets/secrets-env"
ENV SECRETS_ENV_FILE=${SECRETS_ENV_FILE}
# Workaround talos to siderolabs github org rename.
ARG CLUSTERCTL_CONFIG="/root/.cluster-api/clusterctl.yaml"

RUN --mount=type=secret,id=secrets-env <<eot
#!/usr/bin/env sh
set -euxo pipefail

if [ -f "${SECRETS_ENV_FILE}" ]; then
  set -a; . "${SECRETS_ENV_FILE}"; set +a
fi

# Workaround talos to siderolabs github org rename.
touch /root/.cluster-api/clusterctl.yaml

if [ "${PROVIDER_COMPONENTS_URL}" != "none" ]; then
  curl -L "${PROVIDER_COMPONENTS_URL}" \
  | clusterctl-v1_1 generate yaml \
  | sed '/^rules: \[\]$/d' \
  | kpt fn sink "/pkg"
  exit 0
fi

provider_arg="--${PROVIDER_TYPE}=${PROVIDER_NAME}:${PROVIDER_VERSION}"

case "${CLUSTERCTL}" in
  clusterctl-v0_3)
    "${CLUSTERCTL}" config provider "${provider_arg}" -o yaml \
    | sed '/^rules: \[\]$/d' \
    | kpt fn sink "/pkg"
    ;;
  *)
    "${CLUSTERCTL}" generate provider "${provider_arg}" \
    | sed '/^rules: \[\]$/d' \
    | kpt fn sink "/pkg"
esac
eot

FROM scratch as cluster-api-provider-upstream
COPY --link --from=clusterctl-provider-kpt-sink /pkg /

FROM tools as cluster-api-provider-pkg-render
ARG CLUSTERCTL
ARG PROVIDER_TYPE
ARG PROVIDER_NAME
ARG PROVIDER_VERSION
ARG CAPI_API_GROUP
ARG PKG_PATH="cluster-api/${CAPI_API_GROUP}/${PROVIDER_TYPE}/${PROVIDER_NAME}"
ARG KPTFILE_SRC="${PKG_PATH}/Kptfile"
COPY --link ./Kptfile /kpt-files/Kptfile
COPY --link cluster-api/Kptfile /kpt-files/cluster-api/Kptfile
COPY --link ${KPTFILE_SRC} /kpt-files/${KPTFILE_SRC}
COPY --link --from=cluster-api-provider-upstream / /kpt-files/${PKG_PATH}
RUN sed -i 's|image: gcr.io/kpt-fn/\(.*\):.*|exec: /usr/local/bin/kpt-fn-\1|' /kpt-files/Kptfile
RUN sed -i 's|image: gcr.io/kpt-fn/\(.*\):.*|exec: /usr/local/bin/kpt-fn-\1|' /kpt-files/cluster-api/Kptfile
RUN sed -i 's|image: gcr.io/kpt-fn/\(.*\):.*|exec: /usr/local/bin/kpt-fn-\1|' "/kpt-files/${KPTFILE_SRC}"
RUN kpt fn render --allow-exec --truncate-output=false /kpt-files
RUN cp -r "/kpt-files/${PKG_PATH}" /pkg
RUN find /pkg -type f -name 'Kptfile' -delete

FROM scratch as cluster-api-provider-pkg
COPY --link --from=cluster-api-provider-pkg-render /pkg /

# generate workload clusters

FROM tools as clusterctl-cluster-kpt-sink
ARG CLUSTERCTL
ARG PROVIDER_NAME
ARG PROVIDER_VERSION
ARG PROVIDER_COMPONENTS_URL="none"
ARG TARGET_NAMESPACE=default
ARG CONTROL_PLANE_ENDPOINT="127.0.0.1"
ENV CONTROL_PLANE_ENDPOINT="${CONTROL_PLANE_ENDPOINT}"
ARG CONTROL_PLANE_PORT="6443"
ENV CONTROL_PLANE_PORT="${CONTROL_PLANE_PORT}"
ARG CONTROL_PLANE_SERVERCLASS="${PROVIDER_NAME}-cluster-control-plane"
ENV CONTROL_PLANE_SERVERCLASS="${CONTROL_PLANE_SERVERCLASS}"
ARG WORKER_SERVERCLASS="${PROVIDER_NAME}-cluster-workers"
ENV WORKER_SERVERCLASS="${WORKER_SERVERCLASS}"
ARG TALOS_VERSION="v0.14"
ENV TALOS_VERSION="${TALOS_VERSION}"
ARG KUBERNETES_VERSION="v1.20.15"
ENV KUBERNETES_VERSION="${KUBERNETES_VERSION}"
ARG SECRETS_ENV_FILE="/run/secrets/secrets-env"
ENV SECRETS_ENV_FILE=${SECRETS_ENV_FILE}
# Workaround talos to siderolabs github org rename.
ARG CLUSTERCTL_CONFIG="/root/.cluster-api/clusterctl.yaml"

RUN --mount=type=secret,id=secrets-env <<eot
#!/usr/bin/env sh
set -euxo pipefail

if [ -f "${SECRETS_ENV_FILE}" ]; then
  set -a; . "${SECRETS_ENV_FILE}"; set +a
fi

# Workaround talos to siderolabs github org rename.
touch /root/.cluster-api/clusterctl.yaml

provider_arg="--infrastructure=${PROVIDER_NAME}:${PROVIDER_VERSION}"

"${CLUSTERCTL}" config cluster "cluster" "${provider_arg}" --target-namespace="${TARGET_NAMESPACE}" \
| grep -Fv '  namespace: default' \
| kpt fn sink "/pkg"
eot

FROM scratch as cluster-api-cluster-upstream
COPY --link --from=clusterctl-cluster-kpt-sink /pkg /

FROM tools as cluster-api-cluster-pkg-render
ARG CLUSTERCTL
ARG PROVIDER_TYPE
ARG PROVIDER_NAME
ARG PROVIDER_VERSION
ARG CAPI_API_GROUP
ARG PKG_PATH="cluster-api/${CAPI_API_GROUP}/cluster/${PROVIDER_NAME}"
ARG KPTFILE_SRC="${PKG_PATH}/Kptfile"
COPY --link ./Kptfile /kpt-files/Kptfile
COPY --link cluster-api/Kptfile /kpt-files/cluster-api/Kptfile
COPY --link ${KPTFILE_SRC} /kpt-files/${KPTFILE_SRC}
COPY --link --from=cluster-api-cluster-upstream / /kpt-files/${PKG_PATH}
RUN sed -i 's/apply-setters/create-setters/' "/kpt-files/${KPTFILE_SRC}"
RUN sed -i 's|image: gcr.io/kpt-fn/\(.*\):.*|exec: /usr/local/bin/kpt-fn-\1|' /kpt-files/Kptfile
RUN sed -i 's|image: gcr.io/kpt-fn/\(.*\):.*|exec: /usr/local/bin/kpt-fn-\1|' /kpt-files/cluster-api/Kptfile
RUN sed -i 's|image: gcr.io/kpt-fn/\(.*\):.*|exec: /usr/local/bin/kpt-fn-\1|' "/kpt-files/${KPTFILE_SRC}"
RUN kpt fn render --allow-exec --truncate-output=false /kpt-files
RUN cp -r "/kpt-files/${PKG_PATH}" /pkg
RUN find /pkg -type f -name 'Kptfile' -delete

FROM scratch as cluster-api-cluster-pkg
COPY --link --from=cluster-api-cluster-pkg-render /pkg /

FROM tools as git-tag-packages-build
ARG GIT_TAGS
ENV GIT_TAGS=${GIT_TAGS}
COPY --link .git /repo/.git
WORKDIR /repo
RUN <<EOT
#!/usr/bin/env sh
set -euxo pipefail

for tag in $(echo "${GIT_TAGS}"); do
  git tag --force "${tag}"
done
EOT

FROM scratch as git-tag-packages
COPY --link --from=git-tag-packages-build /repo/.git /
