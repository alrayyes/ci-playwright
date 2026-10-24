#!/usr/bin/env bash
# Runs a built image and checks it carries what the consumers' Playwright jobs
# need. Usage: test/smoke.sh <image> <playwright-version> <bun-version>
set -euo pipefail

image="${1:?usage: smoke.sh <image> <playwright-version> <bun-version>}"
playwright="${2:?}"
bun="${3:?}"

fail=0
check() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "ok   ${name}"
  else
    echo "FAIL ${name}"
    fail=1
  fi
}

# shellcheck disable=SC2317,SC2329 # called through check()
in_image() { docker run --rm "${image}" sh -c "$1"; }

check "bun is ${bun}" in_image "[ \"\$(bun --version)\" = '${bun}' ]"
check "bunx is ${bun}" in_image "[ \"\$(bunx --version)\" = '${bun}' ]"
check "playwright is ${playwright}" in_image "playwright --version | grep -qx 'Version ${playwright}'"
for tool in node npx git gh unzip convert sudo openssl curl lcov pipx; do
  check "${tool} exists" in_image "command -v ${tool}"
done
check "runs as root" in_image "[ \"\$(id -u)\" = 0 ]"
check "git trusts any directory" in_image "git config --system --get-all safe.directory | grep -qx '\\*'"
check "browsers live in /ms-playwright" in_image "[ \"\$PLAYWRIGHT_BROWSERS_PATH\" = /ms-playwright ] && ls /ms-playwright | grep -q chromium"
check "headless chromium loads a data: URL" docker run --rm --ipc=host "${image}" node -e "
const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage();
  await p.goto('data:text/html,<title>ok</title>');
  if ((await p.title()) !== 'ok') process.exit(1);
  await b.close();
})().catch(() => process.exit(1));
"
check "io.playwright.version label is ${playwright}" \
  bash -c "[ \"\$(docker inspect -f '{{ index .Config.Labels \"io.playwright.version\" }}' '${image}')\" = '${playwright}' ]"
check "org.opencontainers.image.version label is set" \
  bash -c "[ -n \"\$(docker inspect -f '{{ index .Config.Labels \"org.opencontainers.image.version\" }}' '${image}')\" ]"

exit "${fail}"
