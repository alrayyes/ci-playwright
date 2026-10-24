#!/usr/bin/env bash
# Prints the versions the Dockerfile's two FROM lines carry, as KEY=value lines, so
# the build, the smoke test and the publish workflow all read one source.
#   PLAYWRIGHT_VERSION  from mcr.microsoft.com/playwright:v<version>-<distro>
#   BUN_VERSION         from oven/bun:<version>
set -euo pipefail

dockerfile="${1:-Dockerfile}"

playwright="$(sed -nE 's#^FROM mcr\.microsoft\.com/playwright:v([0-9]+\.[0-9]+\.[0-9]+)-[a-z]+(@sha256:[0-9a-f]{64})? *$#\1#p' "${dockerfile}")"
bun="$(sed -nE 's#^FROM oven/bun:([0-9]+\.[0-9]+\.[0-9]+)(@sha256:[0-9a-f]{64})? AS bun *$#\1#p' "${dockerfile}")"

[ -n "${playwright}" ] || { echo "no playwright FROM line in ${dockerfile}" >&2; exit 1; }
[ -n "${bun}" ] || { echo "no bun FROM line in ${dockerfile}" >&2; exit 1; }

echo "PLAYWRIGHT_VERSION=${playwright}"
echo "BUN_VERSION=${bun}"
