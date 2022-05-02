variable "OUTPUT_DIR" {default = "."}
variable "ARTIFACTS_DIR" {default = "${OUTPUT_DIR}/_out"}
variable "CAPI_DIR" {default = "cluster-api"}
variable "CAPI_V1ALPHA3_DIR" {default = "${CAPI_DIR}/v1alpha3"}
variable "CAPI_V1ALPHA3_WORKLOAD_DIR" {default = "${CAPI_V1ALPHA3_DIR}/workload"}
variable "CAPI_V1ALPHA3_WORKLOAD_SIDERO_DIR" {default = "${CAPI_V1ALPHA3_WORKLOAD_DIR}/sidero"}

variable "KPT_VERSION" {default = "v1.0.0-beta.13"}
variable "CERT_MANAGER_VERSION" {default = "v1.5.5"}
variable "CLUSTERCTL_VERSION" {default = CAPI_V1BETA1_CORE_VERSION}
variable "KUBECTL_VERSION" {default = "1.23.5"}
variable "CAPI_V1ALPHA3_CORE_VERSION" {default = "v0.3.25"}
variable "CAPI_V1ALPHA4_CORE_VERSION" {default = "v0.4.7"}
variable "CAPI_V1BETA1_CORE_VERSION" {default = "v1.1.2"}

# cluster-api v1alpha3
variable "CAPI_V1ALPHA3_BOOTSTRAP_KUBEADM_VERSION" {default = "${CAPI_V1ALPHA3_CORE_VERSION}"}
variable "CAPI_V1ALPHA3_BOOTSTRAP_TALOS_VERSION" {default = "v0.3.2"}
variable "CAPI_V1ALPHA3_CONTROLPLANE_KUBEADM_VERSION" {default = "${CAPI_V1ALPHA3_CORE_VERSION}"}
variable "CAPI_V1ALPHA3_CONTROLPLANE_TALOS_VERSION" {default = "v0.2.0"}
variable "CAPI_V1ALPHA3_INFRASTRUCTURE_DOCKER_VERSION" {default = "${CAPI_V1ALPHA3_CORE_VERSION}"}
variable "CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION" {default = "v0.3.3"}

# cluster-api v1alpha4
variable "CAPI_V1ALPHA4_BOOTSTRAP_KUBEADM_VERSION" {default = "${CAPI_V1ALPHA4_CORE_VERSION}"}
variable "CAPI_V1ALPHA4_BOOTSTRAP_TALOS_VERSION" {default = "v0.4.3"}
variable "CAPI_V1ALPHA4_CONTROLPLANE_KUBEADM_VERSION" {default = "${CAPI_V1ALPHA4_CORE_VERSION}"}
variable "CAPI_V1ALPHA4_CONTROLPLANE_TALOS_VERSION" {default = "v0.3.1"}
variable "CAPI_V1ALPHA4_INFRASTRUCTURE_DOCKER_VERSION" {default = "${CAPI_V1ALPHA4_CORE_VERSION}"}
variable "CAPI_V1ALPHA4_INFRASTRUCTURE_SIDERO_VERSION" {default = "v0.4.1"}

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
      "cert-manager/${CERT_MANAGER_VERSION}",
      # CAPI v1alpha3
      "cluster-api/v1alpha3/core/cluster-api/${CAPI_V1ALPHA3_CORE_VERSION}",
      "cluster-api/v1alpha3/bootstrap/talos/${CAPI_V1ALPHA3_BOOTSTRAP_TALOS_VERSION}",
      "cluster-api/v1alpha3/bootstrap/kubeadm/${CAPI_V1ALPHA3_BOOTSTRAP_KUBEADM_VERSION}",
      "cluster-api/v1alpha3/control-plane/talos/${CAPI_V1ALPHA3_CONTROLPLANE_TALOS_VERSION}",
      "cluster-api/v1alpha3/control-plane/kubeadm/${CAPI_V1ALPHA3_CONTROLPLANE_KUBEADM_VERSION}",
      "cluster-api/v1alpha3/infrastructure/docker/${CAPI_V1ALPHA3_INFRASTRUCTURE_DOCKER_VERSION}",
      "cluster-api/v1alpha3/infrastructure/sidero/${CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION}",
      "cluster-api/v1alpha3/workload/sidero/cluster${CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION}",
      "cluster-api/v1alpha3/workload/sidero/control-plane${CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION}",
      "cluster-api/v1alpha3/workload/sidero/environment${CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION}",
      "cluster-api/v1alpha3/workload/sidero/serverclass${CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION}",
      "cluster-api/v1alpha3/workload/sidero/workers${CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION}",
      # CAPI v1alpha4
      "cluster-api/v1alpha4/core/cluster-api/${CAPI_V1ALPHA4_CORE_VERSION}",
      "cluster-api/v1alpha4/bootstrap/talos/${CAPI_V1ALPHA4_BOOTSTRAP_TALOS_VERSION}",
      "cluster-api/v1alpha4/bootstrap/kubeadm/${CAPI_V1ALPHA4_BOOTSTRAP_KUBEADM_VERSION}",
      "cluster-api/v1alpha4/control-plane/talos/${CAPI_V1ALPHA4_CONTROLPLANE_TALOS_VERSION}",
      "cluster-api/v1alpha4/control-plane/kubeadm/${CAPI_V1ALPHA4_CONTROLPLANE_KUBEADM_VERSION}",
      "cluster-api/v1alpha4/infrastructure/docker/${CAPI_V1ALPHA4_INFRASTRUCTURE_DOCKER_VERSION}",
      "cluster-api/v1alpha4/infrastructure/sidero/${CAPI_V1ALPHA4_INFRASTRUCTURE_SIDERO_VERSION}",
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
    "cluster-api-providers-v1alpha3",
    "cluster-api-providers-v1alpha4"
  ]
}

group "cluster-api-providers-v1alpha3" {
  targets = [
    "cluster-api-v1alpha3-core",
    "cluster-api-v1alpha3-bootstrap-kubeadm",
    "cluster-api-v1alpha3-bootstrap-talos",
    "cluster-api-v1alpha3-control-plane-kubeadm",
    "cluster-api-v1alpha3-control-plane-talos",
    "cluster-api-v1alpha3-infrastructure-docker",
    "cluster-api-v1alpha3-infrastructure-sidero",
  ]
}

group "cluster-api-providers-v1alpha4" {
  targets = [
    "cluster-api-v1alpha4-core",
    "cluster-api-v1alpha4-bootstrap-kubeadm",
    "cluster-api-v1alpha4-bootstrap-talos",
    "cluster-api-v1alpha4-control-plane-kubeadm",
    "cluster-api-v1alpha4-control-plane-talos",
    "cluster-api-v1alpha4-infrastructure-docker",
    "cluster-api-v1alpha4-infrastructure-sidero",
  ]
}

group "cluster-api-workloads" {
  targets = [
    "cluster-api-v1alpha3-workload-sidero",
  ]
}

target "_cluster-api" {
  inherits = ["_common"]
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

target "_cluster-api-v1alpha3" {
  inherits = ["_cluster-api"]
  args = {
    CAPI_API_GROUP = "v1alpha3"
  }
}

target "_cluster-api-v1alpha4" {
  inherits = ["_cluster-api"]
  args = {
    CAPI_API_GROUP = "v1alpha4"
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

target "cluster-api-v1alpha3-core" {
  inherits = ["_cluster-api-v1alpha3", "_cluster-api-provider", "_cluster-api-core"]
  contexts = {
    pkg-local = "${CAPI_DIR}/v1alpha3/core/cluster-api"
  }
  args = {
    VERSION = CAPI_V1ALPHA3_CORE_VERSION
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/v1alpha3/core/cluster-api"]
}

target "cluster-api-v1alpha4-core" {
  inherits = ["_cluster-api-v1alpha4", "_cluster-api-provider", "_cluster-api-core"]
  contexts = {
    pkg-local = "${CAPI_DIR}/v1alpha4/core/cluster-api"
  }
  args = {
    VERSION = CAPI_V1ALPHA4_CORE_VERSION
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/v1alpha4/core/cluster-api"]
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

target "cluster-api-v1alpha3-bootstrap-kubeadm" {
  inherits = ["_cluster-api-v1alpha3", "_cluster-api-provider", "_cluster-api-bootstrap"]
  contexts = {
    pkg-local = "${CAPI_DIR}/v1alpha3/bootstrap/kubeadm"
  }
  args = {
    PROVIDER_NAME = "kubeadm"
    NAMESPACE = "capi-kubeadm-bootstrap-system"
    VERSION = CAPI_V1ALPHA3_BOOTSTRAP_KUBEADM_VERSION
    GITHUB_ORG = "kubernetes-sigs"
    GITHUB_REPO = "cluster-api"
    FILENAME = "bootstrap-components.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/v1alpha3/bootstrap/kubeadm"]
}

target "cluster-api-v1alpha4-bootstrap-kubeadm" {
  inherits = ["_cluster-api-v1alpha4", "_cluster-api-provider", "_cluster-api-bootstrap"]
  contexts = {
    pkg-local = "${CAPI_DIR}/v1alpha4/bootstrap/kubeadm"
  }
  args = {
    PROVIDER_NAME = "kubeadm"
    NAMESPACE = "capi-kubeadm-bootstrap-system"
    VERSION = CAPI_V1ALPHA4_BOOTSTRAP_KUBEADM_VERSION
    GITHUB_ORG = "kubernetes-sigs"
    GITHUB_REPO = "cluster-api"
    FILENAME = "bootstrap-components.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/v1alpha4/bootstrap/kubeadm"]
}

target "cluster-api-v1alpha3-bootstrap-talos" {
  inherits = ["_cluster-api-v1alpha3", "_cluster-api-provider", "_cluster-api-bootstrap"]
  contexts = {
    pkg-local = "${CAPI_DIR}/v1alpha3/bootstrap/talos"
  }
  args = {
    PROVIDER_NAME = "talos"
    NAMESPACE = "cabpt-system"
    VERSION = CAPI_V1ALPHA3_BOOTSTRAP_TALOS_VERSION
    GITHUB_ORG = "siderolabs"
    GITHUB_REPO = "cluster-api-bootstrap-provider-talos"
    FILENAME = "bootstrap-components.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/v1alpha3/bootstrap/talos"]
}

target "cluster-api-v1alpha4-bootstrap-talos" {
  inherits = ["_cluster-api-v1alpha4", "_cluster-api-provider", "_cluster-api-bootstrap"]
  contexts = {
    pkg-local = "${CAPI_DIR}/v1alpha4/bootstrap/talos"
  }
  args = {
    PROVIDER_NAME = "talos"
    NAMESPACE = "cabpt-system"
    VERSION = CAPI_V1ALPHA4_BOOTSTRAP_TALOS_VERSION
    GITHUB_ORG = "siderolabs"
    GITHUB_REPO = "cluster-api-bootstrap-provider-talos"
    FILENAME = "bootstrap-components.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/v1alpha4/bootstrap/talos"]
}

target "cluster-api-v1alpha3-control-plane-kubeadm" {
  inherits = ["_cluster-api-v1alpha3", "_cluster-api-provider", "_cluster-api-control-plane"]
  contexts = {
    pkg-local = "${CAPI_DIR}/v1alpha3/control-plane/kubeadm"
  }
  args = {
    PROVIDER_NAME = "kubeadm"
    NAMESPACE = "capi-kubeadm-control-plane-system"
    VERSION = CAPI_V1ALPHA3_CONTROLPLANE_KUBEADM_VERSION
    GITHUB_ORG = "kubernetes-sigs"
    GITHUB_REPO = "cluster-api"
    FILENAME = "control-plane-components.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/v1alpha3/control-plane/kubeadm"]
}

target "cluster-api-v1alpha4-control-plane-kubeadm" {
  inherits = ["_cluster-api-v1alpha4", "_cluster-api-provider", "_cluster-api-control-plane"]
  contexts = {
    pkg-local = "${CAPI_DIR}/v1alpha4/control-plane/kubeadm"
  }
  args = {
    PROVIDER_NAME = "kubeadm"
    NAMESPACE = "capi-kubeadm-control-plane-system"
    VERSION = CAPI_V1ALPHA4_CONTROLPLANE_KUBEADM_VERSION
    GITHUB_ORG = "kubernetes-sigs"
    GITHUB_REPO = "cluster-api"
    FILENAME = "control-plane-components.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/v1alpha4/control-plane/kubeadm"]
}

target "cluster-api-v1alpha3-control-plane-talos" {
  inherits = ["_cluster-api-v1alpha3", "_cluster-api-provider", "_cluster-api-control-plane"]
  contexts = {
    pkg-local = "${CAPI_DIR}/v1alpha3/control-plane/talos"
  }
  args = {
    PROVIDER_NAME = "talos"
    NAMESPACE = "cacppt-system"
    VERSION = CAPI_V1ALPHA3_CONTROLPLANE_TALOS_VERSION
    GITHUB_ORG = "siderolabs"
    GITHUB_REPO = "cluster-api-control-plane-provider-talos"
    FILENAME = "control-plane-components.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/v1alpha3/control-plane/talos"]
}

target "cluster-api-v1alpha4-control-plane-talos" {
  inherits = ["_cluster-api-v1alpha4", "_cluster-api-provider", "_cluster-api-control-plane"]
  contexts = {
    pkg-local = "${CAPI_DIR}/v1alpha4/control-plane/talos"
  }
  args = {
    PROVIDER_NAME = "talos"
    NAMESPACE = "cacppt-system"
    VERSION = CAPI_V1ALPHA4_CONTROLPLANE_TALOS_VERSION
    GITHUB_ORG = "siderolabs"
    GITHUB_REPO = "cluster-api-control-plane-provider-talos"
    FILENAME = "control-plane-components.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/v1alpha4/control-plane/talos"]
}

target "cluster-api-v1alpha3-infrastructure-docker" {
  inherits = ["_cluster-api-v1alpha3", "_cluster-api-provider", "_cluster-api-infrastructure"]
  contexts = {
    pkg-local = "${CAPI_DIR}/v1alpha3/infrastructure/docker"
  }
  args = {
    PROVIDER_NAME = "docker"
    NAMESPACE = "capd-system"
    VERSION = CAPI_V1ALPHA3_INFRASTRUCTURE_DOCKER_VERSION
    GITHUB_ORG = "kubernetes-sigs"
    GITHUB_REPO = "cluster-api"
    FILENAME = "infrastructure-components-development.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/v1alpha3/infrastructure/docker"]
}

target "cluster-api-v1alpha4-infrastructure-docker" {
  inherits = ["_cluster-api-v1alpha4", "_cluster-api-provider", "_cluster-api-infrastructure"]
  contexts = {
    pkg-local = "${CAPI_DIR}/v1alpha4/infrastructure/docker"
  }
  args = {
    PROVIDER_NAME = "docker"
    NAMESPACE = "capd-system"
    VERSION = CAPI_V1ALPHA4_INFRASTRUCTURE_DOCKER_VERSION
    GITHUB_ORG = "kubernetes-sigs"
    GITHUB_REPO = "cluster-api"
    FILENAME = "infrastructure-components-development.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/v1alpha4/infrastructure/docker"]
}

target "cluster-api-v1alpha3-infrastructure-sidero" {
  inherits = ["_cluster-api-v1alpha3", "_cluster-api-provider", "_cluster-api-infrastructure"]
  contexts = {
    pkg-local = "${CAPI_DIR}/v1alpha3/infrastructure/sidero"
  }
  args = {
    PROVIDER_NAME = "sidero"
    NAMESPACE = "sidero-system"
    VERSION = CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION
    GITHUB_ORG = "siderolabs"
    GITHUB_REPO = "sidero"
    FILENAME = "infrastructure-components.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/v1alpha3/infrastructure/sidero"]
}

target "cluster-api-v1alpha4-infrastructure-sidero" {
  inherits = ["_cluster-api-v1alpha4", "_cluster-api-provider", "_cluster-api-infrastructure"]
  contexts = {
    pkg-local = "${CAPI_DIR}/v1alpha4/infrastructure/sidero"
  }
  args = {
    PROVIDER_NAME = "sidero"
    NAMESPACE = "sidero-system"
    VERSION = CAPI_V1ALPHA4_INFRASTRUCTURE_SIDERO_VERSION
    GITHUB_ORG = "siderolabs"
    GITHUB_REPO = "sidero"
    FILENAME = "infrastructure-components.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/v1alpha4/infrastructure/sidero"]
}

group "cluster-api-v1alpha3-workload-sidero" {
  targets = [
    "cluster-api-v1alpha3-workload-sidero-cluster",
    "cluster-api-v1alpha3-workload-sidero-control-plane",
    "cluster-api-v1alpha3-workload-sidero-workers",
    "cluster-api-v1alpha3-workload-sidero-serverclass",
    "cluster-api-v1alpha3-workload-sidero-environment",
  ]
}

target "_cluster-api-v1alpha3-workload-sidero" {
  inherits = ["_cluster-api-v1alpha3", "_cluster-api-workload"]
  args = {
    PKG_SINK_SOURCE = "pkg-sink-source-sidero-cluster"
    PROVIDER_NAME = "sidero"
    NAMESPACE = "sidero-system"
    VERSION = CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION
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

target "_cluster-api-v1alpha3-workload-sidero-cluster" {
  inherits = ["_cluster-api-v1alpha3-workload-sidero"]
  contexts = {
    pkg-local = "${CAPI_V1ALPHA3_WORKLOAD_SIDERO_DIR}/cluster"
    control-plane-pkg-local = "${CAPI_V1ALPHA3_WORKLOAD_SIDERO_DIR}/control-plane"
    workers-pkg-local = "${CAPI_V1ALPHA3_WORKLOAD_SIDERO_DIR}/workers"
  }
}

target "cluster-api-v1alpha3-workload-sidero-cluster" {
  inherits = ["_cluster-api-v1alpha3-workload-sidero-cluster"]
  target = "cluster-api-v1alpha3-workload-sidero-cluster-pkg"
  output = ["${OUTPUT_DIR}/${CAPI_V1ALPHA3_WORKLOAD_SIDERO_DIR}/cluster"]
}

target "cluster-api-v1alpha3-workload-sidero-control-plane" {
  inherits = ["_cluster-api-v1alpha3-workload-sidero-cluster"]
  target = "cluster-api-v1alpha3-workload-sidero-control-plane-pkg"
  output = ["${OUTPUT_DIR}/${CAPI_V1ALPHA3_WORKLOAD_SIDERO_DIR}/control-plane"]
}

target "cluster-api-v1alpha3-workload-sidero-workers" {
  inherits = ["_cluster-api-v1alpha3-workload-sidero-cluster"]
  target = "cluster-api-v1alpha3-workload-sidero-workers-pkg"
  output = ["${OUTPUT_DIR}/${CAPI_V1ALPHA3_WORKLOAD_SIDERO_DIR}/workers"]
}

target "cluster-api-v1alpha3-workload-sidero-serverclass" {
  inherits = ["_cluster-api-v1alpha3-workload-sidero"]
  contexts = {
    pkg-local = "${CAPI_V1ALPHA3_WORKLOAD_SIDERO_DIR}/serverclass"
  }
  args = {
    PKG_SINK_SOURCE = "pkg-sink-source-sidero-serverclass"
  }
  output = ["${OUTPUT_DIR}/${CAPI_V1ALPHA3_WORKLOAD_SIDERO_DIR}/serverclass"]
}

target "cluster-api-v1alpha3-workload-sidero-environment" {
  inherits = ["_cluster-api-v1alpha3-workload-sidero"]
  contexts = {
    pkg-local = "${CAPI_V1ALPHA3_WORKLOAD_SIDERO_DIR}/environment"
  }
  args = {
    PKG_SINK_SOURCE = "pkg-sink-source-sidero-environment"
  }
  output = ["${OUTPUT_DIR}/${CAPI_V1ALPHA3_WORKLOAD_SIDERO_DIR}/environment"]
}

target "cluster-api-clusterctl-crds" {
  inherits = ["_cluster-api"]
  contexts = {
    pkg-local = "${CAPI_DIR}/clusterctl-crds"
  }
  args = {
    URL = "https://raw.githubusercontent.com/kubernetes-sigs/cluster-api/${CLUSTERCTL_VERSION}/cmd/clusterctl/config/manifest/clusterctl-api.yaml"
  }
  output = ["${OUTPUT_DIR}/${CAPI_DIR}/clusterctl-crds"]
}

group "examples" {
  targets = [
    "examples-cluster-api-v1alpha3-management-docker",
    "examples-cluster-api-v1alpha3-management-sidero",
    "examples-cluster-api-v1alpha3-workload-sidero",
  ]
}

target "_examples" {
  inherits = ["_common"]
  target = "example-artifacts"
  contexts = {
    repo-source = ".git"
  }
}

target "examples-cluster-api-v1alpha3-management-docker" {
  inherits = ["_examples"]
  contexts = {
    example-source = "./examples/cluster-api-v1alpha3-management-docker"
  }
  output = ["${ARTIFACTS_DIR}/examples/cluster-api-v1alpha3-management-docker"]
}

target "examples-cluster-api-v1alpha3-management-sidero" {
  inherits = ["_examples"]
  contexts = {
    example-source = "./examples/cluster-api-v1alpha3-management-sidero"
  }
  output = ["${ARTIFACTS_DIR}/examples/cluster-api-v1alpha3-management-sidero"]
}

target "examples-cluster-api-v1alpha3-workload-sidero" {
  inherits = ["_examples"]
  contexts = {
    example-source = "./examples/cluster-api-v1alpha3-workload-sidero"
  }
  output = ["${ARTIFACTS_DIR}/examples/cluster-api-v1alpha3-workload-sidero"]
}
