# syntax = docker.io/docker/dockerfile-upstream:1.4.0

ARG FETCH_RESOURCES_IMAGE

FROM alpine as tools
RUN apk add -U git curl bash
COPY --link --from=kpt /kpt /usr/local/bin/kpt
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

FROM tools as kpt-fn-render
ARG OUT_PKG="/_out/pkg"
COPY --link --from=pkg_rename_files ${OUT_PKG} ${OUT_PKG}
ARG KPTFILE_SOURCE
COPY --link ${KPTFILE_SOURCE} ${OUT_PKG}/Kptfile
RUN sed -i 's|image: gcr.io/kpt-fn/\(.*\):.*|exec: /usr/local/bin/kpt-fn-\1|' "${OUT_PKG}/Kptfile"
RUN sed -i 's/apply-setters/create-setters/' "${OUT_PKG}/Kptfile"
RUN kpt fn render --allow-exec --truncate-output=false "${OUT_PKG}"
RUN rm "${OUT_PKG}/Kptfile"

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
