#!/usr/bin/env bash
# biome.json's $schema names a version so editor autocomplete and validation
# match the Biome actually running. Nothing keeps it in sync with the
# @biomejs/biome version pinned in package.json - Dependabot bumps one and has
# no reason to know the other field exists. That drifted twice (#36, #61)
# before either was a manual, easy-to-forget fix.
set -uo pipefail

cd "$(dirname "$0")/.."

pinned=$(jq -r '.devDependencies["@biomejs/biome"]' package.json)
schema_version=$(grep -o '"\$schema": *"https://biomejs\.dev/schemas/[^/]*/schema\.json"' biome.json |
  sed -E 's#.*/schemas/([^/]+)/schema\.json"$#\1#')

if [ -z "$schema_version" ]; then
  echo "could not find a Biome \$schema URL in biome.json" >&2
  exit 1
fi

if [ "$pinned" != "$schema_version" ]; then
  echo "biome.json's \$schema is pinned to $schema_version but package.json pins @biomejs/biome $pinned" >&2
  echo "update biome.json's \$schema to https://biomejs.dev/schemas/$pinned/schema.json" >&2
  exit 1
fi

echo "biome.json's \$schema ($schema_version) matches the pinned @biomejs/biome ($pinned)"
