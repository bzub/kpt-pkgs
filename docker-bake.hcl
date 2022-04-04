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
variable "KPT_FN_SET_NAMESPACE_IMAGE" {default = "docker-image://gcr.io/kpt-fn/set-namespace:v0.2.0@sha256:7adc23986f97572d75af9aec6a7f74d60f7b9976227f43a75486633e7c539e6f"}
variable "KPT_FN_CREATE_SETTERS_IMAGE" {default = "docker-image://gcr.io/kpt-fn/create-setters@sha256:76ec527190c3826196db133c32db5d29c228876f0c4b5e692781f68e2dcc7536"}
variable "KPT_FN_APPLY_SETTERS_IMAGE" {default = "docker-image://gcr.io/kpt-fn/apply-setters@sha256:d322a18de00daf566b48bc7cbebf4814bc87cecf783d494ccaf9294bf23c6392"}
variable "KPT_FN_STARLARK_IMAGE" {default = "docker-image://gcr.io/kpt-fn/starlark@sha256:416188026608fbea937ebf2e287ae8aa277651884520621357b7f5115261a04e"}
variable "KPT_FN_SET_LABELS_IMAGE" {default = "docker-image://gcr.io/kpt-fn/set-labels@sha256:d088e20cd2c9067e433398161cd7adda3d23226e1afeda37ea2b8029eaf3852f"}
variable "KPT_FN_ENSURE_NAME_SUBSTRING_IMAGE" {default = "docker-image://gcr.io/kpt-fn/ensure-name-substring@sha256:027d1fcdfa839d991cb6ddf924d339569d20a7dff70cd821642cb0d053739010"}

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
  }
  args = {
    FETCH_RESOURCES_IMAGE = "fetch-github-release-file"
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
  target = "pkg"
  args = {
    KPTFILE_SOURCE = "./cert-manager/Kptfile"
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
    "cluster-api-component-v1alpha3-core",
    "cluster-api-component-v1alpha3-bootstrap-kubeadm",
    "cluster-api-component-v1alpha3-bootstrap-talos",
    "cluster-api-component-v1alpha3-control-plane-kubeadm",
    "cluster-api-component-v1alpha3-control-plane-talos",
    "cluster-api-component-v1alpha3-infrastructure-docker",
    "cluster-api-component-v1alpha3-infrastructure-sidero",
    "cluster-api-component-v1alpha3-cluster-sidero",
  ]
}

group "cluster-api-clusters" {
  targets = [
    "cluster-api-component-v1alpha3-cluster-sidero",
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

target "cluster-api-component-v1alpha3" {
  inherits = ["_cluster-api"]
  args = {
    CAPI_API_GROUP = "v1alpha3"
  }
}

target "cluster-api-component-v1alpha3-core" {
  inherits = ["cluster-api-component-v1alpha3", "_cluster-api-provider"]
  args = {
    KPTFILE_SOURCE = "${CLUSTER_API_DIR}/v1alpha3/core/cluster-api/Kptfile"
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

target "cluster-api-component-v1alpha3-bootstrap" {
  inherits = ["cluster-api-component-v1alpha3", "_cluster-api-provider"]
  args = {
    PROVIDER_TYPE = "bootstrap"
    PROVIDER_TYPE_GO = "BootstrapProvider"
  }
}

target "cluster-api-component-v1alpha3-control-plane" {
  inherits = ["cluster-api-component-v1alpha3", "_cluster-api-provider"]
  args = {
    PROVIDER_TYPE = "control-plane"
    PROVIDER_TYPE_GO = "ControlPlaneProvider"
  }
}

target "cluster-api-component-v1alpha3-infrastructure" {
  inherits = ["cluster-api-component-v1alpha3", "_cluster-api-provider"]
  args = {
    PROVIDER_TYPE = "infrastructure"
    PROVIDER_TYPE_GO = "InfrastructureProvider"
  }
}

target "cluster-api-component-v1alpha3-cluster" {
  inherits = ["cluster-api-component-v1alpha3", "_cluster-api-cluster"]
}

target "cluster-api-component-v1alpha3-bootstrap-kubeadm" {
  inherits = ["cluster-api-component-v1alpha3-bootstrap"]
  args = {
    KPTFILE_SOURCE = "${CLUSTER_API_DIR}/v1alpha3/bootstrap/kubeadm/Kptfile"
    PROVIDER_NAME = "kubeadm"
    NAMESPACE = "capi-kubeadm-bootstrap-system"
    VERSION = CAPI_V1ALPHA3_BOOTSTRAP_KUBEADM_VERSION
    GITHUB_ORG = "kubernetes-sigs"
    GITHUB_REPO = "cluster-api"
    FILENAME = "bootstrap-components.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/bootstrap/kubeadm"]
}

target "cluster-api-component-v1alpha3-bootstrap-talos" {
  inherits = ["cluster-api-component-v1alpha3-bootstrap"]
  args = {
    KPTFILE_SOURCE = "${CLUSTER_API_DIR}/v1alpha3/bootstrap/talos/Kptfile"
    PROVIDER_NAME = "talos"
    NAMESPACE = "cabpt-system"
    VERSION = CAPI_V1ALPHA3_BOOTSTRAP_TALOS_VERSION
    GITHUB_ORG = "siderolabs"
    GITHUB_REPO = "cluster-api-bootstrap-provider-talos"
    FILENAME = "bootstrap-components.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/bootstrap/talos"]
}

target "cluster-api-component-v1alpha3-control-plane-kubeadm" {
  inherits = ["cluster-api-component-v1alpha3-control-plane"]
  args = {
    KPTFILE_SOURCE = "${CLUSTER_API_DIR}/v1alpha3/control-plane/kubeadm/Kptfile"
    PROVIDER_NAME = "kubeadm"
    NAMESPACE = "capi-kubeadm-control-plane-system"
    VERSION = CAPI_V1ALPHA3_CONTROLPLANE_KUBEADM_VERSION
    GITHUB_ORG = "kubernetes-sigs"
    GITHUB_REPO = "cluster-api"
    FILENAME = "control-plane-components.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/control-plane/kubeadm"]
}

target "cluster-api-component-v1alpha3-control-plane-talos" {
  inherits = ["cluster-api-component-v1alpha3-control-plane"]
  args = {
    KPTFILE_SOURCE = "${CLUSTER_API_DIR}/v1alpha3/control-plane/talos/Kptfile"
    PROVIDER_NAME = "talos"
    NAMESPACE = "cacppt-system"
    VERSION = CAPI_V1ALPHA3_CONTROLPLANE_TALOS_VERSION
    GITHUB_ORG = "siderolabs"
    GITHUB_REPO = "cluster-api-control-plane-provider-talos"
    FILENAME = "control-plane-components.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/control-plane/talos"]
}

target "cluster-api-component-v1alpha3-infrastructure-docker" {
  inherits = ["cluster-api-component-v1alpha3-infrastructure"]
  args = {
    KPTFILE_SOURCE = "${CLUSTER_API_DIR}/v1alpha3/infrastructure/docker/Kptfile"
    PROVIDER_NAME = "docker"
    NAMESPACE = "capd-system"
    VERSION = CAPI_V1ALPHA3_INFRASTRUCTURE_DOCKER_VERSION
    GITHUB_ORG = "kubernetes-sigs"
    GITHUB_REPO = "cluster-api"
    FILENAME = "infrastructure-components-development.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/infrastructure/docker"]
}

target "cluster-api-component-v1alpha3-infrastructure-sidero" {
  inherits = ["cluster-api-component-v1alpha3-infrastructure"]
  args = {
    KPTFILE_SOURCE = "${CLUSTER_API_DIR}/v1alpha3/infrastructure/sidero/Kptfile"
    PROVIDER_NAME = "sidero"
    NAMESPACE = "sidero-system"
    VERSION = CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION
    GITHUB_ORG = "siderolabs"
    GITHUB_REPO = "sidero"
    FILENAME = "infrastructure-components.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/infrastructure/sidero"]
}

target "cluster-api-component-v1alpha3-cluster-sidero" {
  inherits = ["cluster-api-component-v1alpha3-cluster"]
  args = {
    KPTFILE_SOURCE = "${CLUSTER_API_DIR}/v1alpha3/cluster/sidero/Kptfile"
    PROVIDER_NAME = "sidero"
    NAMESPACE = "sidero-system"
    VERSION = CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION
    GITHUB_ORG = "siderolabs"
    GITHUB_REPO = "sidero"
    FILENAME = "cluster-template.yaml"
    ENVIRONMENT_VARIABLES = join("\n", [
      "CLUSTER_NAME=cluster",
      "CONTROL_PLANE_MACHINE_COUNT=1",
      "WORKER_MACHINE_COUNT=0",
      "CONTROL_PLANE_ENDPOINT=127.0.0.1",
      "CONTROL_PLANE_PORT=6443",
      "CONTROL_PLANE_SERVERCLASS=any",
      "WORKER_SERVERCLASS=any",
      "TALOS_VERSION=v0.14",
      "KUBERNETES_VERSION=v1.20.15",
    ])
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/cluster/sidero"]
}

target "cluster-api-clusterctl-crds" {
  inherits = ["_cluster-api"]
  args = {
    KPTFILE_SOURCE = "${CLUSTER_API_DIR}/clusterctl-crds/Kptfile"
    URL = "https://raw.githubusercontent.com/kubernetes-sigs/cluster-api/${CLUSTERCTL_VERSION}/cmd/clusterctl/config/manifest/clusterctl-api.yaml"
  }
  output = ["${CLUSTER_API_DIR}/clusterctl-crds"]
}
