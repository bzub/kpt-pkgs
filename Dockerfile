# syntax = docker.io/docker/dockerfile-upstream:1.4.0

ARG FETCH_RESOURCES_IMAGE
ARG PKG_SOURCE
ARG PKG_SINK_SOURCE

FROM alpine as tools
RUN apk add -U git curl bash jq
COPY --link --from=kpt /kpt /usr/local/bin/kpt
COPY --link --from=clusterctl /clusterctl /usr/local/bin/clusterctl
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

FROM tools as fetch-github-release-file
ARG GITHUB_ORG
ARG GITHUB_REPO
ARG VERSION
ARG FILENAME
ARG OUT_FILE="/_out/file"
ARG URL="https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/releases/download/${VERSION}/${FILENAME}"
RUN curl --fail --create-dirs -L -o "${OUT_FILE}" "${URL}"

FROM tools as clusterctl-generate-yaml
ARG ENVIRONMENT_VARIABLES=
ARG SECRETS_ENV_FILE="/run/secrets/secrets-env"
ENV SECRETS_ENV_FILE=${SECRETS_ENV_FILE}
ARG IN_FILE="/_in/file"
ARG OUT_FILE="/_out/file"
COPY --link --from=fetch-github-release-file ${OUT_FILE} ${IN_FILE}
RUN mkdir -p "$(dirname "${OUT_FILE}")"
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
cat "${IN_FILE}" | clusterctl generate yaml > "${OUT_FILE}"
eot

FROM tools as add-clusterctl-provider-resource
ARG PROVIDER_TYPE
ARG PROVIDER_NAME
ARG NAMESPACE
ARG PROVIDER_TYPE_GO
ARG VERSION
ARG OUT_FILE="/_out/file"
COPY --link --from=clusterctl-generate-yaml ${OUT_FILE} ${OUT_FILE}
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

FROM ${FETCH_RESOURCES_IMAGE} as fetch-resources-image

FROM tools as kpt-fn-sink
ARG IN_FILE="/_in/file"
ARG OUT_FILE="/_out/file"
ARG OUT_PKG="/_out/pkg"
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
COPY --link --from=fetch-resources-image ${OUT_FILE} ${IN_FILE}
RUN mkdir -p "$(dirname "${OUT_PKG}")"
RUN <<eot
#!/usr/bin/env sh
set -euxo pipefail
cat "${IN_FILE}" \
| sed '/^rules: \[\]$/d' \
| sed '/^ *caBundle: Cg==$/d' \
| sed '/^  creationTimestamp: null$/d' \
| kpt fn eval - --exec="kpt-fn-starlark" --match-kind="Service" -- "source=$(cat ${ENSURE_PORT_PROTOCOL_STARLARK})" \
| kpt fn sink "${OUT_PKG}"
eot

FROM tools as pkg-sink-source-sidero-cluster
ARG OUT_PKG="/_out/pkg"
ARG CONTROLPLANE_ENDPOINT_FN_CONFIG="/fn-configs/set-controlPlaneEndpoint-from-metalcluster.yaml"
COPY --link --from=kpt-fn-sink ${OUT_PKG}/cluster_clustername.yaml ${OUT_PKG}/cluster.yaml
COPY --link --from=kpt-fn-sink ${OUT_PKG}/metalcluster_clustername.yaml ${OUT_PKG}/metalcluster.yaml
COPY --link <<eot ${CONTROLPLANE_ENDPOINT_FN_CONFIG}
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
RUN kpt fn eval "${OUT_PKG}" --exec="kpt-fn-apply-replacements" --fn-config="${CONTROLPLANE_ENDPOINT_FN_CONFIG}"
RUN kpt fn eval "${OUT_PKG}" --exec="kpt-fn-search-replace" -- "by-file-path=cluster.yaml" "by-path=metadata.name" "put-value=cluster"
RUN kpt fn eval "${OUT_PKG}" --exec="kpt-fn-search-replace" -- "by-file-path=metalcluster.yaml" "by-path=metadata.name" "put-value=metalcluster"
RUN kpt fn eval "${OUT_PKG}" --exec="kpt-fn-search-replace" -- "by-file-path=cluster.yaml" "by-path=spec.controlPlaneRef.name" "put-value=taloscontrolplane"
RUN kpt fn eval "${OUT_PKG}" --exec="kpt-fn-search-replace" -- "by-file-path=cluster.yaml" "by-path=spec.infrastructureRef.name" "put-value=metalcluster"

FROM tools as pkg-sink-source-sidero-machinedeployment
ARG OUT_PKG="/_out/pkg"
COPY --link --from=kpt-fn-sink ${OUT_PKG}/machinedeployment_clustername-workers.yaml ${OUT_PKG}/machinedeployment.yaml
RUN kpt fn eval "${OUT_PKG}" --exec="kpt-fn-search-replace" -- "by-path=metadata.name" "put-value=machinedeployment"
RUN kpt fn eval "${OUT_PKG}" --exec="kpt-fn-search-replace" -- "by-path=spec.template.spec.bootstrap.configRef.name" "put-value=talosconfigtemplate"
RUN kpt fn eval "${OUT_PKG}" --exec="kpt-fn-search-replace" -- "by-path=spec.template.spec.infrastructureRef.name" "put-value=metalmachinetemplate"
RUN kpt fn eval "${OUT_PKG}" --exec="kpt-fn-search-replace" -- "by-path=spec.clusterName" "put-value=cluster"
RUN kpt fn eval "${OUT_PKG}" --exec="kpt-fn-search-replace" -- "by-path=spec.template.spec.clusterName" "put-value=cluster"

FROM tools as pkg-sink-source-sidero-metalmachinetemplate
ARG OUT_PKG="/_out/pkg"
COPY --link --from=kpt-fn-sink ${OUT_PKG}/metalmachinetemplate_clustername-workers.yaml ${OUT_PKG}/metalmachinetemplate.yaml
RUN kpt fn eval "${OUT_PKG}" --exec="kpt-fn-search-replace" -- "by-path=metadata.name" "put-value=metalmachinetemplate"
RUN kpt fn eval "${OUT_PKG}" --exec="kpt-fn-search-replace" -- "by-path=spec.template.spec.serverClassRef.name" "put-value=any"

FROM tools as pkg-sink-source-sidero-serverclass
ARG OUT_PKG="/_out/pkg"
COPY --link <<eot ${OUT_PKG}/serverclass.yaml
apiVersion: metal.sidero.dev/v1alpha1
kind: ServerClass
metadata:
  name: serverclass
eot

FROM tools as pkg-sink-source-sidero-talosconfigtemplate
ARG OUT_PKG="/_out/pkg"
COPY --link --from=kpt-fn-sink ${OUT_PKG}/talosconfigtemplate_clustername-workers.yaml ${OUT_PKG}/talosconfigtemplate.yaml
RUN kpt fn eval "${OUT_PKG}" --exec="kpt-fn-search-replace" -- "by-path=metadata.name" "put-value=talosconfigtemplate"

FROM tools as pkg-sink-source-sidero-taloscontrolplane
ARG OUT_PKG="/_out/pkg"
COPY --link --from=kpt-fn-sink ${OUT_PKG}/taloscontrolplane_clustername-cp.yaml ${OUT_PKG}/taloscontrolplane.yaml
RUN kpt fn eval "${OUT_PKG}" --exec="kpt-fn-search-replace" -- "by-path=metadata.name" "put-value=taloscontrolplane"
RUN kpt fn eval "${OUT_PKG}" --exec="kpt-fn-search-replace" -- "by-path=spec.infrastructureTemplate.name" "put-value=metalmachinetemplate"

FROM ${PKG_SINK_SOURCE} as pkg-sink-source

FROM tools as pkg_rename_files
ARG IN_PKG="/_in/pkg"
ARG OUT_PKG="/_out/pkg"
COPY --link --from=pkg-sink-source ${OUT_PKG} ${IN_PKG}
RUN mkdir -p "$(dirname "${OUT_PKG}")"
RUN <<eot
#!/usr/bin/env sh
set -euxo pipefail
for filepath in $(find "${IN_PKG}" -type f -iname '*.yaml'); do
  kind="$(echo "${filepath}" | sed 's|\(.*/\)\(\w*\)_.*.yaml|\2|')"
  if [ "${kind}" = "customresourcedefinition" ] || [ -z "${kind}" ]; then
    continue
  fi
  dir="$(dirname "${filepath}")"
  outfile="${dir}/${kind}.yaml"
  echo '---' >> "${outfile}"
  cat "${filepath}" >> "${outfile}"
  rm "${filepath}"
done
cp -r "${IN_PKG}" "${OUT_PKG}"
eot

FROM tools as kpt-pkg-get
ARG OUT_PKG="/_out/pkg"
ARG GIT_REPO_DIR="/_in/repo"
ARG GIT_REPO="file://${GIT_REPO_DIR}/.git"
ARG GIT_REF="test_e2e"
ARG UPDATE_STRATEGY="resource-merge"
ARG PKG_SPECS
COPY --link --from=repo-source / ${GIT_REPO_DIR}/.git
RUN mkdir -p "${OUT_PKG}"
RUN <<eot
#!/usr/bin/env sh
set -euxo pipefail
for pkg_spec in $(echo "${PKG_SPECS}" | jq -c '.[]'); do
  remote_dir="$(echo "${pkg_spec}" | jq -r '.["remote_dir"]')"
  local_dir="${OUT_PKG}/$(echo "${pkg_spec}" | jq -r '.["local_dir"]')"
  kpt pkg get "${GIT_REPO}/${remote_dir}@${GIT_REF}" "${local_dir}" --strategy="${UPDATE_STRATEGY}"
done
eot

FROM ${PKG_SOURCE} as pkg-source

FROM tools as kpt-fn-render
ARG OUT_PKG="/_out/pkg"
COPY --link --from=pkg-local / ${OUT_PKG}
COPY --link --from=pkg-source ${OUT_PKG} ${OUT_PKG}
RUN <<eot
#!/usr/bin/env sh
set -euxo pipefail
for kptfile in $(find "${OUT_PKG}" -type f -name Kptfile); do
  sed -i.bak \
    -e 's|image: gcr.io/kpt-fn/\(.*\):.*|exec: /usr/local/bin/kpt-fn-\1|' \
    "${kptfile}"
done
eot
RUN kpt fn render --allow-exec --truncate-output=false "${OUT_PKG}"
RUN <<eot
#!/usr/bin/env sh
set -euxo pipefail
for kptfile in $(find "${OUT_PKG}" -type f -name Kptfile); do
  backup_file="${kptfile}.bak"
  rm "${kptfile}"
  mv "${backup_file}" "${kptfile}"
done
eot

FROM scratch as pkg
ARG OUT_PKG="/_out/pkg"
COPY --link --from=kpt-fn-render "${OUT_PKG}" /

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
