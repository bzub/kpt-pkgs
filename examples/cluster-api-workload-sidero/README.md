# cluster-api-workload-sidero

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
cd "${example_dir}"
git init && git add . && git commit -m "feat: initial commit"
```

## Environment [`lab`]

Define an `environment` resource that will configure the kernel image/parameters for servers within.

<!-- @createEnvironment @test -->
```sh
environment_name="lab"
environment_dir="${environment_name}"

kpt pkg get "${git_repo}/cluster-api/workload/sidero/environment@${git_ref}" "${environment_dir}"
```

Let's give our new environment a unique name and commit the changes.

<!-- @renameEnvironment @test -->
```sh
kpt fn eval "${environment_dir}" --image="gcr.io/kpt-fn/search-replace:unstable" -- "by-path=metadata.name" "put-value=${environment_name}"

git add .
git commit -m "feat: add lab environment"
```

### Add Servers [`cluster0-lab`]

Let's add some `Server` resources.

<!-- @addServers @test -->
```sh
mkdir "${environment_dir}/servers"

for server_idx in $(seq 0 3); do
  server_name="server${server_idx}"
  cat <<EOF > "${environment_dir}/servers/server_${server_name}.yaml"
apiVersion: metal.sidero.dev/v1alpha1
kind: Server
metadata:
  name: ${server_name}
spec:
  accepted: true
EOF
done

git add "${environment_dir}/servers"
git commit -m "feat: add servers to lab environment"
```

### Cluster [`cluster0-lab`]

This package:
- Defines a lab `cluster` consisting of a control-plane (`taloscontrolplane`) and a worker deployment (`machinedeployment`).
- Uses `ServerClass` `any` by default, so any accepted `Server` in the management cluster could be used.
  - We will change this further into the example to add `ServerClass`es that select servers by labels.

#### Getting Packages [`cluster0-lab`]

Populate a new cluster package.

<!-- @gettingPackages @test -->
```sh
cluster_name="cluster0-${environment_name}"
cluster_dir="${environment_dir}/${cluster_name}"

kpt pkg get "${git_repo}/cluster-api/workload/sidero/cluster@${git_ref}" "${cluster_dir}"
kpt pkg get "${git_repo}/cluster-api/workload/sidero/control-plane@${git_ref}" "${cluster_dir}"
kpt pkg get "${git_repo}/cluster-api/workload/sidero/workers@${git_ref}" "${cluster_dir}"
```

#### Rename The Cluster And Resources [`cluster0-lab`]

Let's make the cluster name unique.

<!-- @setClusterResourceNames @test -->
```sh
kpt fn eval "${cluster_dir}" --image="gcr.io/kpt-fn/search-replace:unstable" -- "by-path=metadata.name" "put-value=${cluster_name}"
```

#### Change The Namespace [`cluster0-lab`]

Let's create a namespace for the cluster resources.

<!-- @changeNamespace @test -->
```sh
cat <<EOF > "${cluster_dir}/namespace_${cluster_name}.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: ${cluster_name}
EOF

kpt fn eval "${cluster_dir}" --image="gcr.io/kpt-fn/search-replace:unstable" --match-kind="Cluster" -- "by-path=metadata.namespace" "put-value=${cluster_name}"
```

#### Scale The Cluster [`cluster0-lab`]

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

#### Set Talos And Kubernetes Versions [`cluster0-lab`]

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

#### Finalize Changes [`cluster0-lab`]

Throughout these examples we will be running `kpt fn render` and committing our changes to git after making changes to packages/resources.
`kpt fn render` runs each package's configuration function pipeline.
This modifies and validates resources in ways package maintainers and consumers define in `Kptfile`s.

For example, here this will ensure references to the cluster resources we renamed are updated, among other things.

<!-- @renderAndCommit @test -->
```sh
kpt fn render
git add .
git commit -m "feat: add cluster0-lab cluster"
```

#### Add `ServerClass` [`cluster0-lab`]

Now lets say we have a need for another cluster in our `lab` environment.
We no longer want to use `serverclass` `any`, and we instead want to dedicate specific servers to specific clusters.
To do this we create a `serverclass` which will select servers by label.
Then we will place the cluster's `control-plane` and `workers` packages under the new `serverclass` package directory.

<!-- @addServerClass @test -->
```sh
kpt pkg get "${git_repo}/cluster-api/workload/sidero/serverclass@${git_ref}" "${cluster_dir}"
git mv "${cluster_dir}/control-plane" "${cluster_dir}/serverclass"
git mv "${cluster_dir}/workers" "${cluster_dir}/serverclass"
```

Let's give our new `serverclass` a unique name.
Since this `serverclass` represents all servers in the cluster, we will give it the same name as the cluster.

<!-- @setClusterResourceNames @test -->
```sh
kpt fn eval "${cluster_dir}" --image="gcr.io/kpt-fn/search-replace:unstable" -- "by-path=metadata.name" "put-value=${cluster_name}"
```

#### Move Servers Into The New `ServerClass`

By adding a `ServerClass`, the deployments in our cluster will no longer use the default `any` `ServerClass`.
This means the `Server` resources we created earlier will no longer be selected for use by the cluster.
We can alleviate this by moving `Server` resources under the new `ServerClass` package directory.

<!-- @moveServersIntoServerClass @test -->
```sh
git mv "${environment_dir}/servers" "${cluster_dir}/serverclass"
```

Finalize and commit the changes.

<!-- @renderAndCommit @test -->
```sh
kpt fn render
git add .
git commit -m "feat: add cluster0-lab serverclass"
```
