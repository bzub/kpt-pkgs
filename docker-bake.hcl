variable "ROOT_DIR" {default = "."}
variable "OUT_DIR" {default = "${ROOT_DIR}/_out"}
variable "BIN_DIR" {default = "${OUT_DIR}/bin"}
variable "RESULTS_DIR" {default = "${OUT_DIR}/kpt-fn-results"}
variable "CLUSTER_API_DIR" {default = "${ROOT_DIR}/cluster-api"}
variable "REGISTRY" {default = "ghcr.io"}
variable "USERNAME" {default = "bzub"}
variable "REGISTRY_AND_USERNAME" {default = "${REGISTRY}/${USERNAME}"}

variable "GOLANG_VERSION" {default = "1.17"}
variable "KPT_VERSION" {default = "v1.0.0-beta.13"}
variable "KIND_VERSION" {default = "v0.11.1"}
variable "KUBECTL_VERSION" {default = "1.23.4"}
variable "CERT_MANAGER_VERSION" {default = "v1.1.1"}
variable "CAPI_V1ALPHA3_CORE_VERSION" {default = "v0.3.25"}
variable "CAPI_V1ALPHA4_CORE_VERSION" {default = "v0.4.7"}
variable "CAPI_V1BETA1_CORE_VERSION" {default = "v1.1.2"}
variable "CAPI_V1ALPHA3_BOOTSTRAP_KUBEADM_VERSION" {default = "${CAPI_V1ALPHA3_CORE_VERSION}"}
variable "CAPI_V1ALPHA3_BOOTSTRAP_TALOS_VERSION" {default = "v0.3.2"}
variable "CAPI_V1ALPHA3_CONTROLPLANE_KUBEADM_VERSION" {default = "${CAPI_V1ALPHA3_CORE_VERSION}"}
variable "CAPI_V1ALPHA3_CONTROLPLANE_TALOS_VERSION" {default = "v0.2.0"}
variable "CAPI_V1ALPHA3_INFRASTRUCTURE_DOCKER_VERSION" {default = "${CAPI_V1ALPHA3_CORE_VERSION}"}
variable "CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION" {default = "v0.3.3"}

variable "GOLANG_IMAGE" {default = "docker.io/library/golang:${GOLANG_VERSION}-alpine3.15"}
variable "KPT_IMAGE" {default = "ghcr.io/bzub/images/kpt:${KPT_VERSION}"}
variable "KIND_IMAGE" {default = "ghcr.io/bzub/images/kind:${KIND_VERSION}"}
variable "KUBECTL_IMAGE" {default = "docker.io/bitnami/kubectl:${KUBECTL_VERSION}"}
variable "CLUSTERCTL_V0_3_IMAGE" {default = "ghcr.io/bzub/images/clusterctl:${CAPI_V1ALPHA3_CORE_VERSION}"}
variable "CLUSTERCTL_V0_4_IMAGE" {default = "ghcr.io/bzub/images/clusterctl:${CAPI_V1ALPHA4_CORE_VERSION}"}
variable "CLUSTERCTL_V1_1_IMAGE" {default = "ghcr.io/bzub/images/clusterctl:${CAPI_V1BETA1_CORE_VERSION}"}
variable "CLUSTERCTL_IMAGE" {default = CLUSTERCTL_V1_1_IMAGE}
variable "KPT_FN_SEARCH_REPLACE_IMAGE" {default = "gcr.io/kpt-fn/search-replace@sha256:c8da9c025eea6bef4426c1eb1c12158da7bd795f8912fc83a170d490b3240a8b"}
variable "KPT_FN_SET_ANNOTATIONS_IMAGE" {default = "gcr.io/kpt-fn/set-annotations@sha256:6285fca0192e26c0ae090f26103a3661282260c69c80a794fbf6481082101ea6"}
variable "KPT_FN_SET_NAMESPACE_IMAGE" {default = "gcr.io/kpt-fn/set-namespace:v0.2.0@sha256:7adc23986f97572d75af9aec6a7f74d60f7b9976227f43a75486633e7c539e6f"}
variable "KPT_FN_CREATE_SETTERS_IMAGE" {default = "gcr.io/kpt-fn/create-setters@sha256:76ec527190c3826196db133c32db5d29c228876f0c4b5e692781f68e2dcc7536"}
variable "KPT_FN_APPLY_SETTERS_IMAGE" {default = "gcr.io/kpt-fn/apply-setters@sha256:d322a18de00daf566b48bc7cbebf4814bc87cecf783d494ccaf9294bf23c6392"}
variable "KPT_FN_STARLARK_IMAGE" {default = "gcr.io/kpt-fn/starlark@sha256:416188026608fbea937ebf2e287ae8aa277651884520621357b7f5115261a04e"}
variable "KPT_FN_SET_LABELS_IMAGE" {default = "gcr.io/kpt-fn/set-labels@sha256:d088e20cd2c9067e433398161cd7adda3d23226e1afeda37ea2b8029eaf3852f"}

group "default" {
  targets = [
    "cert-manager",
    "cluster-api",
  ]
}

target "_common" {
  args = {
    GOLANG_IMAGE = GOLANG_IMAGE
    KPT_IMAGE = KPT_IMAGE
    KIND_IMAGE = KIND_IMAGE
    KUBECTL_IMAGE = KUBECTL_IMAGE
    CLUSTERCTL_IMAGE = CLUSTERCTL_IMAGE
    KPT_FN_SEARCH_REPLACE_IMAGE = KPT_FN_SEARCH_REPLACE_IMAGE
    KPT_FN_SET_ANNOTATIONS_IMAGE = KPT_FN_SET_ANNOTATIONS_IMAGE
    KPT_FN_SET_NAMESPACE_IMAGE = KPT_FN_SET_NAMESPACE_IMAGE
    KPT_FN_CREATE_SETTERS_IMAGE = KPT_FN_CREATE_SETTERS_IMAGE
    KPT_FN_APPLY_SETTERS_IMAGE = KPT_FN_APPLY_SETTERS_IMAGE
    KPT_FN_STARLARK_IMAGE = KPT_FN_STARLARK_IMAGE
    KPT_FN_SET_LABELS_IMAGE = KPT_FN_SET_LABELS_IMAGE
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
    PACKAGE_PATH = "cert-manager"
    RESOURCES_URL = "https://github.com/cert-manager/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.yaml"
  }
  output = ["${ROOT_DIR}/cert-manager"]
  platforms = []
}

group "cluster-api" {
  targets = ["cluster-api-components"]
}

group "cluster-api-components" {
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

target "cluster-api-component" {
  inherits = ["_common"]
  target = "cluster-api-component-pkg"
}

target "cluster-api-component-v1alpha3" {
  inherits = ["cluster-api-component"]
  args = {
    CAPI_API_GROUP = "v1alpha3"
  }
}

target "cluster-api-component-v1alpha3-core" {
  inherits = ["cluster-api-component-v1alpha3"]
  args = {
    PROVIDER_TYPE = "core"
    PROVIDER_NAME = "cluster-api"
    PROVIDER_VERSION = CAPI_V1ALPHA3_CORE_VERSION
    PROVIDER_GITHUB_ORG = "kubernetes-sigs"
    PROVIDER_GITHUB_REPO = "cluster-api"
    PROVIDER_COMPONENTS_FILENAME = "core-components.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/core/cluster-api"]
}

target "cluster-api-component-v1alpha3-bootstrap" {
  inherits = ["cluster-api-component-v1alpha3"]
  args = {
    PROVIDER_TYPE = "bootstrap"
  }
}

target "cluster-api-component-v1alpha3-control-plane" {
  inherits = ["cluster-api-component-v1alpha3"]
  args = {
    PROVIDER_TYPE = "control-plane"
  }
}

target "cluster-api-component-v1alpha3-infrastructure" {
  inherits = ["cluster-api-component-v1alpha3"]
  args = {
    PROVIDER_TYPE = "infrastructure"
  }
}

target "cluster-api-component-v1alpha3-cluster" {
  inherits = ["cluster-api-component-v1alpha3"]
  args = {
    PROVIDER_TYPE = "cluster"
  }
}

target "cluster-api-component-v1alpha3-bootstrap-kubeadm" {
  inherits = ["cluster-api-component-v1alpha3-bootstrap"]
  args = {
    PROVIDER_NAME = "kubeadm"
    PROVIDER_VERSION = CAPI_V1ALPHA3_BOOTSTRAP_KUBEADM_VERSION
    PROVIDER_GITHUB_ORG = "kubernetes-sigs"
    PROVIDER_GITHUB_REPO = "cluster-api"
    PROVIDER_COMPONENTS_FILENAME = "bootstrap-components.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/bootstrap/kubeadm"]
}

target "cluster-api-component-v1alpha3-bootstrap-talos" {
  inherits = ["cluster-api-component-v1alpha3-bootstrap"]
  args = {
    PROVIDER_NAME = "talos"
    PROVIDER_VERSION = CAPI_V1ALPHA3_BOOTSTRAP_TALOS_VERSION
    PROVIDER_GITHUB_ORG = "siderolabs"
    PROVIDER_GITHUB_REPO = "cluster-api-bootstrap-provider-talos"
    PROVIDER_COMPONENTS_FILENAME = "bootstrap-components.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/bootstrap/talos"]
}

target "cluster-api-component-v1alpha3-control-plane-kubeadm" {
  inherits = ["cluster-api-component-v1alpha3-control-plane"]
  args = {
    PROVIDER_NAME = "kubeadm"
    PROVIDER_VERSION = CAPI_V1ALPHA3_CONTROLPLANE_KUBEADM_VERSION
    PROVIDER_GITHUB_ORG = "kubernetes-sigs"
    PROVIDER_GITHUB_REPO = "cluster-api"
    PROVIDER_COMPONENTS_FILENAME = "control-plane-components.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/control-plane/kubeadm"]
}

target "cluster-api-component-v1alpha3-control-plane-talos" {
  inherits = ["cluster-api-component-v1alpha3-control-plane"]
  args = {
    PROVIDER_NAME = "talos"
    PROVIDER_VERSION = CAPI_V1ALPHA3_CONTROLPLANE_TALOS_VERSION
    PROVIDER_GITHUB_ORG = "siderolabs"
    PROVIDER_GITHUB_REPO = "cluster-api-control-plane-provider-talos"
    PROVIDER_COMPONENTS_FILENAME = "control-plane-components.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/control-plane/talos"]
}

target "cluster-api-component-v1alpha3-infrastructure-docker" {
  inherits = ["cluster-api-component-v1alpha3-infrastructure"]
  args = {
    PROVIDER_NAME = "docker"
    PROVIDER_VERSION = CAPI_V1ALPHA3_INFRASTRUCTURE_DOCKER_VERSION
    PROVIDER_GITHUB_ORG = "kubernetes-sigs"
    PROVIDER_GITHUB_REPO = "cluster-api"
    PROVIDER_COMPONENTS_FILENAME = "infrastructure-components-development.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/infrastructure/docker"]
}

target "cluster-api-component-v1alpha3-infrastructure-sidero" {
  inherits = ["cluster-api-component-v1alpha3-infrastructure"]
  args = {
    PROVIDER_NAME = "sidero"
    PROVIDER_VERSION = CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION
    PROVIDER_GITHUB_ORG = "siderolabs"
    PROVIDER_GITHUB_REPO = "sidero"
    PROVIDER_COMPONENTS_FILENAME = "infrastructure-components.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/infrastructure/sidero"]
}

target "cluster-api-component-v1alpha3-cluster-sidero" {
  inherits = ["cluster-api-component-v1alpha3-cluster"]
  args = {
    PROVIDER_NAME = "sidero"
    PROVIDER_VERSION = CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION
    PROVIDER_GITHUB_ORG = "siderolabs"
    PROVIDER_GITHUB_REPO = "sidero"
    PROVIDER_COMPONENTS_FILENAME = "cluster-template.yaml"
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
