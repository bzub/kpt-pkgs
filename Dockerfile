# syntax = docker.io/docker/dockerfile-upstream:1.4.0

ARG FETCH_RESOURCES_IMAGE

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

FROM tools as fetch-github-release-file
ARG GITHUB_ORG
ARG GITHUB_REPO
ARG VERSION
ARG FILENAME="file"
ARG OUT_FILE="/_out/${FILENAME}"
ARG URL="https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/releases/download/${VERSION}/${FILENAME}"
RUN curl --fail --create-dirs -L -o "${OUT_FILE}" "${URL}"

FROM tools as clusterctl-generate-yaml
ARG ENVIRONMENT_VARIABLES=
ARG SECRETS_ENV_FILE="/run/secrets/secrets-env"
ENV SECRETS_ENV_FILE=${SECRETS_ENV_FILE}
ARG FILENAME="file"
ARG IN_FILE="/_in/${FILENAME}"
ARG OUT_FILE="/_out/${FILENAME}"
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

FROM ${FETCH_RESOURCES_IMAGE} as fetch-resources-image

FROM tools as kpt-fn-sink
ARG FILENAME="file"
ARG IN_FILE="/_in/${FILENAME}"
ARG OUT_FILE="/_out/${FILENAME}"
ARG OUT_PKG="/_out/pkg"
COPY --link --from=fetch-resources-image ${OUT_FILE} ${IN_FILE}
RUN mkdir -p "$(dirname "${OUT_PKG}")"
RUN <<eot
#!/usr/bin/env sh
set -euxo pipefail
cat "${IN_FILE}" \
| sed '/^rules: \[\]$/d' \
| sed '/^ *caBundle: Cg==$/d'\
| sed '/^  creationTimestamp: null$/d'\
| kpt fn sink "${OUT_PKG}"
eot

FROM tools as pkg_rename_files
ARG FILENAME="file"
ARG IN_PKG="/_in/pkg"
ARG OUT_PKG="/_out/pkg"
COPY --link --from=kpt-fn-sink ${OUT_PKG} ${IN_PKG}
RUN mkdir -p "$(dirname "${OUT_PKG}")"
RUN <<eot
for filepath in $(find "${IN_PKG}" -type f -iname '*.yaml'); do
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
cp -r "${IN_PKG}" "${OUT_PKG}"
eot

FROM pkg_rename_files as kpt-fn-render
ARG FILENAME="file"
ARG OUT_PKG="/_out/pkg"
COPY --link --from=pkg_rename_files ${OUT_PKG} ${OUT_PKG}
ARG KPTFILE_SOURCE
COPY --link ${KPTFILE_SOURCE} ${OUT_PKG}/Kptfile
RUN sed -i 's|image: gcr.io/kpt-fn/\(.*\):.*|exec: /usr/local/bin/kpt-fn-\1|' "${OUT_PKG}/Kptfile"
RUN sed -i 's/apply-setters/create-setters/' "${OUT_PKG}/Kptfile"
RUN kpt fn render --allow-exec --truncate-output=false "${OUT_PKG}"
RUN rm "${OUT_PKG}/Kptfile"

FROM kpt-fn-render as pkg-build
RUN cp -r "${OUT_PKG}" /pkg

FROM scratch as pkg
COPY --link --from=pkg-build /pkg /

# FROM tools as cluster-api-pkg-build
# COPY --link --from=pkg / /pkg
# ARG ENVIRONMENT_VARIABLES=
# ARG SECRETS_ENV_FILE="/run/secrets/secrets-env"
# ENV SECRETS_ENV_FILE=${SECRETS_ENV_FILE}
# RUN --mount=type=secret,id=secrets-env <<eot
# #!/usr/bin/env sh
# set -euxo pipefail
# if [ -n "${ENVIRONMENT_VARIABLES}" ]; then
#   echo "${ENVIRONMENT_VARIABLES}" > /tmp/vars.env
#   set -a; . /tmp/vars.env; set +a
# fi
# if [ -f "${SECRETS_ENV_FILE}" ]; then
#   set +x; set -a; . "${SECRETS_ENV_FILE}"; set +a; set -x
# fi
# for yaml_file in $(find /pkg -type f -name '*.yaml'); do
#   new_file="$(echo "${yaml_file}" | sed 's|^/pkg|/new-pkg|')"
#   mkdir -p "$(dirname "${new_file}")"
#   cat "${yaml_file}" | clusterctl generate yaml > "${new_file}"
# done
# eot
#
# FROM scratch as cluster-api-pkg
# COPY --link --from=cluster-api-pkg-build /new-pkg /

# FROM tools as cluster-api-component-generate-yaml
# ARG ENVIRONMENT_VARIABLES=
# ARG SECRETS_ENV_FILE="/run/secrets/secrets-env"
# ENV SECRETS_ENV_FILE=${SECRETS_ENV_FILE}
# COPY --link --from=cluster-api-component-template-yaml /component-template.yaml /component-template.yaml
# RUN --mount=type=secret,id=secrets-env <<eot
# #!/usr/bin/env sh
# set -euxo pipefail
# if [ -n "${ENVIRONMENT_VARIABLES}" ]; then
#   echo "${ENVIRONMENT_VARIABLES}" > /tmp/vars.env
#   set -a; . /tmp/vars.env; set +a
# fi
# if [ -f "${SECRETS_ENV_FILE}" ]; then
#   set +x; set -a; . "${SECRETS_ENV_FILE}"; set +a; set -x
# fi
# cat /component-template.yaml | clusterctl generate yaml > /component.yaml
# eot
#
# FROM tools as cluster-api-component-kpt-sink
# COPY --link --from=cluster-api-component-generate-yaml /component.yaml /component.yaml
# RUN <<eot
# cat /component.yaml \
# | sed '/^rules: \[\]$/d' \
# | sed '/^ *caBundle: Cg==$/d'\
# | sed '/^  creationTimestamp: null$/d'\
# | kpt fn sink "/pkg"
# eot
#
# FROM tools as cluster-api-component-rename-files
# COPY --link --from=cluster-api-component-kpt-sink /pkg /pkg
# RUN <<eot
# for filepath in $(find /pkg -type f -iname '*.yaml'); do
#   kind="$(echo "${filepath}" | sed 's|\(.*/\)\(\w*\)_.*.yaml|\2|')"
#   if [ "${kind}" = "customresourcedefinition" ]; then
#     continue
#   fi
#   dir="$(dirname "${filepath}")"
#   outfile="${dir}/${kind}.yaml"
#   echo '---' >> "${outfile}"
#   cat "${filepath}" >> "${outfile}"
#   rm "${filepath}"
# done
# eot
#
# FROM tools as cluster-api-component-kpt-fn-render
# ARG PROVIDER_TYPE
# ARG PROVIDER_NAME
# ARG PROVIDER_VERSION
# ARG CAPI_API_GROUP
# ARG PKG_PATH="cluster-api/${CAPI_API_GROUP}/${PROVIDER_TYPE}/${PROVIDER_NAME}"
# ARG KPTFILE_SRC="${PKG_PATH}/Kptfile"
# COPY --link ./Kptfile /kpt-files/Kptfile
# COPY --link cluster-api/Kptfile /kpt-files/cluster-api/Kptfile
# COPY --link ${KPTFILE_SRC} /kpt-files/${KPTFILE_SRC}
# COPY --link --from=cluster-api-component-rename-files /pkg /kpt-files/${PKG_PATH}
# RUN sed -i 's/apply-setters/create-setters/' "/kpt-files/${KPTFILE_SRC}"
# RUN sed -i 's|image: gcr.io/kpt-fn/\(.*\):.*|exec: /usr/local/bin/kpt-fn-\1|' /kpt-files/Kptfile
# RUN sed -i 's|image: gcr.io/kpt-fn/\(.*\):.*|exec: /usr/local/bin/kpt-fn-\1|' /kpt-files/cluster-api/Kptfile
# RUN sed -i 's|image: gcr.io/kpt-fn/\(.*\):.*|exec: /usr/local/bin/kpt-fn-\1|' "/kpt-files/${KPTFILE_SRC}"
# RUN kpt fn render --allow-exec --truncate-output=false /kpt-files
# RUN cp -r "/kpt-files/${PKG_PATH}" /pkg
# RUN find /pkg -type f -name 'Kptfile' -delete
#
# FROM scratch as cluster-api-component-pkg
# COPY --link --from=cluster-api-component-kpt-fn-render /pkg /

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
