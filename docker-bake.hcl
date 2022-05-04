variable "OUTPUT_DIR" {default = "."}
variable "ARTIFACTS_DIR" {default = "${OUTPUT_DIR}/_out"}
variable "CAPI_DIR" {default = "cluster-api"}
variable "CAPI_WORKLOAD_DIR" {default = "${CAPI_DIR}/workload"}
variable "CAPI_WORKLOAD_SIDERO_DIR" {default = "${CAPI_WORKLOAD_DIR}/sidero"}

variable "KPT_VERSION" {default = "v1.0.0-beta.13"}
variable "CERT_MANAGER_VERSION" {default = "v1.7.2"}
variable "CLUSTERCTL_VERSION" {default = CAPI_V1BETA1_CORE_VERSION}
variable "KUBECTL_VERSION" {default = "1.23.5"}
variable "CAPI_V1ALPHA3_CORE_VERSION" {default = "v0.3.25"}
variable "CAPI_V1ALPHA4_CORE_VERSION" {default = "v0.4.7"}
variable "CAPI_V1BETA1_CORE_VERSION" {default = "v1.1.3"}
variable "CAPI_CORE_VERSION" {default = CAPI_V1BETA1_CORE_VERSION}

# cluster-api
variable "CAPI_BOOTSTRAP_KUBEADM_VERSION" {default = "${CAPI_CORE_VERSION}"}
variable "CAPI_BOOTSTRAP_TALOS_VERSION" {default = "v0.5.3"}
variable "CAPI_CONTROLPLANE_KUBEADM_VERSION" {default = "${CAPI_CORE_VERSION}"}
variable "CAPI_CONTROLPLANE_TALOS_VERSION" {default = "v0.4.6"}
variable "CAPI_INFRASTRUCTURE_DOCKER_VERSION" {default = "${CAPI_CORE_VERSION}"}
variable "CAPI_INFRASTRUCTURE_SIDERO_VERSION" {default = "v0.5.0"}

variable "KPT_IMAGE" {default = "docker-image://ghcr.io/bzub/images/kpt:${KPT_VERSION}"}
variable "CLUSTERCTL_IMAGE" {default = "docker-image://ghcr.io/bzub/images/clusterctl:${CLUSTERCTL_VERSION}"}
variable "KUBECTL_IMAGE" {default = "docker-image://docker.io/bitnami/kubectl:${KUBECTL_VERSION}"}
variable "KPT_FN_SEARCH_REPLACE_IMAGE" {default = "docker-image://gcr.io/kpt-fn/search-replace@sha256:c8da9c025eea6bef4426c1eb1c12158da7bd795f8912fc83a170d490b3240a8b"}
variable "KPT_FN_SET_ANNOTATIONS_IMAGE" {default = "docker-image://gcr.io/kpt-fn/set-annotations@sha256:6285fca0192e26c0ae090f26103a3661282260c69c80a794fbf6481082101ea6"}
variable "KPT_FN_SET_NAMESPACE_IMAGE" {default = "docker-image://gcr.io/kpt-fn/set-namespace:v0.3.3"}
variable "KPT_FN_CREATE_SETTERS_IMAGE" {default = "docker-image://gcr.io/kpt-fn/create-setters@sha256:76ec527190c3826196db133c32db5d29c228876f0c4b5e692781f68e2dcc7536"}
variable "KPT_FN_APPLY_SETTERS_IMAGE" {default = "docker-image://gcr.io/kpt-fn/apply-setters@sha256:d322a18de00daf566b48bc7cbebf4814bc87cecf783d494ccaf9294bf23c6392"}
variable "KPT_FN_STARLARK_IMAGE" {default = "docker-image://gcr.io/kpt-fn/starlark@sha256:416188026608fbea937ebf2e287ae8aa277651884520621357b7f5115261a04e"}
variable "KPT_FN_SET_LABELS_IMAGE" {default = "docker-image://gcr.io/kpt-fn/set-labels@sha256:d088e20cd2c9067e433398161cd7adda3d23226e1afeda37ea2b8029eaf3852f"}
variable "KPT_FN_ENSURE_NAME_SUBSTRING_IMAGE" {default = "docker-image://gcr.io/kpt-fn/ensure-name-substring@sha256:027d1fcdfa839d991cb6ddf924d339569d20a7dff70cd821642cb0d053739010"}
variable "KPT_FN_APPLY_REPLACEMENTS_IMAGE" {default = "docker-image://gcr.io/kpt-fn/apply-replacements@sha256:7c494199513277e95fe28e13a0198ea69d8e6cc4100c4a417d0c93995ce41215"}
variable "KPT_FN_GATEKEEPER_IMAGE" {default = "docker-image://gcr.io/kpt-fn/gatekeeper@sha256:3427f13a6208bb3dd6913b4d58b34c3f482823c1edd79f3910aca8e5117812f8"}

group "default" {
  targets = [
    "cert-manager",
    "cluster-api",
    "examples",
  ]
}

target "_common" {
  target = "pkg"
  contexts = {
    kpt = KPT_IMAGE
    clusterctl = CLUSTERCTL_IMAGE
    kubectl = KUBECTL_IMAGE
    kpt-fn-search-replace = KPT_FN_SEARCH_REPLACE_IMAGE
    kpt-fn-set-annotations = KPT_FN_SET_ANNOTATIONS_IMAGE
    kpt-fn-set-namespace = KPT_FN_SET_NAMESPACE_IMAGE
    kpt-fn-create-setters = KPT_FN_CREATE_SETTERS_IMAGE
    kpt-fn-apply-setters = KPT_FN_APPLY_SETTERS_IMAGE
    kpt-fn-starlark = KPT_FN_STARLARK_IMAGE
    kpt-fn-set-labels = KPT_FN_SET_LABELS_IMAGE
    kpt-fn-ensure-name-substring = KPT_FN_ENSURE_NAME_SUBSTRING_IMAGE
    kpt-fn-apply-replacements = KPT_FN_APPLY_REPLACEMENTS_IMAGE
    kpt-fn-gatekeeper = KPT_FN_GATEKEEPER_IMAGE
  }
  args = {
    FETCH_RESOURCES_IMAGE = "github-release-file"
    PKG_SINK_SOURCE = "kpt-fn-sink"
  }
}

target "git-tag-packages" {
  inherits = ["_common"]
  target = "git-tag-packages"
  args = {
    GIT_TAGS = join(" ", [
      "cert-manager/${CERT_MANAGER_VERSION}-pkg.00",
      # cluster-api
      "cluster-api/core/cluster-api/${CAPI_CORE_VERSION}-pkg.00",
      "cluster-api/bootstrap/talos/${CAPI_BOOTSTRAP_TALOS_VERSION}-pkg.00",
      "cluster-api/bootstrap/kubeadm/${CAPI_BOOTSTRAP_KUBEADM_VERSION}-pkg.00",
      "cluster-api/control-plane/talos/${CAPI_CONTROLPLANE_TALOS_VERSION}-pkg.00",
      "cluster-api/control-plane/kubeadm/${CAPI_CONTROLPLANE_KUBEADM_VERSION}-pkg.00",
      "cluster-api/infrastructure/docker/${CAPI_INFRASTRUCTURE_DOCKER_VERSION}-pkg.00",
      "cluster-api/infrastructure/sidero/${CAPI_INFRASTRUCTURE_SIDERO_VERSION}-pkg.00",
      "cluster-api/workload/sidero/cluster/${CAPI_INFRASTRUCTURE_SIDERO_VERSION}-pkg.00",
      "cluster-api/workload/sidero/control-plane/${CAPI_INFRASTRUCTURE_SIDERO_VERSION}-pkg.00",
      "cluster-api/workload/sidero/environment/${CAPI_INFRASTRUCTURE_SIDERO_VERSION}-pkg.00",
      "cluster-api/workload/sidero/serverclass/${CAPI_INFRASTRUCTURE_SIDERO_VERSION}-pkg.00",
      "cluster-api/workload/sidero/workers/${CAPI_INFRASTRUCTURE_SIDERO_VERSION}-pkg.00",
    ])
  }
  output = ["${OUTPUT_DIR}/.git"]
}

target "cert-manager" {
  inherits = ["_common"]
  contexts = {
    pkg-local = "./cert-manager"
  }
  args = {
    GITHUB_ORG = "cert-manager"
    GITHUB_REPO = "cert-manager"
    VERSION = CERT_MANAGER_VERSION
    FILENAME = "cert-manager.yaml"
  }
  output = ["${OUTPUT_DIR}/cert-manager"]
  platforms = []
}

group "cluster-api" {
  targets = [
    "cluster-api-providers",
    "cluster-api-workloads",
  ]
}

group "cluster-api-providers" {
  targets = [
    "cluster-api-core",
    "cluster-api-bootstrap-kubeadm",
    "cluster-api-bootstrap-talos",
    "cluster-api-control-plane-kubeadm",
    "cluster-api-control-plane-talos",
    "cluster-api-infrastructure-docker",
    "cluster-api-infrastructure-sidero",
  ]
}

group "cluster-api-workloads" {
  targets = [
    "cluster-api-workload-sidero",
  ]
}

target "_cluster-api-provider" {
  args = {
    FETCH_RESOURCES_IMAGE = "cluster-api-provider-resources"
  }
}

target "_cluster-api-workload" {
  args = {
    FETCH_RESOURCES_IMAGE = "clusterctl-generate-yaml"
  }
}

target "_cluster-api-core" {
  args = {
    PROVIDER_TYPE = "core"
    PROVIDER_TYPE_GO = "CoreProvider"
    PROVIDER_NAME = "cluster-api"
    NAMESPACE = "capi-system"
    GITHUB_ORG = "kubernetes-sigs"
    GITHUB_REPO = "cluster-api"
    FILENAME = "core-components.yaml"
  }
}

target "cluster-api-core" {
  inherits = ["_common", "_cluster-api-provider", "_cluster-api-core"]
  contexts = {
    pkg-local = "${CAPI_DIR}/core/cluster-api"
  }
  args = {
    VERSION = CAPI_CORE_VERSION
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/core/cluster-api"]
}

target "_cluster-api-bootstrap" {
  args = {
    PROVIDER_TYPE = "bootstrap"
    PROVIDER_TYPE_GO = "BootstrapProvider"
  }
}

target "_cluster-api-control-plane" {
  args = {
    PROVIDER_TYPE = "control-plane"
    PROVIDER_TYPE_GO = "ControlPlaneProvider"
  }
}

target "_cluster-api-infrastructure" {
  args = {
    PROVIDER_TYPE = "infrastructure"
    PROVIDER_TYPE_GO = "InfrastructureProvider"
  }
}

target "cluster-api-bootstrap-kubeadm" {
  inherits = ["_common", "_cluster-api-provider", "_cluster-api-bootstrap"]
  contexts = {
    pkg-local = "${CAPI_DIR}/bootstrap/kubeadm"
  }
  args = {
    PROVIDER_NAME = "kubeadm"
    NAMESPACE = "capi-kubeadm-bootstrap-system"
    VERSION = CAPI_BOOTSTRAP_KUBEADM_VERSION
    GITHUB_ORG = "kubernetes-sigs"
    GITHUB_REPO = "cluster-api"
    FILENAME = "bootstrap-components.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/bootstrap/kubeadm"]
}

target "cluster-api-bootstrap-talos" {
  inherits = ["_common", "_cluster-api-provider", "_cluster-api-bootstrap"]
  contexts = {
    pkg-local = "${CAPI_DIR}/bootstrap/talos"
  }
  args = {
    PROVIDER_NAME = "talos"
    NAMESPACE = "cabpt-system"
    VERSION = CAPI_BOOTSTRAP_TALOS_VERSION
    GITHUB_ORG = "siderolabs"
    GITHUB_REPO = "cluster-api-bootstrap-provider-talos"
    FILENAME = "bootstrap-components.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/bootstrap/talos"]
}

target "cluster-api-control-plane-kubeadm" {
  inherits = ["_common", "_cluster-api-provider", "_cluster-api-control-plane"]
  contexts = {
    pkg-local = "${CAPI_DIR}/control-plane/kubeadm"
  }
  args = {
    PROVIDER_NAME = "kubeadm"
    NAMESPACE = "capi-kubeadm-control-plane-system"
    VERSION = CAPI_CONTROLPLANE_KUBEADM_VERSION
    GITHUB_ORG = "kubernetes-sigs"
    GITHUB_REPO = "cluster-api"
    FILENAME = "control-plane-components.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/control-plane/kubeadm"]
}

target "cluster-api-control-plane-talos" {
  inherits = ["_common", "_cluster-api-provider", "_cluster-api-control-plane"]
  contexts = {
    pkg-local = "${CAPI_DIR}/control-plane/talos"
  }
  args = {
    PROVIDER_NAME = "talos"
    NAMESPACE = "cacppt-system"
    VERSION = CAPI_CONTROLPLANE_TALOS_VERSION
    GITHUB_ORG = "siderolabs"
    GITHUB_REPO = "cluster-api-control-plane-provider-talos"
    FILENAME = "control-plane-components.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/control-plane/talos"]
}

target "cluster-api-infrastructure-docker" {
  inherits = ["_common", "_cluster-api-provider", "_cluster-api-infrastructure"]
  contexts = {
    pkg-local = "${CAPI_DIR}/infrastructure/docker"
  }
  args = {
    PROVIDER_NAME = "docker"
    NAMESPACE = "capd-system"
    VERSION = CAPI_INFRASTRUCTURE_DOCKER_VERSION
    GITHUB_ORG = "kubernetes-sigs"
    GITHUB_REPO = "cluster-api"
    FILENAME = "infrastructure-components-development.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/infrastructure/docker"]
}

target "cluster-api-infrastructure-sidero" {
  inherits = ["_common", "_cluster-api-provider", "_cluster-api-infrastructure"]
  contexts = {
    pkg-local = "${CAPI_DIR}/infrastructure/sidero"
  }
  args = {
    PROVIDER_NAME = "sidero"
    NAMESPACE = "sidero-system"
    VERSION = CAPI_INFRASTRUCTURE_SIDERO_VERSION
    GITHUB_ORG = "siderolabs"
    GITHUB_REPO = "sidero"
    FILENAME = "infrastructure-components.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/infrastructure/sidero"]
}

group "cluster-api-workload-sidero" {
  targets = [
    "cluster-api-workload-sidero-cluster",
    "cluster-api-workload-sidero-control-plane",
    "cluster-api-workload-sidero-workers",
    "cluster-api-workload-sidero-serverclass",
    "cluster-api-workload-sidero-environment",
  ]
}

target "_cluster-api-workload-sidero" {
  inherits = ["_common", "_cluster-api-workload"]
  args = {
    PKG_SINK_SOURCE = "pkg-sink-source-sidero-cluster"
    PROVIDER_NAME = "sidero"
    NAMESPACE = "sidero-system"
    VERSION = CAPI_INFRASTRUCTURE_SIDERO_VERSION
    GITHUB_ORG = "siderolabs"
    GITHUB_REPO = "sidero"
    FILENAME = "cluster-template.yaml"
    ENVIRONMENT_VARIABLES = join("\n", [
      "CLUSTER_NAME=clustername",
      "CONTROL_PLANE_MACHINE_COUNT=1",
      "WORKER_MACHINE_COUNT=0",
      "CONTROL_PLANE_ENDPOINT=127.0.0.1",
      "CONTROL_PLANE_PORT=6443",
      "CONTROL_PLANE_SERVERCLASS=clustername",
      "WORKER_SERVERCLASS=clustername",
      "TALOS_VERSION=v0.14",
      "KUBERNETES_VERSION=v1.20.15",
    ])
  }
}

target "_cluster-api-workload-sidero-cluster" {
  inherits = ["_cluster-api-workload-sidero"]
  contexts = {
    pkg-local = "${CAPI_WORKLOAD_SIDERO_DIR}/cluster"
    control-plane-pkg-local = "${CAPI_WORKLOAD_SIDERO_DIR}/control-plane"
    workers-pkg-local = "${CAPI_WORKLOAD_SIDERO_DIR}/workers"
  }
}

target "cluster-api-workload-sidero-cluster" {
  inherits = ["_cluster-api-workload-sidero-cluster"]
  target = "cluster-api-workload-sidero-cluster-pkg"
  output = ["${OUTPUT_DIR}/${CAPI_WORKLOAD_SIDERO_DIR}/cluster"]
}

target "cluster-api-workload-sidero-control-plane" {
  inherits = ["_cluster-api-workload-sidero-cluster"]
  target = "cluster-api-workload-sidero-control-plane-pkg"
  output = ["${OUTPUT_DIR}/${CAPI_WORKLOAD_SIDERO_DIR}/control-plane"]
}

target "cluster-api-workload-sidero-workers" {
  inherits = ["_cluster-api-workload-sidero-cluster"]
  target = "cluster-api-workload-sidero-workers-pkg"
  output = ["${OUTPUT_DIR}/${CAPI_WORKLOAD_SIDERO_DIR}/workers"]
}

target "cluster-api-workload-sidero-serverclass" {
  inherits = ["_cluster-api-workload-sidero"]
  contexts = {
    pkg-local = "${CAPI_WORKLOAD_SIDERO_DIR}/serverclass"
  }
  args = {
    PKG_SINK_SOURCE = "pkg-sink-source-sidero-serverclass"
  }
  output = ["${OUTPUT_DIR}/${CAPI_WORKLOAD_SIDERO_DIR}/serverclass"]
}

target "cluster-api-workload-sidero-environment" {
  inherits = ["_cluster-api-workload-sidero"]
  contexts = {
    pkg-local = "${CAPI_WORKLOAD_SIDERO_DIR}/environment"
  }
  args = {
    PKG_SINK_SOURCE = "pkg-sink-source-sidero-environment"
  }
  output = ["${OUTPUT_DIR}/${CAPI_WORKLOAD_SIDERO_DIR}/environment"]
}

target "cluster-api-clusterctl-crds" {
  inherits = ["_common"]
  contexts = {
    pkg-local = "${CAPI_DIR}/clusterctl-crds"
  }
  args = {
    FILENAME = "fetch-github-release-file"
    URL = "https://raw.githubusercontent.com/kubernetes-sigs/cluster-api/${CLUSTERCTL_VERSION}/cmd/clusterctl/config/manifest/clusterctl-api.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/clusterctl-crds"]
}

group "examples" {
  targets = [
    "examples-cluster-api-management-docker",
    "examples-cluster-api-management-sidero",
    "examples-cluster-api-workload-sidero",
  ]
}

target "_examples" {
  inherits = ["_common"]
  target = "example-artifacts"
  contexts = {
    repo-source = ".git"
  }
}

target "examples-cluster-api-management-docker" {
  inherits = ["_common", "_examples"]
  contexts = {
    example-source = "./examples/cluster-api-management-docker"
  }
  output = ["${ARTIFACTS_DIR}/examples/cluster-api-management-docker"]
}

target "examples-cluster-api-management-sidero" {
  inherits = ["_common", "_examples"]
  contexts = {
    example-source = "./examples/cluster-api-management-sidero"
  }
  output = ["${ARTIFACTS_DIR}/examples/cluster-api-management-sidero"]
}

target "examples-cluster-api-workload-sidero" {
  inherits = ["_examples"]
  contexts = {
    example-source = "./examples/cluster-api-workload-sidero"
  }
  output = ["${ARTIFACTS_DIR}/examples/cluster-api-workload-sidero"]
}
