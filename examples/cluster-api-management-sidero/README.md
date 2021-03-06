# cluster-api-management-sidero

How to install cluster-api providers for talos and sidero.

## Setup

Set default variables and create a workspace for the blueprint packages in this example.

<!-- @initializeWorkspace @test -->
```sh
example_dir="${EXAMPLE_DIR:-$(mktemp -d)}"
git_repo="${GIT_REPO:-https://github.com/bzub/kpt-pkgs/.git}"
git_ref="${GIT_REF:-main}"

mkdir -p "${example_dir}"
kpt pkg init "${example_dir}"
```

## Blueprint [`sidero-infrastructure-with-cert-manager`]

This builds a blueprint package containing all the packages needed for a cluster-api management cluster.

### Getting Packages [`sidero-infrastructure-with-cert-manager`]

Populate a new blueprint package with the sub-packages needed for a cluster-api management cluster.

<!-- @gettingPackages @test -->
```sh
blueprint_name="sidero-infrastructure-with-cert-manager"
blueprint_dir="${example_dir}/${blueprint_name}"
mkdir "${blueprint_dir}"
kpt pkg init "${blueprint_dir}"

kpt pkg get "${git_repo}/cert-manager@${git_ref}" "${blueprint_dir}/cert-manager"
kpt pkg get "${git_repo}/cluster-api/core/cluster-api@${git_ref}" "${blueprint_dir}/cluster-api-core"
kpt pkg get "${git_repo}/cluster-api/clusterctl-crds@${git_ref}" "${blueprint_dir}/clusterctl-crds"
kpt pkg get "${git_repo}/cluster-api/bootstrap/talos@${git_ref}" "${blueprint_dir}/bootstrap-talos"
kpt pkg get "${git_repo}/cluster-api/control-plane/talos@${git_ref}" "${blueprint_dir}/control-plane-talos"
kpt pkg get "${git_repo}/cluster-api/infrastructure/sidero@${git_ref}" "${blueprint_dir}/infrastructure-sidero"
```

At this point the package is ready to be deployed with default settings via `kpt live` commands.

## Customizations

The blueprint package(s) above may need further customizations to fit your needs.
Here we will cover some of those situations.

### Customizing Provider Feature Gate Flags

Let's enable some experimental features in all providers.
One way to do this is to use the `search-replace` function imperatively.

<!-- @enableFeatureGates @test -->
```sh
kpt fn eval "${example_dir}" \
  --image="gcr.io/kpt-fn/search-replace:unstable" \
  --match-kind="Deployment" \
  -- \
  by-value-regex='--feature-gates=.*' \
  put-value='--feature-gates=MachinePool=true,ClusterResourceSet=true'
```

Running a package's function pipeline after changes is usually a good idea.

<!-- @render @test -->
```sh
kpt fn render "${example_dir}"
```
