#!/usr/bin/env bash
set -euo pipefail

cp "${HOME}/secrets/.git-credentials" "${HOME}"
packages="$(git ls-files '**/Kptfile' | sed 's|/Kptfile$||')"
branch="$(git show -s --pretty=%D HEAD | cut -d' ' -f5)"
git checkout -- .
git checkout "${branch}"
git fetch --tags
git branch "--set-upstream-to=origin/${branch}" "${branch}"
git pull --unshallow
git show-ref --tags -d > /tmp/tags.before

run_git_tag() {
  tag="${1}"
  commit="${2}"
  echo "[INFO] Tagging ${commit} with: \"${tag}\""
  git tag "${tag}" "${commit}"
}

for pkg in ${packages}; do
  echo
  latest_commit="$(git log --no-merges -n1 --oneline --no-abbrev-commit -- "${pkg}" | awk '{print $1}')"
  pkg_ver="$(echo "${PKG_VERSIONS}" | jq -r --arg pkg "${pkg}" '.[$pkg]')"
  pkg_tags="$(git tag -l "${pkg}/${pkg_ver}-pkg.**")"
  if [ -z "${pkg_tags}" ]; then
    echo "[INFO] No tags found for package \"${pkg}\" at version \"${pkg_ver}\"."
    new_tag="${pkg}/${pkg_ver}-pkg.0"
    run_git_tag "${new_tag}" "${latest_commit}"
    continue
  fi

  current_revision="$(echo "${pkg_tags}" | sed  's|.*-pkg\.\([0-9]*\)$|\1|' | sort -n | tail -n1)"
  old_tag="${pkg}/${pkg_ver}-pkg.${current_revision}"
  old_commit="$(git log --no-merges -n1 --oneline --no-abbrev-commit "${old_tag}" | awk '{print $1}')"
  if [ "${latest_commit}" = "${old_commit}" ]; then
    echo "[INFO] No change to package since \"${old_tag}\""
    continue
  fi

  next_revision="$((current_revision + 1))"
  new_tag="${pkg}/${pkg_ver}-pkg.${next_revision}"
  echo "[INFO] Incrementing package revision: \"${next_revision}\""
  run_git_tag "${new_tag}" "${latest_commit}"
done

git show-ref --tags -d > /tmp/tags.after
diff /tmp/tags.before /tmp/tags.after

git config credential.helper store
git push --tags
