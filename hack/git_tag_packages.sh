#!/usr/bin/env bash
set -euxo pipefail

packages="$(git ls-files '**/Kptfile' | sed 's|/Kptfile$||')"

run_git_tag() {
  tag="${1}"
  echo "[INFO] Tagging main with: \"${tag}\""
  git tag "${tag}" main
}

for pkg in ${packages}; do
  echo
  pkg_ver="$(echo "${PKG_VERSIONS}" | jq -r --arg pkg "${pkg}" '.[$pkg]')"
  pkg_tags="$(git tag -l "${pkg}/${pkg_ver}-pkg.**")"
  if [ -z "${pkg_tags}" ]; then
    echo "[INFO] No tags found for package \"${pkg}\" at version \"${pkg_ver}\"."
    new_tag="${pkg}/${pkg_ver}-pkg.0"
    run_git_tag "${new_tag}"
    continue
  fi

  current_revision="$(echo "${pkg_tags}" | sed  's|.*-pkg\.\([0-9]*\)$|\1|' | sort -n | tail -n1)"
  old_tag="${pkg}/${pkg_ver}-pkg.${current_revision}"
  if [ -z "$(git diff main "${old_tag}" -- "${pkg}")" ]; then
    echo "[INFO] No change to package since \"${old_tag}\""
    continue
  fi

  next_revision="$((current_revision + 1))"
  new_tag="${pkg}/${pkg_ver}-pkg.${next_revision}"
  echo "[INFO] Incrementing package revision: \"${next_revision}\""
  run_git_tag "${new_tag}"
done
