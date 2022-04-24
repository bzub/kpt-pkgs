# cluster-api-v1alpha3-workload-sidero

How to create cluster-api workload clusters backed by talos and sidero.

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
git -C "${example_dir}" init && git -C "${example_dir}" add . && git -C "${example_dir}" commit -m "feat: initial commit"
```

## Cluster [`datacenter0-lab`]

This package:
- Defines a lab `cluster` consisting of a control-plane (`taloscontrolplane`) and a worker deployment (`machinedeployment`).
- Uses `ServerClass` `any` by default, so any accepted `Server` in the management cluster could be used.
  - We will change this further into the example to add `ServerClass`es that select servers by labels.

### Getting Packages [`datacenter0-lab`]

Populate a new cluster package.

<!-- @gettingPackages @test -->
```sh
cluster_name="datacenter0-lab"
cluster_dir="${example_dir}/${cluster_name}"

kpt pkg get "${git_repo}/cluster-api/v1alpha3/cluster/sidero/cluster@${git_ref}" "${cluster_dir}"
```

### Rename The Cluster And Resources [`datacenter0-lab`]

Let's make the cluster name unique.

<!-- @setClusterResourceNames @test -->
```sh
kpt fn eval "${cluster_dir}" --image="gcr.io/kpt-fn/search-replace:unstable" -- "by-path=metadata.name" "put-value=${cluster_name}"
kpt fn render "${cluster_dir}"
```

### Scale The Cluster [`datacenter0-lab`]

Our lab cluster will have three control-plane nodes and one worker node.

<!-- @scaleTheCluster @test -->
```sh
kpt fn eval "${cluster_dir}" --image="gcr.io/kpt-fn/search-replace:unstable" \
  --match-kind="TalosControlPlane" \
  -- "by-path=spec.replicas" "put-value=3"

kpt fn eval "${cluster_dir}" --image="gcr.io/kpt-fn/search-replace:unstable" \
  --match-kind="MachineDeployment" \
  -- "by-path=spec.replicas" "put-value=1"
```

### Set Talos And Kubernetes Versions [`datacenter0-lab`]

Our lab cluster will have Talos `v0.9.1` and Kubernetes `v1.20.5`.

<!-- @setTalosKubernetesVersions @test -->
```sh
kpt fn eval "${cluster_dir}" --image="gcr.io/kpt-fn/search-replace:unstable" \
  --match-kind="TalosControlPlane" \
  -- "by-path=spec.version" "put-value=v1.20.5"

kpt fn eval "${cluster_dir}" --image="gcr.io/kpt-fn/search-replace:unstable" \
  --match-kind="MachineDeployment" \
  -- "by-path=spec.template.spec.version" "put-value=v1.20.5"

kpt fn eval "${cluster_dir}" --image="gcr.io/kpt-fn/search-replace:unstable" \
  --match-kind="TalosControlPlane" \
  -- "by-path=spec.controlPlaneConfig.controlplane.talosVersion" "put-value=v0.9"

kpt fn eval "${cluster_dir}" --image="gcr.io/kpt-fn/search-replace:unstable" \
  --match-kind="TalosControlPlane" \
  -- "by-path=spec.controlPlaneConfig.init.talosVersion" "put-value=v0.9"

kpt fn eval "${cluster_dir}" --image="gcr.io/kpt-fn/search-replace:unstable" \
  --match-kind="TalosConfigTemplate" \
  -- "by-path=spec.template.spec.talosVersion" "put-value=v0.9"
```

## Customizations

The blueprint package(s) above may need further customizations to fit your needs.
Here we will cover some of those situations.

***TODO***
