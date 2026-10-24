#!/usr/bin/env bash
# Builds the image with the versions the Dockerfile's FROM lines carry, the way CI
# and the publish workflow do. Usage: scripts/build.sh [tag]   (default ci-playwright:local)
set -euo pipefail

tag="${1:-ci-playwright:local}"
cd "$(dirname "$0")/.."

eval "$(./scripts/versions.sh)"

docker build \
  --build-arg "PLAYWRIGHT_VERSION=${PLAYWRIGHT_VERSION}" \
  --build-arg "IMAGE_VERSION=${PLAYWRIGHT_VERSION}" \
  -t "${tag}" .
