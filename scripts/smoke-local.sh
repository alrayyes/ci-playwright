#!/usr/bin/env bash
# Runs test/smoke.sh with the versions from the Dockerfile. Usage: scripts/smoke-local.sh <image>
set -euo pipefail

cd "$(dirname "$0")/.."
eval "$(./scripts/versions.sh)"
./test/smoke.sh "${1:?usage: smoke-local.sh <image>}" "${PLAYWRIGHT_VERSION}" "${BUN_VERSION}"
