#!/usr/bin/env bash
# Fails when README.md pins an image tag to a literal version. The examples use
# <version> placeholders so a Playwright bump can't leave them stale (#38).
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC2016 # backticks are literal in the pattern
if grep -nE 'ci-playwright:[0-9]+\.[0-9]+\.[0-9]+|^\| `[0-9]+\.[0-9]+\.[0-9]+(-bun[0-9.]+)?` ' README.md; then
  echo "README.md pins a literal image version; use <version>" >&2
  exit 1
fi
echo "ok   README.md has no literal image versions"
