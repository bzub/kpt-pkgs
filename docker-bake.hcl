variable "BUILDKIT_GITHUB_TOKEN" {default = ""}
variable "BUILDKIT_DOCKER_HOST" {default = "unix:///var/run/docker.sock"}
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
variable "CLUSTERCTL_V0_3_IMAGE" {default = "ghcr.io/bzub/images/clusterctl:${CAPI_V1ALPHA3_CORE_VERSION}"}
variable "CLUSTERCTL_V0_4_IMAGE" {default = "ghcr.io/bzub/images/clusterctl:${CAPI_V1ALPHA4_CORE_VERSION}"}
variable "CLUSTERCTL_V1_1_IMAGE" {default = "ghcr.io/bzub/images/clusterctl:${CAPI_V1BETA1_CORE_VERSION}"}

group "default" {
  targets = [
    "cert-manager",
    "cluster-api",
  ]
}

target "_common" {
  args = {
    GITHUB_TOKEN = BUILDKIT_GITHUB_TOKEN
    DOCKER_HOST = BUILDKIT_DOCKER_HOST
    GOLANG_IMAGE = GOLANG_IMAGE
    KPT_IMAGE = KPT_IMAGE
    KIND_IMAGE = KIND_IMAGE
    CLUSTERCTL_V0_3_IMAGE = CLUSTERCTL_V0_3_IMAGE
    CLUSTERCTL_V0_4_IMAGE = CLUSTERCTL_V0_4_IMAGE
    CLUSTERCTL_V1_1_IMAGE = CLUSTERCTL_V1_1_IMAGE
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
  targets = [
    "cluster-api-providers",
    "cluster-api-clusters",
  ]
}

group "cluster-api-clusters" {
  targets = [
    "cluster-api-cluster-v1alpha3-sidero",
  ]
}

group "cluster-api-providers" {
  targets = [
    "cluster-api-provider-v1alpha3-core",
    "cluster-api-provider-v1alpha3-bootstrap-kubeadm",
    "cluster-api-provider-v1alpha3-bootstrap-talos",
    "cluster-api-provider-v1alpha3-control-plane-kubeadm",
    "cluster-api-provider-v1alpha3-control-plane-talos",
    "cluster-api-provider-v1alpha3-infrastructure-docker",
    "cluster-api-provider-v1alpha3-infrastructure-sidero",
  ]
}

target "cluster-api-provider" {
  inherits = ["_common"]
  target = "cluster-api-provider-pkg"
}

target "cluster-api-provider-v1alpha3" {
  inherits = ["cluster-api-provider"]
  args = {
    CAPI_API_GROUP = "v1alpha3"
    CLUSTERCTL = "clusterctl-v0_3"
  }
}

target "cluster-api-provider-v1alpha3-core" {
  inherits = ["cluster-api-provider-v1alpha3"]
  args = {
    PROVIDER_TYPE = "core"
    PROVIDER_NAME = "cluster-api"
    PROVIDER_VERSION = CAPI_V1ALPHA3_CORE_VERSION
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/core/cluster-api"]
}

target "cluster-api-provider-v1alpha3-bootstrap" {
  inherits = ["cluster-api-provider-v1alpha3"]
  args = {
    PROVIDER_TYPE = "bootstrap"
  }
}

target "cluster-api-provider-v1alpha3-control-plane" {
  inherits = ["cluster-api-provider-v1alpha3"]
  args = {
    PROVIDER_TYPE = "control-plane"
  }
}

target "cluster-api-provider-v1alpha3-infrastructure" {
  inherits = ["cluster-api-provider-v1alpha3"]
  args = {
    PROVIDER_TYPE = "infrastructure"
  }
}

target "cluster-api-provider-v1alpha3-bootstrap-kubeadm" {
  inherits = ["cluster-api-provider-v1alpha3-bootstrap"]
  args = {
    PROVIDER_NAME = "kubeadm"
    PROVIDER_VERSION = CAPI_V1ALPHA3_BOOTSTRAP_KUBEADM_VERSION
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/bootstrap/kubeadm"]
}

target "cluster-api-provider-v1alpha3-bootstrap-talos" {
  inherits = ["cluster-api-provider-v1alpha3-bootstrap"]
  args = {
    PROVIDER_NAME = "talos"
    PROVIDER_VERSION = CAPI_V1ALPHA3_BOOTSTRAP_TALOS_VERSION
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/bootstrap/talos"]
}

target "cluster-api-provider-v1alpha3-control-plane-kubeadm" {
  inherits = ["cluster-api-provider-v1alpha3-control-plane"]
  args = {
    PROVIDER_NAME = "kubeadm"
    PROVIDER_VERSION = CAPI_V1ALPHA3_CONTROLPLANE_KUBEADM_VERSION
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/control-plane/kubeadm"]
}

target "cluster-api-provider-v1alpha3-control-plane-talos" {
  inherits = ["cluster-api-provider-v1alpha3-control-plane"]
  args = {
    PROVIDER_NAME = "talos"
    PROVIDER_VERSION = CAPI_V1ALPHA3_CONTROLPLANE_TALOS_VERSION
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/control-plane/talos"]
}

target "cluster-api-provider-v1alpha3-infrastructure-docker" {
  inherits = ["cluster-api-provider-v1alpha3-infrastructure"]
  args = {
    PROVIDER_NAME = "docker"
    PROVIDER_VERSION = CAPI_V1ALPHA3_INFRASTRUCTURE_DOCKER_VERSION
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/infrastructure/docker"]
}

target "cluster-api-provider-v1alpha3-infrastructure-sidero" {
  inherits = ["cluster-api-provider-v1alpha3-infrastructure"]
  args = {
    PROVIDER_NAME = "sidero"
    PROVIDER_VERSION = CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION
    CLUSTERCTL = "clusterctl-v1_1"
    PROVIDER_COMPONENTS_URL = "https://github.com/talos-systems/sidero/releases/download/${CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION}/infrastructure-components.yaml"
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/infrastructure/sidero"]
}

target "cluster-api-cluster" {
  inherits = ["_common"]
  target = "cluster-api-cluster-pkg"
}

target "cluster-api-cluster-v1alpha3" {
  inherits = ["cluster-api-cluster"]
  args = {
    CAPI_API_GROUP = "v1alpha3"
    CLUSTERCTL = "clusterctl-v0_3"
  }
}

target "cluster-api-cluster-v1alpha3-sidero" {
  inherits = ["cluster-api-cluster-v1alpha3"]
  args = {
    PROVIDER_NAME = "sidero"
    PROVIDER_VERSION = CAPI_V1ALPHA3_INFRASTRUCTURE_SIDERO_VERSION
  }
  output = ["${CLUSTER_API_DIR}/v1alpha3/cluster/sidero"]
}
