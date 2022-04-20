# cluster-api-v1alpha3-workload-sidero

How to create blueprints for cluster-api workload clusters backed by talos and sidero.

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

## Blueprint [`control-plane-only-simple`]

This blueprint:
- Contains the minimal set of sub-packages needed to deploy a workload cluster.
- Only defines a control-plane (`taloscontrolplane`). No workers.
- Eschews sidero's server-group customization resources like `ServerClass` and `Environment`.

Use cases may include:
- Small clusters (1-3 nodes).
- Lab/test scenarios.

### Getting Packages [`control-plane-only-simple`]

Populate a new blueprint package with sub-packages.

<!-- @gettingPackages @test -->
```sh
blueprint_name="control-plane-only-simple"
blueprint_dir="${example_dir}/${blueprint_name}"

kpt pkg get "${git_repo}/cluster-api/v1alpha3/cluster/sidero/cluster@${git_ref}" "${blueprint_dir}"
kpt pkg get "${git_repo}/cluster-api/v1alpha3/cluster/sidero/metalmachinetemplate@${git_ref}" "${blueprint_dir}/metalmachinetemplate"
kpt pkg get "${git_repo}/cluster-api/v1alpha3/cluster/sidero/taloscontrolplane@${git_ref}" "${blueprint_dir}/metalmachinetemplate/taloscontrolplane"

kpt fn render "${blueprint_dir}"
```

At this point the blueprint package is ready to be deployed with default settings via `kpt live` commands.

## Blueprint [`dedicated-environments-and-serverclasses`]

This blueprint:
- Defines a control-plane deployment (`taloscontrolplane`) as well as a worker deployment (`machinedeployment`).
- Defines separate `Environment`s and `ServerClass`es that are dedicated to the control-plane and worker deployments of this cluster.

Use cases may include:
- Predictable server allocation -- specific servers dedicated to specific clusters and roles.

### Getting Packages [`dedicated-environments-and-serverclasses`]

Populate a new blueprint package with sub-packages.

<!-- @gettingPackages @test -->
```sh
blueprint_name="dedicated-environments-and-serverclasses"
blueprint_dir="${example_dir}/${blueprint_name}"

kpt pkg get "${git_repo}/cluster-api/v1alpha3/cluster/sidero/cluster@${git_ref}" "${blueprint_dir}"
kpt pkg get "${git_repo}/cluster-api/v1alpha3/cluster/sidero/environment@${git_ref}" "${blueprint_dir}/control-plane"
kpt pkg get "${git_repo}/cluster-api/v1alpha3/cluster/sidero/serverclass@${git_ref}" "${blueprint_dir}/control-plane/serverclass"
kpt pkg get "${git_repo}/cluster-api/v1alpha3/cluster/sidero/metalmachinetemplate@${git_ref}" "${blueprint_dir}/control-plane/serverclass/metalmachinetemplate"
kpt pkg get "${git_repo}/cluster-api/v1alpha3/cluster/sidero/taloscontrolplane@${git_ref}" "${blueprint_dir}/control-plane/serverclass/metalmachinetemplate/taloscontrolplane"
kpt pkg get "${git_repo}/cluster-api/v1alpha3/cluster/sidero/environment@${git_ref}" "${blueprint_dir}/workers"
kpt pkg get "${git_repo}/cluster-api/v1alpha3/cluster/sidero/serverclass@${git_ref}" "${blueprint_dir}/workers/serverclass"
kpt pkg get "${git_repo}/cluster-api/v1alpha3/cluster/sidero/metalmachinetemplate@${git_ref}" "${blueprint_dir}/workers/serverclass/metalmachinetemplate"
kpt pkg get "${git_repo}/cluster-api/v1alpha3/cluster/sidero/talosconfigtemplate@${git_ref}" "${blueprint_dir}/workers/serverclass/metalmachinetemplate/talosconfigtemplate"
kpt pkg get "${git_repo}/cluster-api/v1alpha3/cluster/sidero/machinedeployment@${git_ref}" "${blueprint_dir}/workers/serverclass/metalmachinetemplate/talosconfigtemplate/machinedeployment"

kpt fn render "${blueprint_dir}"
```

At this point the package is ready to be deployed with default settings via `kpt live` commands.
