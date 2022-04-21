# cluster-api-v1alpha3-workload-sidero

How to create blueprints for cluster-api workload clusters backed by talos and sidero.

## Setup

Set default variables and create a workspace for the blueprint packages in this example.

<!-- @initializeWorkspace @test -->
```sh
set -euxo pipefail
example_dir="${EXAMPLE_DIR:-$(mktemp -d)}"
git_repo="${GIT_REPO:-https://github.com/bzub/kpt-pkgs/.git}"
git_ref="${GIT_REF:-main}"

mkdir -p "${example_dir}"
kpt pkg init "${example_dir}"
```

## Blueprint [`hello-world`]

This blueprint:
- Defines a `cluster`.
- Defines a control-plane deployment (`taloscontrolplane`).
- Defines a worker deployment (`machinedeployment`).

### Getting Packages [`hello-world`]

Populate a new blueprint package.

<!-- @gettingPackages @test -->
```sh
blueprint_name="hello-world"
blueprint_dir="${example_dir}/${blueprint_name}"

kpt pkg get "${git_repo}/cluster-api/v1alpha3/cluster/sidero/cluster@${git_ref}" "${blueprint_dir}"
```

### Rename The Cluster And Resources [`hello-world`]

The default cluster name is boring. Let's make it unique.

<!-- @setClusterResourceNames @test -->
```sh
kpt fn eval "${blueprint_dir}" --image="gcr.io/kpt-fn/search-replace:unstable" -- "by-path=metadata.name" "put-value=hello-world"
kpt fn render "${blueprint_dir}"
```

## Customizations

The blueprint package(s) above may need further customizations to fit your needs.
Here we will cover some of those situations.

***TODO***
