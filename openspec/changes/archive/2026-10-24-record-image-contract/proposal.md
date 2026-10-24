## Why

The image shipped through three tickets
([#1](https://github.com/alrayyes/ci-playwright/issues/1),
[#5](https://github.com/alrayyes/ci-playwright/issues/5),
[#8](https://github.com/alrayyes/ci-playwright/issues/8)) with the contract only
in the README and `test/smoke.sh`. Two of the three were bugs where the image
drifted from what consumers rely on: Bun moved under the floating tag, and
`bunx` was missing. A spec makes the contract something a change can be checked
against.

## What Changes

- Record what the image must carry and how it runs: `image/contents`.
- Record how the tags relate to the Playwright and Bun versions: `image/tags`.

## Capabilities

### New Capabilities

- `image/contents`: the tools a consumer's CI job needs, and the user it runs as.
- `image/tags`: the tag scheme, and the rule that the tag equals the consumers'
  `@playwright/test` version.

### Modified Capabilities

None.

## Impact

`openspec/` only. No behaviour change.
