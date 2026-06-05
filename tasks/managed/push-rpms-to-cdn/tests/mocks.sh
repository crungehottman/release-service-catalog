#!/usr/bin/env bash
set -eux

# mocks to be injected into task step scripts

DATA_DIR="${DATA_DIR:-/var/workdir/release}"

# Mock pubtools-pulp-push to simulate successful CDN push
function pubtools-pulp-push() {
    echo "pubtools-pulp-push $*" >> "${DATA_DIR}/mock_pubtools.txt"
    echo "Mock: pubtools-pulp-push called with arguments:"
    echo "  $*"
    echo "Mock: Push completed successfully"
    return 0
}

# Mock select-oci-auth for trusted artifacts
function select-oci-auth() {
    echo "Mock select-oci-auth called with: $*"
}

# Mock oras for trusted artifact operations
function oras() {
    echo "Mock oras called with: $*"
    echo "$*" >> "${DATA_DIR}/mock_oras.txt"
    local args="$*"

    if [[ "$*" == "pull --registry-config"* ]]; then
        echo "Mocking pulling files"
        # Trusted artifact pull - files should already be set up by the setup task
    fi
}
