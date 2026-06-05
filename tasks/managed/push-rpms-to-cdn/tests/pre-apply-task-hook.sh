#!/usr/bin/env bash

set -x
TASK_PATH="$1"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Mount mocks as ConfigMap and source them instead of prepending to the step script.
# This avoids "argument list too long" from Tekton's place-scripts when the combined script is large.
kubectl delete configmap test-mocks --ignore-not-found
kubectl create configmap test-mocks --from-file=mocks.sh="$SCRIPT_DIR/mocks.sh"
yq -i '.spec.volumes += [{"name": "test-mocks", "configMap": {"name": "test-mocks"}}]' "$TASK_PATH"
yq -i '.spec.steps[1].volumeMounts += [{"name": "test-mocks", "mountPath": "/mnt/test-mocks"}]' "$TASK_PATH"
yq -i '.spec.steps[1].script |= sub("^(#![^\n]*\n)", "${1}source /mnt/test-mocks/mocks.sh\n")' "$TASK_PATH"

# Create a dummy cdn-push-secret (pushSecret) with certificate files
kubectl delete secret cdn-push-secret --ignore-not-found
kubectl create secret generic cdn-push-secret \
  --from-literal=pulp_url='https://rhsm-pulp.example.com' \
  --from-literal=url='https://exodus-gw.example.com' \
  --from-literal=konflux-release-rhsm-pulp.crt='mock-cert' \
  --from-literal=konflux-release-rhsm-pulp.key='mock-key' \
  --from-literal=cert='mock-exodus-cert' \
  --from-literal=key='mock-exodus-key'

# Create a dummy pulp-access secret (Hosted Pulp credentials)
kubectl delete secret pulp-access --ignore-not-found
kubectl create secret generic pulp-access \
  --from-literal=tls.crt='mock-hosted-pulp-cert' \
  --from-literal=tls.key='mock-hosted-pulp-key'
