# syntax = docker.io/docker/dockerfile-upstream:1.4.2

ARG FETCH_RESOURCES_IMAGE=scratch
ARG PKG_SINK_SOURCE
ARG OUT_DIR=/_out
ARG IN_DIR=/_in

FROM docker.io/library/golang:1.17.9-alpine3.15 as golang

FROM golang as mdrip-build
RUN apk add -U git
ARG MDRIP_GIT_REF=v1.0.2
RUN go install "github.com/monopole/mdrip@${MDRIP_GIT_REF}"

FROM alpine as tools
RUN apk add -U git curl bash jq
COPY --link --from=kpt /usr/local/bin/kpt /usr/local/bin/kpt-bin
COPY --link --from=clusterctl /clusterctl /usr/local/bin/clusterctl
COPY --link --from=kubectl /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/kubectl
COPY --link --from=kpt-fn-search-replace /usr/local/bin/function /usr/local/bin/kpt-fn-search-replace
COPY --link --from=kpt-fn-set-annotations /usr/local/bin/function /usr/local/bin/kpt-fn-set-annotations
COPY --link --from=kpt-fn-set-namespace /usr/local/bin/function /usr/local/bin/kpt-fn-set-namespace
COPY --link --from=kpt-fn-create-setters /usr/local/bin/function /usr/local/bin/kpt-fn-create-setters
COPY --link --from=kpt-fn-apply-setters /usr/local/bin/function /usr/local/bin/kpt-fn-apply-setters
COPY --link --from=kpt-fn-starlark /usr/local/bin/function /usr/local/bin/kpt-fn-starlark
COPY --link --from=kpt-fn-set-labels /usr/local/bin/function /usr/local/bin/kpt-fn-set-labels
COPY --link --from=kpt-fn-ensure-name-substring /usr/local/bin/function /usr/local/bin/kpt-fn-ensure-name-substring
COPY --link --from=kpt-fn-apply-replacements /usr/local/bin/function /usr/local/bin/kpt-fn-apply-replacements
COPY --link --from=kpt-fn-gatekeeper /usr/local/bin/function /usr/local/bin/kpt-fn-gatekeeper
COPY --link --from=mdrip-build /go/bin/mdrip /usr/local/bin/mdrip
COPY --link <<'eot' /usr/local/bin/kpt
#!/usr/bin/env bash
set -euxo pipefail
run_kpt() {
  /usr/local/bin/kpt-bin "${@}"
}
run_kpt_render() {
  pkg="${@: -1}"
  if [ "${pkg}" = "render" ] || [ "${pkg}" = "--allow-exec" ]; then
    pkg="${PWD}"
  fi
  for kptfile in $(/usr/bin/find "${pkg}" -type f -name Kptfile); do
    sed -i.bak -e 's|image: gcr.io/kpt-fn/\(.*\):.*|exec: /usr/local/bin/kpt-fn-\1|' "${kptfile}"
  done
  run_kpt "${@}"
  return_code="${?}"
  for kptfile in $(/usr/bin/find "${pkg}" -type f -name Kptfile); do
    backup_file="${kptfile}.bak"
    rm "${kptfile}"
    mv "${backup_file}" "${kptfile}"
  done
  exit "${return_code}"
}
if [ "${#}" -lt "3" ]; then
  run_kpt "${@}"
  exit "${?}"
fi
if [ "${1}" = "fn" ] && [ "${2}" = "render" ]; then
  run_kpt_render "${@}"
fi
run_kpt "${@}"
eot
RUN chmod +x /usr/local/bin/kpt

FROM tools as fetch-github-release-file
ARG GITHUB_ORG
ARG GITHUB_REPO
ARG VERSION
ARG FILENAME
ARG OUT_DIR
ARG OUT_FILE=${OUT_DIR}/${FILENAME}
ARG URL="https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/releases/download/${VERSION}/${FILENAME}"
RUN curl --fail --create-dirs -L -o "${OUT_FILE}" "${URL}"

FROM scratch as github-release-file
ARG OUT_DIR
COPY --link --from=fetch-github-release-file ${OUT_DIR} /

FROM tools as clusterctl-generate-yaml-build
ARG ENVIRONMENT_VARIABLES=
ARG SECRETS_ENV_FILE="/run/secrets/secrets-env"
ENV SECRETS_ENV_FILE=${SECRETS_ENV_FILE}
ARG OUT_DIR
ARG IN_DIR
ARG OUT_FILE="${OUT_DIR}/file"
COPY --link --from=github-release-file / ${IN_DIR}
RUN mkdir -p "${OUT_DIR}"
RUN --mount=type=secret,id=secrets-env <<eot
#!/usr/bin/env sh
set -euxo pipefail
if [ -n "${ENVIRONMENT_VARIABLES}" ]; then
  echo "${ENVIRONMENT_VARIABLES}" > /tmp/vars.env
  set -a; . /tmp/vars.env; set +a
fi
if [ -f "${SECRETS_ENV_FILE}" ]; then
  set +x; set -a; . "${SECRETS_ENV_FILE}"; set +a; set -x
fi
cat $(find "${IN_DIR}" -type f -maxdepth 1) | clusterctl generate yaml > "${OUT_FILE}"
eot

FROM scratch as clusterctl-generate-yaml
ARG OUT_DIR
COPY --link --from=clusterctl-generate-yaml-build ${OUT_DIR} /

FROM tools as add-clusterctl-provider-resource-build
ARG PROVIDER_TYPE
ARG PROVIDER_NAME
ARG NAMESPACE
ARG PROVIDER_TYPE_GO
ARG VERSION
ARG OUT_DIR
ARG OUT_FILE="${OUT_DIR}/file"
COPY --link --from=clusterctl-generate-yaml / ${OUT_DIR}
RUN <<eot
#!/usr/bin/env sh
set -euxo pipefail
provider_name_short="${PROVIDER_NAME}"
provider_name_full="${PROVIDER_TYPE}-${PROVIDER_NAME}"
if [ "${PROVIDER_TYPE}" == "core" ]; then
  provider_name_full="${PROVIDER_NAME}"
fi
cat <<EOT >> "${OUT_FILE}"
---
apiVersion: clusterctl.cluster.x-k8s.io/v1alpha3
kind: Provider
metadata:
  name: ${provider_name_full}
  namespace: ${NAMESPACE}
providerName: ${provider_name_short}
type: ${PROVIDER_TYPE_GO}
version: ${VERSION}
EOT
eot

FROM scratch as cluster-api-provider-resources
ARG OUT_DIR
COPY --link --from=add-clusterctl-provider-resource-build ${OUT_DIR} /

FROM ${FETCH_RESOURCES_IMAGE} as fetch-resources-image

FROM tools as kpt-fn-sink-build
ARG OUT_DIR
ARG IN_DIR
ARG ENSURE_PORT_PROTOCOL_STARLARK="/fn-configs/ensure-port-protocol.star"
COPY --link <<eot ${ENSURE_PORT_PROTOCOL_STARLARK}
def addportprotocol(resources):
  for resource in resources:
    spec = resource.get("spec")
    ports = spec.get("ports")
    if not ports:
      continue
    for port in ports:
      port.setdefault("protocol", "TCP")
addportprotocol(ctx.resource_list["items"])
eot
COPY --link --from=fetch-resources-image / ${IN_DIR}
RUN mkdir -p "$(dirname "${OUT_PKG}")"
RUN <<eot
#!/usr/bin/env sh
set -euxo pipefail
cat $(find "${IN_DIR}" -type f -maxdepth 1) \
| sed '/^rules: \[\]$/d' \
| sed '/^ *caBundle: Cg==$/d' \
| sed '/^  creationTimestamp: null$/d' \
| kpt fn eval - --exec="kpt-fn-starlark" --match-kind="Service" -- "source=$(cat ${ENSURE_PORT_PROTOCOL_STARLARK})" \
| kpt fn sink "${OUT_DIR}"
eot

FROM scratch as kpt-fn-sink
ARG OUT_DIR
COPY --link --from=kpt-fn-sink-build ${OUT_DIR} /

FROM tools as pkg-sink-source-sidero-cluster-build
ARG OUT_DIR
ARG CONTROL_PLANE_ENDPOINT_FN_CONFIG="/fn-configs/set-controlPlaneEndpoint-from-metalcluster.yaml"
COPY --link --from=kpt-fn-sink /cluster_clustername.yaml ${OUT_DIR}/cluster.yaml
COPY --link --from=kpt-fn-sink /metalcluster_clustername.yaml ${OUT_DIR}/metalcluster.yaml
COPY --link --from=kpt-fn-sink /metalmachinetemplate_clustername-cp.yaml ${OUT_DIR}/control-plane/metalmachinetemplate.yaml
COPY --link --from=kpt-fn-sink /taloscontrolplane_clustername-cp.yaml ${OUT_DIR}/control-plane/taloscontrolplane.yaml
COPY --link --from=kpt-fn-sink /metalmachinetemplate_clustername-workers.yaml ${OUT_DIR}/workers/metalmachinetemplate.yaml
COPY --link --from=kpt-fn-sink /machinedeployment_clustername-workers.yaml /tmp/machinedeployment.yaml
RUN kubectl patch -f /tmp/machinedeployment.yaml --local -o yaml --type=json -p '[{"op":"remove","path":"/spec/selector"}]' > "${OUT_DIR}/workers/machinedeployment.yaml"
COPY --link --from=kpt-fn-sink /talosconfigtemplate_clustername-workers.yaml ${OUT_DIR}/workers/talosconfigtemplate.yaml
COPY --link <<eot ${CONTROL_PLANE_ENDPOINT_FN_CONFIG}
apiVersion: fn.kpt.dev/v1alpha1
kind: ApplyReplacements
metadata:
  name: set-controlPlaneEndpoint-from-metalcluster
replacements:
  - source:
      kind: MetalCluster
      fieldPath: spec.controlPlaneEndpoint
    targets:
      - select:
          kind: Cluster
        fieldPaths:
          - spec.controlPlaneEndpoint
        options:
          create: true
eot
RUN kpt fn eval "${OUT_DIR}" --exec="kpt-fn-apply-replacements" --fn-config="${CONTROL_PLANE_ENDPOINT_FN_CONFIG}"
RUN kpt fn eval "${OUT_DIR}" --exec="kpt-fn-search-replace" -- "by-path=metadata.name" "put-value=cluster-name"
RUN kpt fn eval "${OUT_DIR}" --exec="kpt-fn-search-replace" --match-kind="Cluster" -- "by-path=metadata.namespace" "put-value=default"
RUN kpt fn eval "${OUT_DIR}" --exec="kpt-fn-search-replace" --match-kind="MetalMachineTemplate" -- "by-path=spec.template.spec.serverClassRef.name" "put-value=any"

FROM scratch as pkg-sink-source-sidero-cluster
ARG OUT_DIR
COPY --link --from=pkg-sink-source-sidero-cluster-build ${OUT_DIR} /

FROM scratch as pkg-sink-source-sidero-serverclass
COPY --link <<eot /serverclass.yaml
apiVersion: metal.sidero.dev/v1alpha1
kind: ServerClass
metadata:
  name: serverclass
eot

FROM scratch as pkg-sink-source-sidero-environment
COPY --link <<eot /environment.yaml
apiVersion: metal.sidero.dev/v1alpha1
kind: Environment
metadata:
  name: environment
spec:
  initrd:
    url: https://github.com/talos-systems/talos/releases/download/v0.10.3/initramfs-amd64.xz
  kernel:
    args:
    - talos.config=https://sidero-endpoint:8081/configdata?uuid=
    - talos.platform=metal
    - console=tty0
    - console=ttyS0
    - consoleblank=0
    - earlyprintk=ttyS0
    - ima_appraise=fix
    - ima_hash=sha512
    - ima_template=ima-ng
    - init_on_alloc=1
    - initrd=initramfs.xz
    - nvme_core.io_timeout=4294967295
    - printk.devkmsg=on
    - pti=on
    - random.trust_cpu=on
    - slab_nomerge=
    url: https://github.com/talos-systems/talos/releases/download/v0.10.3/vmlinuz-amd64
eot

FROM ${PKG_SINK_SOURCE} as pkg-sink-source

FROM tools as pkg-rename-files-build
ARG OUT_DIR
ARG IN_DIR
COPY --link --from=pkg-sink-source / ${IN_DIR}
RUN mkdir -p "${OUT_DIR}"
RUN <<eot
#!/usr/bin/env sh
set -euxo pipefail
for filepath in $(find "${IN_DIR}" -type f -iname '*.yaml' | sort); do
  kind="$(echo "${filepath}" | sed 's|\(.*/\)\(\w*\)_.*.yaml|\2|')"
  if [ "${kind}" = "customresourcedefinition" ] || [ -z "${kind}" ]; then
    continue
  fi
  # This is a workaround for issues with missing permissions.
  # TODO: create an issue in https://github.com/siderolabs/cluster-api-bootstrap-provider-talos
  if [ "$(basename "${filepath}")" == "clusterrole_cabpt-manager-role.yaml" ]; then
    cat <<'EOF' >> "${filepath}"
- apiGroups:
  - cluster.x-k8s.io
  resources:
  - machinepools
  - machinepools/status
  verbs:
  - get
  - list
  - watch
EOF
  fi
  dir="$(dirname "${filepath}")"
  outfile="${dir}/${kind}.yaml"
  echo '---' >> "${outfile}"
  cat "${filepath}" >> "${outfile}"
  rm "${filepath}"
done
cp -r $(find "${IN_DIR}" -maxdepth 1 -mindepth 1) "${OUT_DIR}"
eot

FROM scratch as pkg-rename-files
ARG OUT_DIR
COPY --link --from=pkg-rename-files-build ${OUT_DIR} /

FROM tools as example-artifacts-build
ARG OUT_DIR
ARG IN_DIR
ARG GIT_REPO_DIR="${IN_DIR}/repo"
ENV GIT_REPO_DIR=${GIT_REPO_DIR}
ARG GIT_REPO="file://${GIT_REPO_DIR}/.git"
ENV GIT_REPO=${GIT_REPO}
ARG GIT_REF="test_e2e"
ENV GIT_REF=${GIT_REF}
ENV EXAMPLE_DIR="${OUT_DIR}"
ARG EXAMPLE_SOURCE_DIR="${IN_DIR}/example"
ARG CAPI_API_GROUP
ENV CAPI_API="${CAPI_API_GROUP}"
COPY --link --from=repo-source / "${GIT_REPO_DIR}/.git"
COPY --link --from=example-source / "${EXAMPLE_SOURCE_DIR}"
RUN <<eot
#!/usr/bin/env sh
set -euxo pipefail
git -C "${GIT_REPO_DIR}" checkout "${GIT_REF}" -- .
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
git -C "${GIT_REPO_DIR}" tag "${GIT_REF}" -f
eot
RUN <<eot
#!/usr/bin/env sh
set -euxo pipefail
sed -i 's/kpt fn render/kpt fn render --allow-exec/g' "${EXAMPLE_SOURCE_DIR}/README.md"
sed -i 's|--image="gcr.io/kpt-fn/\(.*\):unstable"|--exec=kpt-fn-\1|g' "${EXAMPLE_SOURCE_DIR}/README.md"
mdrip "${EXAMPLE_SOURCE_DIR}" > /example.sh
chmod +x /example.sh
bash -c /example.sh
eot

FROM scratch as example-artifacts
ARG OUT_DIR
COPY --link --from=example-artifacts-build ${OUT_DIR} /

FROM tools as kpt-fn-render
ARG OUT_DIR
COPY --link --from=pkg-local / ${OUT_DIR}
COPY --link --from=pkg-rename-files / ${OUT_DIR}
RUN kpt fn render --allow-exec --truncate-output=false "${OUT_DIR}"

FROM scratch as pkg
ARG OUT_DIR
COPY --link --from=kpt-fn-render "${OUT_DIR}" /

FROM tools as cluster-api-workload-sidero-cluster-kpt-fn-render
ARG OUT_DIR
COPY --link --from=pkg-local / ${OUT_DIR}
COPY --link --from=control-plane-pkg-local / ${OUT_DIR}/control-plane
COPY --link --from=workers-pkg-local / ${OUT_DIR}/workers
COPY --link --from=pkg-rename-files / ${OUT_DIR}
RUN kpt fn render --allow-exec --truncate-output=false "${OUT_DIR}"

FROM tools as cluster-api-workload-sidero-cluster-pkg-build
ARG OUT_DIR
COPY --link --from=cluster-api-workload-sidero-cluster-kpt-fn-render "${OUT_DIR}" "${OUT_DIR}"
RUN find "${OUT_DIR}" -mindepth 2 -not -path "${OUT_DIR}/.fn-configs*" -delete 
RUN find "${OUT_DIR}" -mindepth 1 -type d -not -path "${OUT_DIR}/.fn-configs" -delete 

FROM scratch as cluster-api-workload-sidero-cluster-pkg
ARG OUT_DIR
COPY --link --from=cluster-api-workload-sidero-cluster-pkg-build "${OUT_DIR}" /

FROM scratch as cluster-api-workload-sidero-control-plane-pkg
ARG OUT_DIR
COPY --link --from=cluster-api-workload-sidero-cluster-kpt-fn-render "${OUT_DIR}/control-plane" /

FROM scratch as cluster-api-workload-sidero-workers-pkg
ARG OUT_DIR
COPY --link --from=cluster-api-workload-sidero-cluster-kpt-fn-render "${OUT_DIR}/workers" /

FROM tools as git-tag-packages-build
ARG GIT_TAGS
ENV GIT_TAGS=${GIT_TAGS}
COPY --link .git /repo/.git
WORKDIR /repo
RUN <<EOT
#!/usr/bin/env sh
set -euxo pipefail
for tag in $(echo "${GIT_TAGS}"); do
  git tag "${tag}"
done
EOT

FROM scratch as git-tag-packages
COPY --link --from=git-tag-packages-build /repo/.git /
