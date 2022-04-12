# cluster-api-v1alpha3-talos-sidero-management

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] cluster-api-v1alpha3-talos-sidero-management`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree cluster-api-v1alpha3-talos-sidero-management`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init cluster-api-v1alpha3-talos-sidero-management
kpt live apply cluster-api-v1alpha3-talos-sidero-management --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
