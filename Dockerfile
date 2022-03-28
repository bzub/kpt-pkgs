# syntax = docker.io/docker/dockerfile-upstream:1.4.0

ARG GOLANG_IMAGE
ARG KPT_IMAGE
ARG KIND_IMAGE
ARG KUBECTL_IMAGE
ARG CLUSTERCTL_IMAGE
ARG KPT_FN_SEARCH_REPLACE_IMAGE
ARG KPT_FN_SET_ANNOTATIONS_IMAGE
ARG KPT_FN_SET_NAMESPACE_IMAGE
ARG KPT_FN_CREATE_SETTERS_IMAGE
ARG KPT_FN_APPLY_SETTERS_IMAGE
ARG KPT_FN_STARLARK_IMAGE
ARG KPT_FN_SET_LABELS_IMAGE

FROM $GOLANG_IMAGE as golang
FROM $KPT_IMAGE as kpt
FROM $KIND_IMAGE as kind
FROM $KUBECTL_IMAGE as kubectl
FROM $CLUSTERCTL_IMAGE as clusterctl
FROM $KPT_FN_SEARCH_REPLACE_IMAGE as kpt-fn-search-replace
FROM $KPT_FN_SET_ANNOTATIONS_IMAGE as kpt-fn-set-annotations
FROM $KPT_FN_SET_NAMESPACE_IMAGE as kpt-fn-set-namespace
FROM $KPT_FN_CREATE_SETTERS_IMAGE as kpt-fn-create-setters
FROM $KPT_FN_APPLY_SETTERS_IMAGE as kpt-fn-apply-setters
FROM $KPT_FN_STARLARK_IMAGE as kpt-fn-starlark
FROM $KPT_FN_SET_LABELS_IMAGE as kpt-fn-set-labels

FROM golang as tools
RUN apk add -U git build-base curl bash docker
COPY --link --from=kpt /kpt /usr/local/bin/kpt
COPY --link --from=kind /kind /usr/local/bin/kind
COPY --link --from=kubectl /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/kubectl
COPY --link --from=clusterctl /clusterctl /usr/local/bin/clusterctl
COPY --link --from=kpt-fn-search-replace /usr/local/bin/function /usr/local/bin/kpt-fn-search-replace
COPY --link --from=kpt-fn-set-annotations /usr/local/bin/function /usr/local/bin/kpt-fn-set-annotations
COPY --link --from=kpt-fn-set-namespace /usr/local/bin/function /usr/local/bin/kpt-fn-set-namespace
COPY --link --from=kpt-fn-create-setters /usr/local/bin/function /usr/local/bin/kpt-fn-create-setters
COPY --link --from=kpt-fn-apply-setters /usr/local/bin/function /usr/local/bin/kpt-fn-apply-setters
COPY --link --from=kpt-fn-starlark /usr/local/bin/function /usr/local/bin/kpt-fn-starlark
COPY --link --from=kpt-fn-set-labels /usr/local/bin/function /usr/local/bin/kpt-fn-set-labels

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

# TODO: Make this more generic.
FROM tools as cluster-api-component-template-yaml
ARG PROVIDER_GITHUB_ORG
ARG PROVIDER_GITHUB_REPO
ARG PROVIDER_VERSION
ARG PROVIDER_COMPONENTS_FILENAME
ARG COMPONENT_URL="https://github.com/${PROVIDER_GITHUB_ORG}/${PROVIDER_GITHUB_REPO}/releases/download/${PROVIDER_VERSION}/${PROVIDER_COMPONENTS_FILENAME}"
RUN curl -L -o /component-template.yaml "${COMPONENT_URL}"

FROM tools as cluster-api-component-generate-yaml
ARG ENVIRONMENT_VARIABLES=
ARG SECRETS_ENV_FILE="/run/secrets/secrets-env"
ENV SECRETS_ENV_FILE=${SECRETS_ENV_FILE}
COPY --link --from=cluster-api-component-template-yaml /component-template.yaml /component-template.yaml
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
cat /component-template.yaml | clusterctl generate yaml > /component.yaml
eot

FROM tools as cluster-api-component-kpt-sink
COPY --link --from=cluster-api-component-generate-yaml /component.yaml /component.yaml
RUN <<eot
cat /component.yaml \
| sed '/^rules: \[\]$/d' \
| sed '/^ *caBundle: Cg==$/d'\
| sed '/^  creationTimestamp: null$/d'\
| kpt fn sink "/pkg"
eot

FROM tools as cluster-api-component-rename-files
COPY --link --from=cluster-api-component-kpt-sink /pkg /pkg
RUN <<eot
for filepath in $(find /pkg -type f -iname '*.yaml'); do
  kind="$(echo "${filepath}" | sed 's|\(.*/\)\(\w*\)_.*.yaml|\2|')"
  if [ "${kind}" = "customresourcedefinition" ]; then
    continue
  fi
  dir="$(dirname "${filepath}")"
  outfile="${dir}/${kind}.yaml"
  echo '---' >> "${outfile}"
  cat "${filepath}" >> "${outfile}"
  rm "${filepath}"
done
eot

FROM tools as cluster-api-component-kpt-fn-render
ARG PROVIDER_TYPE
ARG PROVIDER_NAME
ARG PROVIDER_VERSION
ARG CAPI_API_GROUP
ARG PKG_PATH="cluster-api/${CAPI_API_GROUP}/${PROVIDER_TYPE}/${PROVIDER_NAME}"
ARG KPTFILE_SRC="${PKG_PATH}/Kptfile"
COPY --link ./Kptfile /kpt-files/Kptfile
COPY --link cluster-api/Kptfile /kpt-files/cluster-api/Kptfile
COPY --link ${KPTFILE_SRC} /kpt-files/${KPTFILE_SRC}
COPY --link --from=cluster-api-component-rename-files /pkg /kpt-files/${PKG_PATH}
RUN sed -i 's/apply-setters/create-setters/' "/kpt-files/${KPTFILE_SRC}"
RUN sed -i 's|image: gcr.io/kpt-fn/\(.*\):.*|exec: /usr/local/bin/kpt-fn-\1|' /kpt-files/Kptfile
RUN sed -i 's|image: gcr.io/kpt-fn/\(.*\):.*|exec: /usr/local/bin/kpt-fn-\1|' /kpt-files/cluster-api/Kptfile
RUN sed -i 's|image: gcr.io/kpt-fn/\(.*\):.*|exec: /usr/local/bin/kpt-fn-\1|' "/kpt-files/${KPTFILE_SRC}"
RUN kpt fn render --allow-exec --truncate-output=false /kpt-files
RUN cp -r "/kpt-files/${PKG_PATH}" /pkg
RUN find /pkg -type f -name 'Kptfile' -delete

FROM scratch as cluster-api-component-pkg
COPY --link --from=cluster-api-component-kpt-fn-render /pkg /

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
