# clusterctl-crds

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] clusterctl-crds`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree clusterctl-crds`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init clusterctl-crds
kpt live apply clusterctl-crds --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
