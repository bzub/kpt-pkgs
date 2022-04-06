variable "ROOT_DIR" {default = "."}
variable "CLUSTER_API_DIR" {default = "${ROOT_DIR}/cluster-api"}

variable "KPT_VERSION" {default = "v1.0.0-beta.13"}
variable "CERT_MANAGER_VERSION" {default = "v1.1.1"}
variable "CLUSTERCTL_VERSION" {default = CAPI_V1BETA1_CORE_VERSION}
variable "CAPI_V1ALPHA3_CORE_VERSION" {default = "v0.3.25"}
variable "CAPI_V1ALPHA4_CORE_VERSION" {default = "v0.4.7"}
variable "CAPI_V1BETA1_CORE_VERSION" {default = "v1.1.2"}
variable "CAPI_V1ALPHA3_BOOTSTRAP_KUBEADM_VERSION" {default = "${CAPI_V1ALPHA3_CORE_VERSION}"}
variable "CAPI_V1ALPHA3_BOOTSTRAP_TALOS_VERSION" {default = "v0.3.2"}
variable "CAPI_V1ALPHA3_CONTROLPLANE_KUBEADM_VERSION" {default = "${CAPI_V1ALPHA3_CORE_VERSION}"}
variable "CAPI_V1ALPHA3_CONTROLPLANE_TALOS_VERSION" {default = "v0.2.0"}
variable "CAPI_V1ALPHA3_INFRASTRUCTURE_DOCKER_VERSION" {default = "${CAPI_V1ALPHA3_CORE_VERSION}"}
variable "CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION" {default = "v0.3.3"}

variable "KPT_IMAGE" {default = "docker-image://ghcr.io/bzub/images/kpt:${KPT_VERSION}"}
variable "CLUSTERCTL_IMAGE" {default = "docker-image://ghcr.io/bzub/images/clusterctl:${CLUSTERCTL_VERSION}"}
variable "KPT_FN_SEARCH_REPLACE_IMAGE" {default = "docker-image://gcr.io/kpt-fn/search-replace@sha256:c8da9c025eea6bef4426c1eb1c12158da7bd795f8912fc83a170d490b3240a8b"}
variable "KPT_FN_SET_ANNOTATIONS_IMAGE" {default = "docker-image://gcr.io/kpt-fn/set-annotations@sha256:6285fca0192e26c0ae090f26103a3661282260c69c80a794fbf6481082101ea6"}
variable "KPT_FN_SET_NAMESPACE_IMAGE" {default = "docker-image://gcr.io/kpt-fn/set-namespace@sha256:a457b9266764ae42c94b2ecd6690e4fc858295b2c58a7043d9e486697ef8b201"}
variable "KPT_FN_CREATE_SETTERS_IMAGE" {default = "docker-image://gcr.io/kpt-fn/create-setters@sha256:76ec527190c3826196db133c32db5d29c228876f0c4b5e692781f68e2dcc7536"}
variable "KPT_FN_APPLY_SETTERS_IMAGE" {default = "docker-image://gcr.io/kpt-fn/apply-setters@sha256:d322a18de00daf566b48bc7cbebf4814bc87cecf783d494ccaf9294bf23c6392"}
variable "KPT_FN_STARLARK_IMAGE" {default = "docker-image://gcr.io/kpt-fn/starlark@sha256:416188026608fbea937ebf2e287ae8aa277651884520621357b7f5115261a04e"}
variable "KPT_FN_SET_LABELS_IMAGE" {default = "docker-image://gcr.io/kpt-fn/set-labels@sha256:d088e20cd2c9067e433398161cd7adda3d23226e1afeda37ea2b8029eaf3852f"}
variable "KPT_FN_ENSURE_NAME_SUBSTRING_IMAGE" {default = "docker-image://gcr.io/kpt-fn/ensure-name-substring@sha256:027d1fcdfa839d991cb6ddf924d339569d20a7dff70cd821642cb0d053739010"}
variable "KPT_FN_APPLY_REPLACEMENTS_IMAGE" {default = "docker-image://gcr.io/kpt-fn/apply-replacements@sha256:7c494199513277e95fe28e13a0198ea69d8e6cc4100c4a417d0c93995ce41215"}

group "default" {
  targets = [
    "cert-manager",
    "cluster-api",
  ]
}

target "_common" {
  contexts = {
    kpt = KPT_IMAGE
    clusterctl = CLUSTERCTL_IMAGE
    kpt-fn-search-replace = KPT_FN_SEARCH_REPLACE_IMAGE
    kpt-fn-set-annotations = KPT_FN_SET_ANNOTATIONS_IMAGE
    kpt-fn-set-namespace = KPT_FN_SET_NAMESPACE_IMAGE
    kpt-fn-create-setters = KPT_FN_CREATE_SETTERS_IMAGE
    kpt-fn-apply-setters = KPT_FN_APPLY_SETTERS_IMAGE
    kpt-fn-starlark = KPT_FN_STARLARK_IMAGE
    kpt-fn-set-labels = KPT_FN_SET_LABELS_IMAGE
    kpt-fn-ensure-name-substring = KPT_FN_ENSURE_NAME_SUBSTRING_IMAGE
    kpt-fn-apply-replacements = KPT_FN_APPLY_REPLACEMENTS_IMAGE
  }
  args = {
    FETCH_RESOURCES_IMAGE = "fetch-github-release-file"
    PKG_SOURCE = "pkg_rename_files"
    PKG_SINK_SOURCE = "kpt-fn-sink"
  }
}

target "git-tag-packages" {
  inherits = ["_common"]
  target = "git-tag-packages"
  args = {
    GIT_TAGS = join(" ", [
      "cert-manager/${CERT_MANAGER_VERSION}",
      "cluster-api/v1alpha3/core/cluster-api/${CAPI_V1ALPHA3_CORE_VERSION}",
      "cluster-api/v1alpha3/bootstrap/talos/${CAPI_V1ALPHA3_BOOTSTRAP_TALOS_VERSION}",
      "cluster-api/v1alpha3/bootstrap/kubeadm/${CAPI_V1ALPHA3_BOOTSTRAP_KUBEADM_VERSION}",
      "cluster-api/v1alpha3/control-plane/talos/${CAPI_V1ALPHA3_CONTROLPLANE_TALOS_VERSION}",
      "cluster-api/v1alpha3/control-plane/kubeadm/${CAPI_V1ALPHA3_CONTROLPLANE_KUBEADM_VERSION}",
      "cluster-api/v1alpha3/infrastructure/docker/${CAPI_V1ALPHA3_INFRASTRUCTURE_DOCKER_VERSION}",
      "cluster-api/v1alpha3/infrastructure/sidero/${CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION}",
      "cluster-api/v1alpha3/cluster/sidero/${CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION}",
    ])
  }
  output = ["${ROOT_DIR}/.git"]
}

target "cert-manager" {
  inherits = ["_common"]
  contexts = {
    pkg-local = "./cert-manager"
  }
  target = "pkg"
  args = {
    GITHUB_ORG = "cert-manager"
    GITHUB_REPO = "cert-manager"
    VERSION = CERT_MANAGER_VERSION
    FILENAME = "cert-manager.yaml"
  }
  output = ["${ROOT_DIR}/cert-manager"]
  platforms = []
}

group "cluster-api" {
  targets = [
    "cluster-api-providers",
    "cluster-api-clusters",
  ]
}

group "cluster-api-providers" {
  targets = [
    "cluster-api-v1alpha3-core",
    "cluster-api-v1alpha3-bootstrap-kubeadm",
    "cluster-api-v1alpha3-bootstrap-talos",
    "cluster-api-v1alpha3-control-plane-kubeadm",
    "cluster-api-v1alpha3-control-plane-talos",
    "cluster-api-v1alpha3-infrastructure-docker",
    "cluster-api-v1alpha3-infrastructure-sidero",
    "cluster-api-v1alpha3-cluster-sidero",
  ]
}

group "cluster-api-clusters" {
  targets = [
    "cluster-api-v1alpha3-cluster-sidero",
  ]
}

target "_cluster-api" {
  inherits = ["_common"]
  target = "pkg"
}

target "_cluster-api-provider" {
  args = {
    FETCH_RESOURCES_IMAGE = "add-clusterctl-provider-resource"
  }
}

target "_cluster-api-cluster" {
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

target "cluster-api-v1alpha3-core" {
  inherits = ["_cluster-api-v1alpha3", "_cluster-api-provider"]
  contexts = {
    pkg-local = "${CLUSTER_API_DIR}/v1alpha3/core/cluster-api"
  }
  args = {
    PROVIDER_TYPE = "core"
    PROVIDER_TYPE_GO = "CoreProvider"
    PROVIDER_NAME = "cluster-api"
    NAMESPACE = "capi-system"
    VERSION = CAPI_V1ALPHA3_CORE_VERSION
    GITHUB_ORG = "kubernetes-sigs"
    GITHUB_REPO = "cluster-api"
    FILENAME = "core-components.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/core/cluster-api"]
}

target "_cluster-api-v1alpha3-bootstrap" {
  inherits = ["_cluster-api-v1alpha3", "_cluster-api-provider"]
  args = {
    PROVIDER_TYPE = "bootstrap"
    PROVIDER_TYPE_GO = "BootstrapProvider"
  }
}

target "_cluster-api-v1alpha3-control-plane" {
  inherits = ["_cluster-api-v1alpha3", "_cluster-api-provider"]
  args = {
    PROVIDER_TYPE = "control-plane"
    PROVIDER_TYPE_GO = "ControlPlaneProvider"
  }
}

target "_cluster-api-v1alpha3-infrastructure" {
  inherits = ["_cluster-api-v1alpha3", "_cluster-api-provider"]
  args = {
    PROVIDER_TYPE = "infrastructure"
    PROVIDER_TYPE_GO = "InfrastructureProvider"
  }
}

target "_cluster-api-v1alpha3-cluster" {
  inherits = ["_cluster-api-v1alpha3", "_cluster-api-cluster"]
}

target "cluster-api-v1alpha3-bootstrap-kubeadm" {
  inherits = ["_cluster-api-v1alpha3-bootstrap"]
  contexts = {
    pkg-local = "${CLUSTER_API_DIR}/v1alpha3/bootstrap/kubeadm"
  }
  args = {
    PROVIDER_NAME = "kubeadm"
    NAMESPACE = "capi-kubeadm-bootstrap-system"
    VERSION = CAPI_V1ALPHA3_BOOTSTRAP_KUBEADM_VERSION
    GITHUB_ORG = "kubernetes-sigs"
    GITHUB_REPO = "cluster-api"
    FILENAME = "bootstrap-components.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/bootstrap/kubeadm"]
}

target "cluster-api-v1alpha3-bootstrap-talos" {
  inherits = ["_cluster-api-v1alpha3-bootstrap"]
  contexts = {
    pkg-local = "${CLUSTER_API_DIR}/v1alpha3/bootstrap/talos"
  }
  args = {
    PROVIDER_NAME = "talos"
    NAMESPACE = "cabpt-system"
    VERSION = CAPI_V1ALPHA3_BOOTSTRAP_TALOS_VERSION
    GITHUB_ORG = "siderolabs"
    GITHUB_REPO = "cluster-api-bootstrap-provider-talos"
    FILENAME = "bootstrap-components.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/bootstrap/talos"]
}

target "cluster-api-v1alpha3-control-plane-kubeadm" {
  inherits = ["_cluster-api-v1alpha3-control-plane"]
  contexts = {
    pkg-local = "${CLUSTER_API_DIR}/v1alpha3/control-plane/kubeadm"
  }
  args = {
    PROVIDER_NAME = "kubeadm"
    NAMESPACE = "capi-kubeadm-control-plane-system"
    VERSION = CAPI_V1ALPHA3_CONTROLPLANE_KUBEADM_VERSION
    GITHUB_ORG = "kubernetes-sigs"
    GITHUB_REPO = "cluster-api"
    FILENAME = "control-plane-components.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/control-plane/kubeadm"]
}

target "cluster-api-v1alpha3-control-plane-talos" {
  inherits = ["_cluster-api-v1alpha3-control-plane"]
  contexts = {
    pkg-local = "${CLUSTER_API_DIR}/v1alpha3/control-plane/talos"
  }
  args = {
    PROVIDER_NAME = "talos"
    NAMESPACE = "cacppt-system"
    VERSION = CAPI_V1ALPHA3_CONTROLPLANE_TALOS_VERSION
    GITHUB_ORG = "siderolabs"
    GITHUB_REPO = "cluster-api-control-plane-provider-talos"
    FILENAME = "control-plane-components.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/control-plane/talos"]
}

target "cluster-api-v1alpha3-infrastructure-docker" {
  inherits = ["_cluster-api-v1alpha3-infrastructure"]
  contexts = {
    pkg-local = "${CLUSTER_API_DIR}/v1alpha3/infrastructure/docker"
  }
  args = {
    PROVIDER_NAME = "docker"
    NAMESPACE = "capd-system"
    VERSION = CAPI_V1ALPHA3_INFRASTRUCTURE_DOCKER_VERSION
    GITHUB_ORG = "kubernetes-sigs"
    GITHUB_REPO = "cluster-api"
    FILENAME = "infrastructure-components-development.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/infrastructure/docker"]
}

target "cluster-api-v1alpha3-infrastructure-sidero" {
  inherits = ["_cluster-api-v1alpha3-infrastructure"]
  contexts = {
    pkg-local = "${CLUSTER_API_DIR}/v1alpha3/infrastructure/sidero"
  }
  args = {
    PROVIDER_NAME = "sidero"
    NAMESPACE = "sidero-system"
    VERSION = CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION
    GITHUB_ORG = "siderolabs"
    GITHUB_REPO = "sidero"
    FILENAME = "infrastructure-components.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/infrastructure/sidero"]
}

group "cluster-api-v1alpha3-cluster-sidero" {
  targets = [
    "cluster-api-v1alpha3-cluster-sidero-cluster",
    "cluster-api-v1alpha3-cluster-sidero-machinedeployment",
    "cluster-api-v1alpha3-cluster-sidero-metalmachinetemplate",
    "cluster-api-v1alpha3-cluster-sidero-serverclass",
    "cluster-api-v1alpha3-cluster-sidero-talosconfigtemplate",
    "cluster-api-v1alpha3-cluster-sidero-taloscontrolplane",
  ]
}

target "_cluster-api-v1alpha3-cluster-sidero" {
  inherits = ["_cluster-api-v1alpha3-cluster"]
  contexts = {
    pkg-local = "${CLUSTER_API_DIR}/v1alpha3/cluster/sidero"
  }
  args = {
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

target "cluster-api-v1alpha3-cluster-sidero-cluster" {
  inherits = ["_cluster-api-v1alpha3-cluster-sidero"]
  contexts = {
    pkg-local = "${CLUSTER_API_DIR}/v1alpha3/cluster/sidero/cluster"
  }
  args = {
    PKG_SINK_SOURCE = "pkg-sink-source-sidero-cluster"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/cluster/sidero/cluster"]
}

target "cluster-api-v1alpha3-cluster-sidero-machinedeployment" {
  inherits = ["_cluster-api-v1alpha3-cluster-sidero"]
  contexts = {
    pkg-local = "${CLUSTER_API_DIR}/v1alpha3/cluster/sidero/machinedeployment"
  }
  args = {
    PKG_SINK_SOURCE = "pkg-sink-source-sidero-machinedeployment"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/cluster/sidero/machinedeployment"]
}

target "cluster-api-v1alpha3-cluster-sidero-metalmachinetemplate" {
  inherits = ["_cluster-api-v1alpha3-cluster-sidero"]
  contexts = {
    pkg-local = "${CLUSTER_API_DIR}/v1alpha3/cluster/sidero/metalmachinetemplate"
  }
  args = {
    PKG_SINK_SOURCE = "pkg-sink-source-sidero-metalmachinetemplate"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/cluster/sidero/metalmachinetemplate"]
}

target "cluster-api-v1alpha3-cluster-sidero-serverclass" {
  inherits = ["_cluster-api-v1alpha3-cluster-sidero"]
  contexts = {
    pkg-local = "${CLUSTER_API_DIR}/v1alpha3/cluster/sidero/serverclass"
  }
  args = {
    PKG_SINK_SOURCE = "pkg-sink-source-sidero-serverclass"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/cluster/sidero/serverclass"]
}

target "cluster-api-v1alpha3-cluster-sidero-talosconfigtemplate" {
  inherits = ["_cluster-api-v1alpha3-cluster-sidero"]
  contexts = {
    pkg-local = "${CLUSTER_API_DIR}/v1alpha3/cluster/sidero/talosconfigtemplate"
  }
  args = {
    PKG_SINK_SOURCE = "pkg-sink-source-sidero-talosconfigtemplate"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/cluster/sidero/talosconfigtemplate"]
}

target "cluster-api-v1alpha3-cluster-sidero-taloscontrolplane" {
  inherits = ["_cluster-api-v1alpha3-cluster-sidero"]
  contexts = {
    pkg-local = "${CLUSTER_API_DIR}/v1alpha3/cluster/sidero/taloscontrolplane"
  }
  args = {
    PKG_SINK_SOURCE = "pkg-sink-source-sidero-taloscontrolplane"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/cluster/sidero/taloscontrolplane"]
}

target "cluster-api-clusterctl-crds" {
  inherits = ["_cluster-api"]
  contexts = {
    pkg-local = "${CLUSTER_API_DIR}/clusterctl-crds"
  }
  args = {
    URL = "https://raw.githubusercontent.com/kubernetes-sigs/cluster-api/${CLUSTERCTL_VERSION}/cmd/clusterctl/config/manifest/clusterctl-api.yaml"
  }
  output = ["${CLUSTER_API_DIR}/clusterctl-crds"]
}
